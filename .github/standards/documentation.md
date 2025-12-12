# Documentation Standards

## Principle
Documentation is code. Keep it updated, concise, and accurate. Outdated docs are worse than no docs.

## README.md Structure

Every project/module must have a README with:

### 1. Title & Description
- Clear project name
- One-sentence description
- Badges (build status, coverage, version)

### 2. Prerequisites
- Required software/tools and versions
- System requirements
- Account/access requirements (AWS, APIs)

### 3. Installation/Setup
```markdown
## Setup

1. Clone the repository
2. Install dependencies: `npm install` or `go mod download`
3. Copy `.env.example` to `.env` and configure
4. Run: `make start` or `npm start`
```

### 4. Usage
- Basic examples
- Common commands
- Configuration options

### 5. Project Structure (optional for larger projects)
```
project/
├── cmd/           # Application entrypoints
├── internal/      # Private application code
├── pkg/           # Public libraries
└── terraform/     # Infrastructure code
```

### 6. Configuration
- Environment variables with descriptions
- Configuration file examples
- Default values

### 7. Testing
- How to run tests: `go test ./...`
- Coverage reports
- Integration test requirements

### 8. Deployment
- Build commands
- Deployment process
- Infrastructure setup (link to terraform docs)

### 9. Contributing (if open source)
- Link to CONTRIBUTING.md
- Code style requirements
- PR process

### 10. License & Contact
- License type
- Maintainer contacts

## Code Comments

### When to Comment

**Required:**
- Public APIs and exported functions
- Complex algorithms or business logic
- Non-obvious decisions or workarounds
- Security considerations
- Performance trade-offs

**Prohibited:**
- Obvious code behavior
- Commented-out code (use git)
- Outdated comments

### Documentation Comments by Language

**Go (GoDoc):**
```go
// GetUser retrieves a user by ID from the database.
// Returns ErrNotFound if the user does not exist.
// Returns ErrDatabase if the query fails.
func GetUser(ctx context.Context, id string) (*User, error) {
    // Implementation
}
```

**Python (Docstrings):**
```python
def get_user(user_id: str) -> User:
    """
    Retrieve a user by ID from the database.
    
    Args:
        user_id: Unique identifier for the user
        
    Returns:
        User object with populated fields
        
    Raises:
        UserNotFoundError: If user_id does not exist
        DatabaseError: If query fails
    """
    pass
```

**JavaScript/TypeScript (JSDoc):**
```typescript
/**
 * Retrieves a user by ID from the database.
 * @param {string} userId - Unique identifier for the user
 * @returns {Promise<User>} User object
 * @throws {NotFoundError} If user does not exist
 * @throws {DatabaseError} If query fails
 */
async function getUser(userId: string): Promise<User> {
    // Implementation
}
```

**Terraform (Inline):**
```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase, alphanumeric, and hyphens only"
  }
}
```

## Inline Comments

### Good Examples
```go
// Use exponential backoff to avoid overwhelming the API during failures
retryDelay := time.Second * time.Duration(math.Pow(2, float64(attempt)))

// CloudFront requires a minimum TTL of 0, not null
if ttl == nil {
    ttl = aws.Int64(0)
}
```

### Bad Examples
```go
// Bad: Obvious
i++ // increment i

// Bad: Redundant
// Get user from database
user := db.GetUser(id)

// Bad: Outdated (code changed but comment didn't)
// Returns an array of users <- actually returns a map now
func GetUsers() map[string]User { }
```

## Architecture Documentation

### ADR (Architecture Decision Records)
For significant architectural decisions, create ADRs in `docs/adr/`:

**Template: `docs/adr/001-use-s3-for-static-hosting.md`**
```markdown
# 1. Use S3 for Static Website Hosting

## Status
Accepted

## Context
Need to host static HTML/CSS/JS files with high availability and low cost.

## Decision
Use AWS S3 with CloudFront for static website hosting.

## Consequences
**Positive:**
- Low cost ($0.023/GB)
- High availability (99.99% SLA)
- Global CDN with CloudFront
- No server management

**Negative:**
- No server-side rendering
- Limited to static content
- AWS vendor lock-in
```

## API Documentation

### REST APIs
- Use OpenAPI/Swagger specification
- Document all endpoints, parameters, responses
- Include example requests/responses
- Version your API (`/v1/users`)

### GraphQL
- Use GraphQL schema as documentation
- Add descriptions to all fields
- Provide example queries

### Internal APIs/Libraries
- Document public interfaces
- Provide usage examples
- List dependencies and requirements

## Terraform Module Documentation

Every Terraform module must have:

**`README.md`:**
```markdown
# S3 Static Website Module

Creates an S3 bucket configured for static website hosting.

## Usage

\`\`\`hcl
module "static_site" {
  source      = "./modules/s3-static-site"
  bucket_name = "my-site-bucket"
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
\`\`\`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | S3 bucket name | string | n/a | yes |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| website_endpoint | S3 website endpoint URL |
| bucket_arn | ARN of the S3 bucket |
```

## Changelog

Maintain a `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/):

```markdown
# Changelog

## [Unreleased]

## [1.2.0] - 2024-12-12
### Added
- JWT token refresh endpoint
- Rate limiting on authentication

### Fixed
- S3 bucket policy for public read access

### Changed
- Increased session timeout to 24 hours

## [1.1.0] - 2024-11-01
...
```

## Documentation Maintenance

### Review Schedule
- Update docs with every code change
- Quarterly review of all documentation
- Archive outdated docs (don't delete, mark as deprecated)

### Quality Checks
- [ ] No broken links
- [ ] Examples are tested and working
- [ ] Version numbers are current
- [ ] Screenshots are up-to-date
- [ ] Prerequisites match actual requirements

## Tools

- **Diagrams:** Mermaid (in Markdown), draw.io, or Lucidchart
- **API Docs:** Swagger/OpenAPI, Postman collections
- **Code Docs:** GoDoc, Sphinx (Python), JSDoc
- **Infrastructure:** Terraform docs, terraform-docs tool

## Anti-Patterns to Avoid
- ❌ "The code is self-documenting" (it's not)
- ❌ Writing documentation after the fact (do it during development)
- ❌ Copy-pasting documentation (keep DRY)
- ❌ Overly verbose docs (concise and clear wins)
- ❌ Documentation without examples (show, don't just tell)
