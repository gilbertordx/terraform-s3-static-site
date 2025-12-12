# CI/CD Pipeline Standards

## Mission
Automate enforcement of all standards. Failing checks block deployment. No exceptions.

## Pipeline Philosophy
- **Shift Left:** Catch issues early (pre-commit > CI > deployment)
- **Fail Fast:** Stop on first critical failure
- **Zero Trust:** Verify everything, trust nothing
- **Automation:** Humans don't enforce standards, pipelines do

## Pre-Commit Hooks (Local Enforcement)

### Setup
```bash
# Install pre-commit framework
pip install pre-commit

# .pre-commit-config.yaml in repo root
```

### Configuration
```yaml
# .pre-commit-config.yaml
repos:
  # Code formatting
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: detect-private-key  # Prevent committed secrets
  
  # Secrets scanning
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
  
  # Terraform
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_tfsec
  
  # Go
  - repo: local
    hooks:
      - id: go-fmt
        name: go fmt
        entry: sh -c 'gofmt -w . && git diff --exit-code'
        language: system
        pass_filenames: false
      - id: go-vet
        name: go vet
        entry: go vet ./...
        language: system
        pass_filenames: false
      - id: go-test-short
        name: go test (short)
        entry: go test -short ./...
        language: system
        pass_filenames: false
  
  # Python
  - repo: https://github.com/psf/black
    rev: 23.9.1
    hooks:
      - id: black
  
  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
  
  # Commit message validation
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v3.0.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
```

### Install
```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

## CI Pipeline (GitHub Actions)

### Main Workflow
**File: `.github/workflows/ci.yml`**

```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  GO_VERSION: '1.21'
  PYTHON_VERSION: '3.11'
  NODE_VERSION: '20'
  TERRAFORM_VERSION: '1.6'

jobs:
  # Job 1: Security Checks (run first, fail fast)
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for secret scanning
      
      - name: Scan for secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
      
      - name: Dependency vulnerability scan
        run: |
          # Go
          go install golang.org/x/vuln/cmd/govulncheck@latest
          govulncheck ./...
          
          # Python (if applicable)
          pip install safety
          safety check
          
          # Node (if applicable)
          npm audit --audit-level=high
  
  # Job 2: Code Quality
  code-quality:
    name: Code Quality
    runs-on: ubuntu-latest
    needs: security  # Run after security passes
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
      
      - name: Go formatting check
        run: |
          if [ "$(gofmt -s -l . | wc -l)" -gt 0 ]; then
            echo "Code is not formatted. Run: gofmt -s -w ."
            gofmt -s -l .
            exit 1
          fi
      
      - name: Go vet
        run: go vet ./...
      
      - name: Go lint
        uses: golangci/golangci-lint-action@v3
        with:
          version: latest
          args: --timeout=5m
      
      - name: Terraform formatting check
        run: terraform fmt -check -recursive terraform/
      
      - name: Terraform validation
        run: |
          cd terraform/
          terraform init -backend=false
          terraform validate
  
  # Job 3: Testing
  test:
    name: Unit & Integration Tests
    runs-on: ubuntu-latest
    needs: code-quality
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
      
      - name: Cache Go modules
        uses: actions/cache@v3
        with:
          path: ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
      
      - name: Run unit tests
        run: |
          go test ./... -v -race -coverprofile=coverage.out -covermode=atomic
      
      - name: Check test coverage
        run: |
          coverage=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
          echo "Total coverage: $coverage%"
          
          if (( $(echo "$coverage < 80" | bc -l) )); then
            echo "❌ Coverage $coverage% is below required 80%"
            exit 1
          fi
          echo "✅ Coverage $coverage% meets 80% threshold"
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.out
          flags: unittests
  
  # Job 4: Infrastructure Testing
  terraform:
    name: Terraform Validation
    runs-on: ubuntu-latest
    needs: security
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}
      
      - name: Terraform fmt check
        run: terraform fmt -check -recursive
      
      - name: Terraform init
        run: terraform init -backend=false
        working-directory: ./terraform
      
      - name: Terraform validate
        run: terraform validate
        working-directory: ./terraform
      
      - name: Terraform plan
        run: terraform plan -out=tfplan
        working-directory: ./terraform
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: tfsec security scan
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          working_directory: ./terraform
          soft_fail: false  # Fail on security issues
      
      - name: Checkov IaC scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          framework: terraform
          soft_fail: false
      
      - name: Terratest (if tests exist)
        run: |
          cd test/
          go test -v -timeout 30m
        if: hashFiles('test/**/*_test.go') != ''
  
  # Job 5: Build & Package
  build:
    name: Build Application
    runs-on: ubuntu-latest
    needs: [test, terraform]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: ${{ env.GO_VERSION }}
      
      - name: Build binary
        run: |
          CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app ./cmd/main.go
      
      - name: Build Docker image
        run: |
          docker build -t myapp:${{ github.sha }} .
      
      - name: Scan Docker image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
  
  # Job 6: Deploy (only on main branch)
  deploy:
    name: Deploy to Environment
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: us-east-1
      
      - name: Deploy with Terraform
        run: |
          terraform init
          terraform apply -auto-approve
        working-directory: ./terraform
        env:
          TF_VAR_environment: production
      
      - name: Health check
        run: |
          sleep 30
          curl -f https://api.example.com/health || exit 1
