# Testing Standards

## Testing Philosophy
- Tests are first-class code: maintain, refactor, and document them
- Write tests during development, not after
- Failing tests block deployment
- Tests document expected behavior
- Fast feedback: run tests frequently

## Coverage Requirements

### Minimum Thresholds
- **Unit tests:** 80% code coverage minimum
- **Critical paths:** 100% coverage (auth, payments, security)
- **Integration tests:** All major workflows
- **E2E tests:** Core user journeys

### What to Measure
- Line coverage (primary metric)
- Branch coverage (conditional logic)
- Function coverage (all functions called)

### Tools
- **Go:** `go test -cover`, `go tool cover -html`
- **Python:** `pytest --cov`, `coverage.py`
- **JavaScript:** `jest --coverage`, `nyc`
- **Terraform:** `terraform validate`, `terraform plan`, `terratest`

## Test Types & Strategy

### 1. Unit Tests (70% of tests)
**Scope:** Single function/method in isolation

**Characteristics:**
- Fast (<10ms per test)
- No external dependencies (mock DB, APIs)
- Test one thing per test
- Deterministic (same input = same output)

**Go Example:**
```go
func TestCalculateTotal(t *testing.T) {
    tests := []struct {
        name     string
        items    []Item
        expected float64
    }{
        {"empty cart", []Item{}, 0.0},
        {"single item", []Item{{Price: 10.0}}, 10.0},
        {"multiple items", []Item{{Price: 10.0}, {Price: 5.0}}, 15.0},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := CalculateTotal(tt.items)
            if result != tt.expected {
                t.Errorf("got %v, want %v", result, tt.expected)
            }
        })
    }
}
```

**Python Example:**
```python
import pytest

def test_calculate_total_empty_cart():
    assert calculate_total([]) == 0.0

def test_calculate_total_single_item():
    assert calculate_total([Item(price=10.0)]) == 10.0

@pytest.mark.parametrize("items,expected", [
    ([], 0.0),
    ([Item(price=10.0)], 10.0),
    ([Item(price=10.0), Item(price=5.0)], 15.0),
])
def test_calculate_total(items, expected):
    assert calculate_total(items) == expected
```

### 2. Integration Tests (20% of tests)
**Scope:** Multiple components working together

**Characteristics:**
- Moderate speed (100ms-1s per test)
- Real dependencies (test DB, local services)
- Test interfaces between components
- Use test fixtures and containers

**Example:**
```go
func TestUserRepository_CreateAndGet(t *testing.T) {
    // Setup: real test database
    db := setupTestDB(t)
    defer db.Close()
    
    repo := NewUserRepository(db)
    
    // Create user
    user := &User{Name: "Alice", Email: "alice@example.com"}
    err := repo.Create(user)
    require.NoError(t, err)
    
    // Retrieve user
    retrieved, err := repo.GetByEmail("alice@example.com")
    require.NoError(t, err)
    assert.Equal(t, user.Name, retrieved.Name)
}
```

### 3. End-to-End Tests (10% of tests)
**Scope:** Full user workflow through the system

**Characteristics:**
- Slow (1-10s per test)
- Full stack (UI, API, database)
- Test critical user journeys
- Run in CI, not locally every time

**Example (API E2E):**
```go
func TestUserRegistrationFlow(t *testing.T) {
    client := setupTestClient(t)
    
    // Register user
    resp := client.POST("/api/v1/register", RegisterRequest{
        Email:    "test@example.com",
        Password: "SecurePass123!",
    })
    assert.Equal(t, 201, resp.StatusCode)
    
    // Login
    loginResp := client.POST("/api/v1/login", LoginRequest{
        Email:    "test@example.com",
        Password: "SecurePass123!",
    })
    assert.Equal(t, 200, loginResp.StatusCode)
    
    token := loginResp.Body.Token
    assert.NotEmpty(t, token)
    
    // Access protected resource
    userResp := client.GET("/api/v1/user", WithAuth(token))
    assert.Equal(t, 200, userResp.StatusCode)
}
```

### 4. Infrastructure Tests (Terraform)
**Tools:** `terratest`, `kitchen-terraform`, `terraform validate`

**Example (terratest):**
```go
func TestS3StaticSite(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../terraform-s3-site",
        Vars: map[string]interface{}{
            "bucket_name": "test-bucket-" + uuid.New().String(),
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    // Validate outputs
    endpoint := terraform.Output(t, terraformOptions, "website_endpoint")
    assert.NotEmpty(t, endpoint)
    
    // Test website is accessible
    resp, err := http.Get("http://" + endpoint)
    require.NoError(t, err)
    assert.Equal(t, 200, resp.StatusCode)
}
```

## Test Naming Conventions

### Pattern: `Test<FunctionName>_<Scenario>_<ExpectedResult>`

**Examples:**
```go
// Good
TestCalculateTotal_EmptyCart_ReturnsZero
TestCreateUser_DuplicateEmail_ReturnsError
TestAuthenticateUser_ValidCredentials_ReturnsToken

// Bad
TestCalculate           // Not specific
TestUser                // Too vague
TestCreateUserFunction  // Redundant "Function"
```

