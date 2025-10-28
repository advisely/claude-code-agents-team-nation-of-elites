---
name: java-patterns
description: Java Spring Boot patterns, dependency injection, REST APIs, JPA/Hibernate, and enterprise Java development best practices
---

# Java Spring Boot Development Patterns

## When to Use This Skill

- Building Spring Boot microservices
- Implementing REST APIs with Spring Web
- Database access with JPA/Hibernate
- Enterprise Java application development
- Following Spring best practices

## Target Agents

- `java-expert` - Primary user for Java development
- `backend-developer` - Backend development with Java/Spring
- `api-architect` - REST API design with Spring Boot

## Core Patterns

### 1. Layered Architecture

```java
// Controller Layer
@RestController
@RequestMapping("/api/posts")
public class PostController {
    private final PostService postService;

    @Autowired
    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping
    public ResponseEntity<Page<PostDTO>> getPosts(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size
    ) {
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(postService.findAll(pageable));
    }

    @PostMapping
    public ResponseEntity<PostDTO> createPost(@Valid @RequestBody CreatePostRequest request) {
        PostDTO post = postService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(post);
    }
}

// Service Layer
@Service
@Transactional
public class PostService {
    private final PostRepository postRepository;
    private final PostMapper postMapper;

    public PostDTO create(CreatePostRequest request) {
        Post post = postMapper.toEntity(request);
        Post saved = postRepository.save(post);
        return postMapper.toDTO(saved);
    }

    @Transactional(readOnly = true)
    public Page<PostDTO> findAll(Pageable pageable) {
        return postRepository.findAll(pageable)
            .map(postMapper::toDTO);
    }
}

// Repository Layer
public interface PostRepository extends JpaRepository<Post, Long> {
    @Query("SELECT p FROM Post p WHERE p.status = :status")
    Page<Post> findByStatus(@Param("status") PostStatus status, Pageable pageable);

    @Query("SELECT p FROM Post p JOIN FETCH p.author WHERE p.id = :id")
    Optional<Post> findByIdWithAuthor(@Param("id") Long id);
}
```

### 2. Entity Mapping with JPA

```java
@Entity
@Table(name = "posts")
@EntityListeners(AuditingEntityListener.class)
public class Post {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PostStatus status = PostStatus.DRAFT;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User author;

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Comment> comments = new ArrayList<>();

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    // Getters, setters, equals, hashCode
}
```

### 3. DTO Pattern with MapStruct

```java
@Mapper(componentModel = "spring")
public interface PostMapper {
    @Mapping(target = "authorName", source = "author.name")
    @Mapping(target = "commentsCount", expression = "java(post.getComments().size())")
    PostDTO toDTO(Post post);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Post toEntity(CreatePostRequest request);
}

public record PostDTO(
    Long id,
    String title,
    String content,
    PostStatus status,
    String authorName,
    Integer commentsCount,
    LocalDateTime createdAt
) {}
```

### 4. Exception Handling

```java
@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleResourceNotFound(
        ResourceNotFoundException ex
    ) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.NOT_FOUND.value(),
            ex.getMessage(),
            LocalDateTime.now()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ValidationErrorResponse> handleValidation(
        MethodArgumentNotValidException ex
    ) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
            errors.put(error.getField(), error.getDefaultMessage())
        );

        return ResponseEntity.badRequest().body(
            new ValidationErrorResponse(errors, LocalDateTime.now())
        );
    }
}
```

### 5. Security with Spring Security

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

### 6. Testing with JUnit 5 & Mockito

```java
@SpringBootTest
@AutoConfigureMockMvc
class PostControllerIntegrationTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldCreatePost() throws Exception {
        CreatePostRequest request = new CreatePostRequest("Title", "Content");

        mockMvc.perform(post("/api/posts")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.title").value("Title"));
    }
}

@ExtendWith(MockitoExtension.class)
class PostServiceTest {
    @Mock
    private PostRepository postRepository;

    @InjectMocks
    private PostService postService;

    @Test
    void shouldCreatePost() {
        // Arrange
        CreatePostRequest request = new CreatePostRequest("Title", "Content");
        Post post = new Post();
        when(postRepository.save(any(Post.class))).thenReturn(post);

        // Act
        PostDTO result = postService.create(request);

        // Assert
        assertNotNull(result);
        verify(postRepository).save(any(Post.class));
    }
}
```

## Best Practices

1. Use **constructor injection** over field injection
2. Follow **layered architecture** (Controller, Service, Repository)
3. Use **DTOs** for API responses
4. Implement **global exception handling**
5. Use **Spring Data JPA** for database access
6. Write **comprehensive tests**
7. Use **@Transactional** appropriately
8. Implement **proper security** with Spring Security
9. Use **validation annotations** (@Valid, @NotNull, etc.)
10. Follow **RESTful** API conventions
