# Security & Secrets Management Standards

## Core Principle: Zero Trust
Never trust, always verify. Assume breach. Defense in depth.

## Secrets Management

### What Are Secrets?
- API keys and tokens
- Database credentials
- Private keys and certificates
- OAuth client secrets
- Encryption keys
- Session secrets
- Service account credentials

### Storage Rules

**NEVER commit secrets to git:**
- ❌ No hardcoded credentials in code
- ❌ No `.env` files in git (add to `.gitignore`)
- ❌ No secrets in config files
- ❌ No secrets in comments or documentation
- ❌ No secrets in CI/CD pipeline definitions (use encrypted secrets)

**Use dedicated secret stores:**
- ✅ **AWS Secrets Manager** (preferred for AWS)
- ✅ **AWS SSM Parameter Store** (for simple configs)
- ✅ **HashiCorp Vault** (cross-cloud, advanced features)
- ✅ **Azure Key Vault** (for Azure)
- ✅ **Google Secret Manager** (for GCP)

### Local Development

**`.env` files:**
```bash
# .env (NEVER commit this file)
DATABASE_URL=postgresql://localhost:5432/myapp
API_KEY=sk_test_abc123xyz
```

**`.env.example` (DO commit this):**
```bash
# .env.example
DATABASE_URL=postgresql://localhost:5432/myapp
API_KEY=your_api_key_here
```

**`.gitignore`:**
```
.env
.env.local
.env.*.local
*.key
*.pem
secrets.yml
credentials.json
```

### Environment Variables

**Naming convention:**
```bash
# Good
DATABASE_URL=...
AWS_ACCESS_KEY_ID=...
STRIPE_API_KEY=...

# Bad (too generic)
KEY=...
SECRET=...
TOKEN=...
```

**Loading in code:**

**Go:**
```go
import "os"

func main() {
    dbURL := os.Getenv("DATABASE_URL")
    if dbURL == "" {
        log.Fatal("DATABASE_URL not set")
    }
    // Never log the actual value
    log.Println("Database connection configured")
}
```

**Python:**
```python
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL not set")
```

### Secrets in AWS (Terraform)

**Using Secrets Manager:**
```hcl
# Store secret
resource "aws_secretsmanager_secret" "api_key" {
  name = "myapp/api-key"
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = var.api_key  # Passed via TF_VAR or -var-file
}

# Retrieve in application
data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = "myapp/api-key"
}
```

**Using SSM Parameter Store:**
```hcl
resource "aws_ssm_parameter" "db_password" {
  name  = "/myapp/db/password"
  type  = "SecureString"  # Encrypted with KMS
  value = var.db_password
  
  tags = {
    Environment = var.environment
  }
}
```

### Secrets Rotation

**Requirements:**
- Rotate secrets every 90 days (30 days for critical systems)
- Automate rotation where possible (AWS Secrets Manager)
- Use temporary credentials (IAM roles, STS)
- Revoke secrets immediately on suspected compromise

**AWS Secrets Manager auto-rotation:**
```hcl
resource "aws_secretsmanager_secret_rotation" "api_key" {
  secret_id           = aws_secretsmanager_secret.api_key.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}
```

## Encryption

### Data at Rest
**AWS:**
- S3: Enable SSE-S3 or SSE-KMS encryption
- RDS: Enable encryption at creation (cannot enable later)
- EBS: Enable encryption by default
- DynamoDB: Enable encryption

**Terraform example:**
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.this.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # or "aws:kms"
    }
  }
}
```

### Data in Transit
- **TLS 1.2+ only** (disable TLS 1.0, 1.1)
- Use HTTPS for all APIs
- Internal services: mTLS (mutual TLS) preferred
- Certificate management: AWS ACM, Let's Encrypt

**Enforce HTTPS (CloudFront):**
```hcl
resource "aws_cloudfront_distribution" "this" {
  # ... other config
  
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn           = aws_acm_certificate.this.arn
    ssl_support_method            = "sni-only"
    minimum_protocol_version      = "TLSv1.2_2021"
  }
  
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
  }
}
```

## Authentication & Authorization

### Principles
- **Authenticate:** Verify identity (who are you?)
- **Authorize:** Verify permissions (what can you do?)
- **Always do both:** Never trust without verification

### API Authentication

**Best practices:**
- Use JWT tokens or OAuth 2.0
- Short-lived tokens (15-60 minutes)
- Refresh tokens for long sessions
- Include token expiration (`exp` claim)
- Validate signature and claims on every request

**JWT structure:**
```json
{
  "sub": "user-id-123",
  "email": "user@example.com",
  "roles": ["user"],
  "exp": 1702377600,
  "iat": 1702374000
}
```

**Go JWT validation:**
```go
func ValidateToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        return []byte(os.Getenv("JWT_SECRET")), nil
    })
    
    if err != nil || !token.Valid {
        return nil, ErrInvalidToken
    }
    
    claims := token.Claims.(*Claims)
    if claims.ExpiresAt < time.Now().Unix() {
        return nil, ErrTokenExpired
    }
    
    return claims, nil
}
```

### AWS IAM Best Practices

**Least privilege:**
```hcl
# Good: Specific resource and actions
resource "aws_iam_policy" "s3_read" {
  name = "s3-specific-bucket-read"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}