### Python (pytest):
```python
def test_calculate_total_empty_cart_returns_zero():
    pass

def test_create_user_duplicate_email_raises_error():
    pass
```

### JavaScript/TypeScript:
```typescript
describe('UserService', () => {
    describe('createUser', () => {
        it('should create user with valid data', () => {});
        it('should throw error when email exists', () => {});
    });
});
```

## Test Structure (AAA Pattern)

**Arrange → Act → Assert**

```go
func TestWithdraw_InsufficientFunds_ReturnsError(t *testing.T) {
    // Arrange
    account := NewAccount(100.0)
    
    // Act
    err := account.Withdraw(150.0)
    
    // Assert
    assert.Error(t, err)
    assert.Equal(t, ErrInsufficientFunds, err)
    assert.Equal(t, 100.0, account.Balance()) // Balance unchanged
}
```

## Mocking & Test Doubles

### When to Mock
- External APIs (HTTP, gRPC)
- Databases (for unit tests)
- Time-dependent operations
- File system operations
- Non-deterministic behavior

### When NOT to Mock
- Simple functions (just call them)
- Internal business logic
- Database in integration tests

### Go Mocking (using interfaces):
```go
type UserRepository interface {
    GetByID(ctx context.Context, id string) (*User, error)
}

type mockUserRepository struct {
    users map[string]*User
}

func (m *mockUserRepository) GetByID(ctx context.Context, id string) (*User, error) {
    user, ok := m.users[id]
    if !ok {
        return nil, ErrNotFound
    }
    return user, nil
}
```

### Python Mocking:
```python
from unittest.mock import Mock, patch

@patch('myapp.external_api.fetch_user')
def test_get_user_data(mock_fetch):
    mock_fetch.return_value = {'id': 1, 'name': 'Alice'}
    
    result = get_user_data(1)
    
    assert result['name'] == 'Alice'
    mock_fetch.assert_called_once_with(1)
```

## Test Data Management

### Fixtures
- Use factories or builders for test data
- Keep test data small and focused
- Use realistic but anonymized data

**Go (testify):**
```go
func setupTestDB(t *testing.T) *sql.DB {
    db, err := sql.Open("sqlite3", ":memory:")
    require.NoError(t, err)
    
    // Run migrations
    runMigrations(db)
    
    t.Cleanup(func() { db.Close() })
    return db
}
```

**Python (pytest fixtures):**
```python
@pytest.fixture
def db_session():
    session = create_test_session()
    yield session
    session.rollback()
    session.close()

@pytest.fixture
def sample_user():
    return User(name="Alice", email="alice@example.com")
```

## Test Organization

### Directory Structure
```
project/
├── cmd/
├── internal/
│   ├── user/
│   │   ├── user.go
│   │   ├── user_test.go          # Unit tests next to code
│   │   └── repository_test.go
├── test/
│   ├── integration/               # Integration tests
│   │   └── user_integration_test.go
│   ├── e2e/                       # End-to-end tests
│   │   └── user_flow_test.go
│   └── fixtures/                  # Test data
│       └── users.json
```

## CI/CD Integration

### Pre-commit Hooks
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running tests..."
go test ./... -short || exit 1

echo "Checking coverage..."
go test ./... -cover -coverprofile=coverage.out
go tool cover -func=coverage.out | grep total | awk '{if ($3+0 < 80) exit 1}'
```

### CI Pipeline (GitHub Actions example)
```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Run tests
        run: go test ./... -v -race -coverprofile=coverage.out
      
      - name: Check coverage
        run: |
          coverage=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
          if (( $(echo "$coverage < 80" | bc -l) )); then
            echo "Coverage $coverage% is below 80%"
            exit 1
          fi
```

## Performance Testing

### Benchmarks (Go)
```go
func BenchmarkCalculateTotal(b *testing.B) {
    items := []Item{{Price: 10.0}, {Price: 5.0}}
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        CalculateTotal(items)
    }
}
```

Run: `go test -bench=. -benchmem`

### Load Testing
- **Tools:** k6, Apache JMeter, Locust
- Test critical endpoints under load
- Define SLAs: p95 latency, throughput

## Best Practices

### Do's ✅
- Write tests first (TDD) when possible
- Test behavior, not implementation
- Keep tests independent (no shared state)
- Use descriptive test names
- Test edge cases and error paths
- Make tests readable (clear AAA structure)
- Clean up resources (defer, t.Cleanup, fixtures)

### Don'ts ❌
- Don't test private functions directly (test through public API)
- Don't share state between tests
- Don't use production data
- Don't skip cleanup
- Don't test framework code (e.g., testing a library's behavior)
- Don't write brittle tests (tightly coupled to implementation)

## Testing Checklist

Before committing:
- [ ] All new code has tests
- [ ] All tests pass locally
- [ ] Coverage meets threshold (80%+)
- [ ] No flaky tests (run multiple times)
- [ ] Integration tests use isolated environment
- [ ] Tests are fast (unit tests <10ms each)
- [ ] Test names clearly describe scenario
- [ ] Mocks are used appropriately
- [ ] Edge cases and errors are tested