```

## PR Merge Requirements

### Branch Protection Rules
**GitHub Settings → Branches → Branch protection rules for `main`:**

```yaml
# Required in GitHub UI
Require a pull request before merging: ✓
  Require approvals: 1 (2 for critical changes)
  Dismiss stale PR approvals when new commits are pushed: ✓
  Require review from Code Owners: ✓

Require status checks to pass before merging: ✓
  Require branches to be up to date before merging: ✓
  Status checks that are required:
    - security
    - code-quality
    - test
    - terraform
    - build

Require conversation resolution before merging: ✓

Require signed commits: ✓ (recommended)

Require linear history: ✓ (no merge commits, squash or rebase)

Do not allow bypassing the above settings: ✓

Restrict who can push to matching branches:
  - Limit to admins only
```

## Quality Gates Summary

### Pre-Commit (Local)
1. ✅ Code formatted (gofmt, black, terraform fmt)
2. ✅ No secrets detected
3. ✅ Short tests pass (<5 sec)
4. ✅ Conventional commit message
5. ✅ No trailing whitespace, large files

### CI Pipeline (Automated)
**Phase 1: Security (fail fast)**
- ✅ Secret scanning (TruffleHog)
- ✅ Dependency vulnerabilities (govulncheck, safety, npm audit)

**Phase 2: Code Quality**
- ✅ Formatting check (gofmt, terraform fmt)
- ✅ Linting (golangci-lint, tflint)
- ✅ Static analysis (go vet)

**Phase 3: Testing**
- ✅ Unit tests pass
- ✅ **80% minimum coverage** (HARD BLOCK)
- ✅ Integration tests pass
- ✅ Race condition detection

**Phase 4: Infrastructure**
- ✅ Terraform validate
- ✅ Terraform plan (no errors)
- ✅ tfsec security scan
- ✅ Checkov compliance scan
- ✅ Terratest (if applicable)

**Phase 5: Build**
- ✅ Binary builds successfully
- ✅ Docker image builds
- ✅ Container security scan (Trivy)

**Phase 6: Deploy**
- ✅ Terraform apply (production)
- ✅ Health check post-deployment

## Enforcement Matrix

| Standard | Pre-Commit | CI | PR Merge | Blocks Deploy |
|----------|-----------|----|---------:|------------:|
| **Git Conventional Commits** | ✓ | - | ✓ | ✓ |
| **No Secrets** | ✓ | ✓ | ✓ | ✓ |
| **Code Formatting** | ✓ | ✓ | ✓ | ✓ |
| **Linting (no warnings)** | ✓ | ✓ | ✓ | ✓ |
| **80% Test Coverage** | - | ✓ | ✓ | ✓ |
| **All Tests Pass** | ✓ | ✓ | ✓ | ✓ |
| **Terraform Validate** | ✓ | ✓ | ✓ | ✓ |
| **tfsec Security** | - | ✓ | ✓ | ✓ |
| **Dependency Vulnerabilities** | - | ✓ | ✓ | ✓ |
| **Container Scan** | - | ✓ | ✓ | ✓ |
| **PR Approval** | - | - | ✓ | ✓ |
| **Branch Up-to-Date** | - | - | ✓ | ✓ |

## Monitoring & Alerts

### CloudWatch Alarms (Terraform)
```hcl
resource "aws_cloudwatch_metric_alarm" "failed_deployments" {
  alarm_name          = "failed-deployments"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedDeployments"
  namespace           = "CI/CD"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert on failed deployments"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "test_coverage_drop" {
  alarm_name          = "test-coverage-below-threshold"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TestCoverage"
  namespace           = "CI/CD"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when test coverage drops below 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### Slack Notifications
```yaml
# Add to CI workflow
- name: Notify Slack on failure
  if: failure()
  uses: slackapi/slack-github-action@v1.24.0
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "❌ CI Pipeline Failed",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Job:* ${{ github.job }}\n*Branch:* ${{ github.ref }}\n*Commit:* ${{ github.sha }}"
            }
          }
        ]
      }
```

## Rollback Procedure

### Automatic Rollback
```yaml
# Add to deploy job
- name: Deploy new version
  id: deploy
  run: terraform apply -auto-approve
  
- name: Health check
  id: health
  run: |
    for i in {1..10}; do
      if curl -f https://api.example.com/health; then
        echo "Health check passed"
        exit 0
      fi
      sleep 10
    done
    echo "Health check failed after 100s"
    exit 1

- name: Rollback on failure
  if: failure() && steps.deploy.outcome == 'success'
  run: |
    terraform apply -auto-approve -var="app_version=${{ env.PREVIOUS_VERSION }}"
```

## Emergency Bypass (Break Glass)

**Use case:** Critical production hotfix

**Process:**
1. Create hotfix branch from `main`: `hotfix/critical-security-patch`
2. Apply minimal fix
3. Get emergency approval from 2 team leads
4. Use admin override to merge (all checks must still pass)
5. Post-incident review within 24 hours

**Audit trail:**
- All bypasses logged in CloudTrail
- Slack notification to #incidents channel
- Requires written justification in PR

## Pipeline Performance Targets

| Stage | Target | Current | Status |
|-------|--------|---------|--------|
| Pre-commit hooks | <5s | - | ⚡ |
| Security scan | <2min | - | ⚡ |
| Code quality | <3min | - | ⚡ |
| Unit tests | <5min | - | ⚡ |
| Integration tests | <10min | - | ⚡ |
| Build | <5min | - | ⚡ |
| Deploy | <10min | - | ⚡ |
| **Total pipeline** | **<30min** | - | 🎯 |

## Success Metrics

**Track weekly:**
- Pipeline success rate (target: >95%)
- Mean time to detect (MTTD) failures
- Mean time to recover (MTTR) from failures
- Test coverage trend
- Security scan findings trend
- Deployment frequency

**Review monthly:**
- False positive rate (linters, security scans)
- Pipeline optimization opportunities
- Developer friction points

## Team Responsibilities

| Role | Responsibility |
|------|----------------|
| **Developers** | Fix broken pipelines within 1 hour; maintain >80% coverage |
| **Tech Lead** | Review weekly metrics; approve bypass requests |
| **DevOps/SRE** | Maintain pipeline infrastructure; optimize performance |
| **Security** | Review security scan findings; update threat models |

## Command Reference

```bash
# Run all checks locally (before push)
make ci-local

# Run specific checks
make test-coverage    # Check if coverage meets 80%
make security-scan    # Run all security tools
make terraform-check  # Validate Terraform

# View coverage report
go tool cover -html=coverage.out

# Generate baseline for secrets (first time)
detect-secrets scan > .secrets.baseline

# Update dependencies and check for vulnerabilities
go get -u ./...
govulncheck ./...
```

---

**JOCKO'S FINAL WORD:**

This pipeline is your DISCIPLINE. It enforces every standard automatically.

- ❌ No secrets? **Blocked.**
- ❌ Coverage <80%? **Blocked.**
- ❌ Security vulnerabilities? **Blocked.**
- ❌ Formatting wrong? **Blocked.**

The pipeline doesn't negotiate. It doesn't make exceptions. It ENFORCES.

Your job: Write code that passes. The pipeline's job: Make sure you did.

**EXECUTE.**
