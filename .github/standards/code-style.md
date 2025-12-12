# Code Style & Formatting Standards

## Universal Principles
- **Readability over cleverness**: Code is read more than written
- **Consistency**: Follow project conventions, not personal preference
- **Simplicity**: Prefer clear, straightforward solutions
- **DRY**: Don't Repeat Yourself - extract common logic
- **YAGNI**: You Aren't Gonna Need It - don't over-engineer

## Naming Conventions

### General Rules
- Use descriptive names (no single-letter except loop counters)
- Names should reveal intent: `userAuthToken` > `token`
- Avoid abbreviations unless widely known: `http`, `api`, `url`
- Boolean variables start with `is`, `has`, `can`, `should`: `isActive`, `hasPermission`

### Language-Specific

**Go:**
- Packages: lowercase, single word (`auth`, `storage`)
- Exported: PascalCase (`UserService`, `GetUser`)
- Unexported: camelCase (`validateToken`, `parseConfig`)
- Constants: PascalCase or ALL_CAPS for package-level
- Interfaces: `-er` suffix when single method (`Reader`, `Handler`)

**Python:**
- Modules: lowercase_with_underscores
- Classes: PascalCase (`UserManager`, `S3Client`)
- Functions/variables: snake_case (`get_user`, `user_id`)
- Constants: UPPER_CASE_WITH_UNDERSCORES
- Private: prefix with `_` (`_internal_method`)

**JavaScript/TypeScript:**
- Variables/functions: camelCase (`getUserData`, `isValid`)
- Classes/interfaces: PascalCase (`UserService`, `IUser`)
- Constants: UPPER_CASE or camelCase based on project
- Files: kebab-case (`user-service.ts`) or camelCase (`userService.ts`)

**Terraform:**
- Resources: snake_case (`aws_s3_bucket`, `user_data_bucket`)
- Variables: snake_case (`bucket_name`, `aws_region`)
- Use descriptive names: `static_site_bucket` > `bucket1`

## Formatting & Linting

### Terraform
- **Tool:** `terraform fmt` (built-in)
- **Validation:** `terraform validate`
- **Linter:** `tflint`
- **Security:** `tfsec`, `checkov`
- Line length: 120 characters
- 2-space indentation

### Go
- **Formatter:** `gofmt` or `goimports`
- **Linter:** `golangci-lint` (aggregates multiple linters)
- Run before commit: `go fmt ./...`
- Required checks: `go vet`, `staticcheck`, `errcheck`
- Line length: 100-120 characters

### Python
- **Formatter:** `black` (opinionated, no config needed)
- **Linter:** `pylint`, `flake8`, or `ruff`
- **Import sorter:** `isort`
- **Type checker:** `mypy` (enforce type hints)
- Style guide: PEP 8
- Line length: 88 characters (black default) or 100

### JavaScript/TypeScript
- **Formatter:** `prettier`
- **Linter:** `eslint` with recommended rules
- **Config:** Airbnb or Standard style guide
- Use semicolons (consistent choice)
- Line length: 80-100 characters
- Trailing commas in multiline structures

## Code Structure

### Function/Method Guidelines
- **Small functions:** Max 30-50 lines (prefer smaller)
- **Single responsibility:** One function, one purpose
- **Parameters:** Limit to 3-4; use struct/object if more needed
- **Return early:** Avoid deep nesting with guard clauses
- **Error handling:** Always handle errors explicitly (no silent failures)

### File Organization
- **Length:** Max 300-500 lines per file; split if larger
- **Grouping:** Related functions/classes together
- **Imports:** Group and sort (stdlib → external → internal)
- **Order:** Constants → types → variables → functions

### Comments
- **What to comment:**
  - **Why**, not **what** (code shows what, comments explain why)
  - Complex algorithms or business logic
  - Public APIs and exported functions
  - Non-obvious decisions or trade-offs
  - TODO/FIXME with context and owner

- **What NOT to comment:**
  - Obvious code (bad: `// increment i`)
  - Outdated comments (update or delete)
  - Commented-out code (use git history instead)

- **Format:**
  - Go: `// GoDoc` style for exported items
  - Python: Docstrings for modules, classes, functions
  - JS/TS: JSDoc for functions and types
  - Terraform: Inline comments for complex logic

## Error Handling

### Go
- Always check errors: `if err != nil { return err }`
- Wrap errors with context: `fmt.Errorf("fetch user: %w", err)`
- Use sentinel errors for known cases: `var ErrNotFound = errors.New("not found")`
- Log errors at boundary (handlers), not deep in stack

### Python
- Use specific exceptions: `ValueError`, `TypeError`, not bare `Exception`
- Re-raise with context: `raise ValueError("invalid input") from e`
- Use context managers (`with`) for resources
- Log with structured context

### JavaScript/TypeScript
- Use `try/catch` for async operations
- Return `Result<T, E>` types or throw custom errors
- Avoid throwing strings; use Error objects
- Always reject promises with Error objects

## Best Practices

### Avoid
- ❌ Magic numbers (use named constants)
- ❌ Global mutable state
- ❌ Deep nesting (>3 levels)
- ❌ Long parameter lists
- ❌ God objects/functions
- ❌ Premature optimization

### Prefer
- ✅ Explicit over implicit
- ✅ Composition over inheritance
- ✅ Immutability where possible
- ✅ Pure functions (no side effects)
- ✅ Dependency injection
- ✅ Interface-based design

## Pre-commit Checklist
- [ ] Code is formatted (run formatter)
- [ ] No linter warnings
- [ ] All tests pass
- [ ] No debug statements or commented code
- [ ] No hardcoded values (use config)
- [ ] Error handling is complete
- [ ] Names are descriptive and consistent