# Bad: Wildcard permissions
resource "aws_iam_policy" "bad" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"        # Too broad
      Resource = "*"           # All resources
    }]
  })
}
```

**Use IAM roles, not access keys:**
- EC2/ECS/Lambda: Attach IAM roles
- Local development: Use AWS SSO or temporary credentials
- CI/CD: Use OIDC federation (GitHub Actions, GitLab)

## Input Validation & Sanitization

### Validate All Input
**Never trust user input:**
- Validate type, format, length, range
- Whitelist allowed characters
- Sanitize before use in queries, commands, or HTML

**Go example:**
```go
func ValidateEmail(email string) error {
    if len(email) > 254 {
        return ErrEmailTooLong
    }
    
    matched, _ := regexp.MatchString(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`, email)
    if !matched {
        return ErrInvalidEmail
    }
    
    return nil
}
```

**SQL Injection Prevention:**
```go
// Good: Parameterized query
db.Query("SELECT * FROM users WHERE email = ?", email)

// Bad: String concatenation
db.Query("SELECT * FROM users WHERE email = '" + email + "'")  // VULNERABLE
```

**Python (SQLAlchemy):**
```python
# Good
session.query(User).filter(User.email == email).first()

# Bad
session.execute(f"SELECT * FROM users WHERE email = '{email}'")  # VULNERABLE
```

### Command Injection Prevention
```go
// Bad: Shell injection risk
cmd := exec.Command("sh", "-c", "echo "+userInput)

// Good: No shell, direct execution
cmd := exec.Command("echo", userInput)
```

## Rate Limiting & DDoS Protection

**Implement rate limiting:**
- Authentication endpoints: 5 requests/minute
- API endpoints: 100 requests/minute
- Use API Gateway, NGINX, or application-level middleware

**Go middleware:**
```go
import "golang.org/x/time/rate"

func RateLimitMiddleware(limiter *rate.Limiter) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow() {
                http.Error(w, "Rate limit exceeded", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

**AWS WAF (Web Application Firewall):**
```hcl
resource "aws_wafv2_rate_based_rule" "rate_limit" {
  name     = "rate-limit-rule"
  scope    = "REGIONAL"
  
  limit              = 2000
  aggregate_key_type = "IP"
}
```

## Logging & Monitoring

### What to Log
- Authentication attempts (success and failure)
- Authorization failures
- API access (with user ID)
- Configuration changes
- Secret access (audit trail)
- Errors and exceptions

### What NOT to Log
- ❌ Passwords or secrets
- ❌ Full credit card numbers
- ❌ PII without masking (SSN, etc.)
- ❌ Session tokens

**Good logging:**
```go
log.Info("User login successful",
    "user_id", userID,
    "ip", clientIP,
    "timestamp", time.Now())

// Bad: Logging sensitive data
log.Info("User login", "password", password)  // NEVER
```

### Security Monitoring

**Enable AWS services:**
- **CloudTrail:** Audit API calls
- **GuardDuty:** Threat detection
- **Config:** Configuration compliance
- **VPC Flow Logs:** Network traffic
- **CloudWatch Alarms:** Anomaly detection

**Terraform example:**
```hcl
resource "aws_cloudtrail" "main" {
  name                          = "main-trail"
  s3_bucket_name                = aws_s3_bucket.trail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}
```

## Dependency Security

### Scan for Vulnerabilities
- **Go:** `govulncheck`, Dependabot
- **Python:** `safety`, `pip-audit`
- **JavaScript:** `npm audit`, Snyk
- **Terraform:** `tfsec`, `checkov`, `terrascan`

**CI pipeline check:**
```yaml
- name: Security scan
  run: |
    go install golang.org/x/vuln/cmd/govulncheck@latest
    govulncheck ./...
```

### Keep Dependencies Updated
- Regular updates (monthly at minimum)
- Auto-merge security patches (Dependabot)
- Pin versions in production (avoid `latest`)

## Infrastructure Hardening

### Network Security
- **Private subnets:** Place databases and internal services in private subnets
- **Security groups:** Whitelist only required ports and IPs
- **NACLs:** Additional layer for subnet-level filtering
- **No public IPs:** Use NAT Gateway for outbound, load balancers for inbound

**Terraform security group:**
```hcl
resource "aws_security_group" "app" {
  name = "app-sg"
  
  # Allow HTTPS from ALB only
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # Allow outbound to specific services
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### S3 Bucket Security
```hcl
# Block public access at account level (default)
resource "aws_s3_account_public_access_block" "main" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket-level encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning for data protection
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

## Incident Response

### On Suspected Breach
1. **Isolate:** Revoke compromised credentials immediately
2. **Rotate:** Change all potentially affected secrets
3. **Audit:** Review logs for unauthorized access
4. **Notify:** Inform stakeholders and affected users
5. **Remediate:** Patch vulnerabilities
6. **Document:** Post-mortem and lessons learned

### Preparation
- Maintain incident response runbook
- Define escalation procedures
- Regular security drills
- Access to emergency contacts

## Security Checklist

Before deployment:
- [ ] No secrets in git history
- [ ] All secrets in secret manager
- [ ] Encryption enabled (at rest and in transit)
- [ ] TLS 1.2+ enforced
- [ ] IAM roles follow least privilege
- [ ] Rate limiting configured
- [ ] Input validation on all endpoints
- [ ] Security logging enabled
- [ ] Dependency vulnerabilities scanned
- [ ] Infrastructure scanned (tfsec, checkov)
- [ ] Backups configured and tested
- [ ] Incident response plan documented
