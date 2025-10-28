---
name: go-patterns
description: Go (Golang) patterns, concurrency, interfaces, error handling, and idiomatic Go development for high-performance systems
---

# Go Development Patterns

## When to Use This Skill

- Building high-performance backend services
- Implementing concurrent systems
- Creating microservices with Go
- Writing idiomatic Go code
- Building CLI tools and APIs

## Target Agents

- `go-expert` - Primary user for Go development
- `backend-developer` - Backend development with Go
- `api-architect` - API design with Go

## Core Patterns

### 1. Struct and Interface Patterns

```go
// Interface definition
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    FindByID(ctx context.Context, id int64) (*User, error)
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id int64) error
}

// Implementation
type postgresUserRepo struct {
    db *sql.DB
}

func NewPostgresUserRepo(db *sql.DB) UserRepository {
    return &postgresUserRepo{db: db}
}

func (r *postgresUserRepo) Create(ctx context.Context, user *User) error {
    query := `INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id`
    return r.db.QueryRowContext(ctx, query, user.Name, user.Email).Scan(&user.ID)
}
```

### 2. Error Handling

```go
// Custom errors
type ValidationError struct {
    Field string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("%s: %s", e.Field, e.Message)
}

// Error wrapping (Go 1.13+)
func processUser(id int64) error {
    user, err := repo.FindByID(ctx, id)
    if err != nil {
        return fmt.Errorf("failed to find user %d: %w", id, err)
    }
    return nil
}

// Error checking
if errors.Is(err, sql.ErrNoRows) {
    // Handle not found
}

var valErr *ValidationError
if errors.As(err, &valErr) {
    // Handle validation error
}
```

### 3. Concurrency Patterns

```go
// Worker Pool
func workerPool(tasks <-chan Task, results chan<- Result, workerCount int) {
    var wg sync.WaitGroup

    for i := 0; i < workerCount; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for task := range tasks {
                result := processTask(task)
                results <- result
            }
        }()
    }

    wg.Wait()
    close(results)
}

// Context cancellation
func doWork(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            // Do work
            time.Sleep(100 * time.Millisecond)
        }
    }
}

// Usage
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
```

### 4. HTTP Server with net/http

```go
type Server struct {
    router *http.ServeMux
    userService UserService
}

func NewServer(userService UserService) *Server {
    s := &Server{
        router: http.NewServeMux(),
        userService: userService,
    }

    s.routes()
    return s
}

func (s *Server) routes() {
    s.router.HandleFunc("/api/users", s.handleUsers())
    s.router.HandleFunc("/api/users/", s.handleUser())
}

func (s *Server) handleUsers() http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        switch r.Method {
        case http.MethodGet:
            s.getUsers(w, r)
        case http.MethodPost:
            s.createUser(w, r)
        default:
            http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        }
    }
}

func (s *Server) createUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondJSON(w, http.StatusBadRequest, ErrorResponse{Error: err.Error()})
        return
    }

    user, err := s.userService.Create(r.Context(), &req)
    if err != nil {
        respondJSON(w, http.StatusInternalServerError, ErrorResponse{Error: err.Error()})
        return
    }

    respondJSON(w, http.StatusCreated, user)
}

func respondJSON(w http.ResponseWriter, status int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteStatus(status)
    json.NewEncoder(w).Encode(data)
}
```

### 5. Middleware Pattern

```go
type Middleware func(http.HandlerFunc) http.HandlerFunc

func ChainMiddleware(h http.HandlerFunc, middlewares ...Middleware) http.HandlerFunc {
    for i := len(middlewares) - 1; i >= 0; i-- {
        h = middlewares[i](h)
    }
    return h
}

func Logger(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next(w, r)
        log.Printf("%s %s %v", r.Method, r.URL.Path, time.Since(start))
    }
}

func Auth(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        token := r.Header.Get("Authorization")
        if token == "" {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }
        next(w, r)
    }
}

// Usage
handler := ChainMiddleware(handleUsers, Logger, Auth)
```

### 6. Testing

```go
func TestUserService_Create(t *testing.T) {
    // Arrange
    mockRepo := &MockUserRepository{}
    service := NewUserService(mockRepo)

    req := &CreateUserRequest{
        Name:  "John Doe",
        Email: "john@example.com",
    }

    mockRepo.On("Create", mock.Anything, mock.AnythingOfType("*User")).
        Return(nil)

    // Act
    user, err := service.Create(context.Background(), req)

    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, user)
    assert.Equal(t, req.Name, user.Name)
    mockRepo.AssertExpectations(t)
}

// Table-driven tests
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "test@example.com", false},
        {"missing @", "testexample.com", true},
        {"empty", "", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validateEmail(tt.email)
            if (err != nil) != tt.wantErr {
                t.Errorf("validateEmail() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

## Best Practices

1. **Accept interfaces, return structs**
2. **Handle errors explicitly**
3. **Use context for cancellation**
4. **Prefer composition over inheritance**
5. **Keep functions small and focused**
6. **Use defer for cleanup**
7. **Write idiomatic Go code**
8. **Use go fmt and go vet**
9. **Write table-driven tests**
10. **Document public APIs**
