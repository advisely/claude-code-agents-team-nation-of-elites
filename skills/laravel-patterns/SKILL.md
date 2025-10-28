---
name: laravel-patterns
description: Laravel PHP framework best practices, Eloquent ORM patterns, and RESTful API development for modern web applications
---

# Laravel Development Patterns

## When to Use This Skill

- Building Laravel web applications and APIs
- Implementing authentication and authorization
- Database modeling with Eloquent ORM
- Building RESTful APIs with Laravel
- Following Laravel best practices and conventions

## Target Agents

- `laravel-expert` - Primary user for Laravel development
- `backend-developer` - General backend development with Laravel
- `api-architect` - REST API design using Laravel

## Core Patterns

### 1. MVC Architecture

**Controller Pattern:**

```php
// Thin controllers, fat models
namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Services\PostService;

class PostController extends Controller
{
    public function __construct(
        private PostService $postService
    ) {}

    public function store(StorePostRequest $request)
    {
        $post = $this->postService->createPost($request->validated());

        return response()->json([
            'data' => $post,
            'message' => 'Post created successfully'
        ], 201);
    }
}
```

**Service Layer Pattern:**

```php
namespace App\Services;

use App\Models\Post;
use App\Events\PostCreated;

class PostService
{
    public function createPost(array $data): Post
    {
        $post = Post::create($data);

        event(new PostCreated($post));

        return $post->load('author', 'tags');
    }
}
```

### 2. Eloquent ORM Best Practices

**Relationship Definitions:**

```php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Post extends Model
{
    protected $fillable = ['title', 'content', 'user_id', 'status'];

    protected $casts = [
        'published_at' => 'datetime',
        'is_featured' => 'boolean',
    ];

    // Relationships
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }

    // Scopes
    public function scopePublished($query)
    {
        return $query->where('status', 'published')
                     ->whereNotNull('published_at');
    }

    // Accessors
    public function getExcerptAttribute(): string
    {
        return substr($this->content, 0, 200) . '...';
    }
}
```

**Query Optimization:**

```php
// ❌ N+1 Problem
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name; // N+1 queries!
}

// ✅ Eager Loading
$posts = Post::with('author', 'comments.user')->get();

// ✅ Lazy Eager Loading
$posts = Post::all();
$posts->load('author', 'comments');

// ✅ Query Builder Optimization
$posts = Post::select(['id', 'title', 'user_id'])
    ->with(['author:id,name'])
    ->published()
    ->latest()
    ->paginate(15);
```

### 3. API Resources

**Resource Classes:**

```php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'excerpt' => $this->excerpt,
            'content' => $this->when($request->user()?->can('view', $this->resource), $this->content),
            'author' => new UserResource($this->whenLoaded('author')),
            'comments_count' => $this->when($this->comments_count !== null, $this->comments_count),
            'published_at' => $this->published_at?->toIso8601String(),
            'created_at' => $this->created_at->toIso8601String(),
            'links' => [
                'self' => route('posts.show', $this->id),
            ],
        ];
    }
}
```

**Resource Collections:**

```php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class PostCollection extends ResourceCollection
{
    public function toArray($request): array
    {
        return [
            'data' => $this->collection,
            'links' => [
                'self' => route('posts.index'),
            ],
            'meta' => [
                'total' => $this->total(),
                'current_page' => $this->currentPage(),
                'last_page' => $this->lastPage(),
            ],
        ];
    }
}
```

### 4. Authentication with Sanctum

**API Token Authentication:**

```php
// config/sanctum.php
return [
    'expiration' => 60 * 24, // 24 hours
];

// Controller
use Laravel\Sanctum\HasApiTokens;

class AuthController extends Controller
{
    public function login(LoginRequest $request)
    {
        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $user = Auth::user();
        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'user' => new UserResource($user),
            'token' => $token,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out successfully']);
    }
}
```

### 5. Form Request Validation

**Custom Request Classes:**

```php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Post::class);
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'content' => ['required', 'string', 'min:100'],
            'status' => ['required', Rule::in(['draft', 'published'])],
            'tags' => ['array'],
            'tags.*' => ['exists:tags,id'],
            'published_at' => ['nullable', 'date', 'after:now'],
        ];
    }

    public function messages(): array
    {
        return [
            'content.min' => 'Post content must be at least 100 characters.',
            'tags.*.exists' => 'One or more selected tags do not exist.',
        ];
    }
}
```

### 6. Database Migrations

**Migration Best Practices:**

```php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('content');
            $table->enum('status', ['draft', 'published'])->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index(['status', 'published_at']);
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

### 7. Events and Listeners

**Event-Driven Architecture:**

```php
// Event
namespace App\Events;

use App\Models\Post;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PostCreated
{
    use Dispatchable, SerializesModels;

    public function __construct(public Post $post) {}
}

// Listener
namespace App\Listeners;

use App\Events\PostCreated;
use App\Notifications\NewPostNotification;

class NotifySubscribers
{
    public function handle(PostCreated $event): void
    {
        $subscribers = User::whereHas('subscriptions', function ($query) use ($event) {
            $query->where('user_id', $event->post->user_id);
        })->get();

        $subscribers->each(function ($subscriber) use ($event) {
            $subscriber->notify(new NewPostNotification($event->post));
        });
    }
}
```

### 8. Job Queues

**Queueable Jobs:**

```php
namespace App\Jobs;

use App\Models\Post;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessPostImage implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 3;
    public $timeout = 120;

    public function __construct(
        public Post $post,
        public string $imagePath
    ) {}

    public function handle(): void
    {
        // Process image (resize, optimize, etc.)
        $processedPath = $this->processImage($this->imagePath);

        $this->post->update(['featured_image' => $processedPath]);
    }

    public function failed(\Throwable $exception): void
    {
        // Handle job failure
        \Log::error('Image processing failed', [
            'post_id' => $this->post->id,
            'error' => $exception->getMessage(),
        ]);
    }
}
```

### 9. Policy Authorization

**Policy Classes:**

```php
namespace App\Policies;

use App\Models\Post;
use App\Models\User;

class PostPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(?User $user, Post $post): bool
    {
        return $post->status === 'published' || $user?->id === $post->user_id;
    }

    public function create(User $user): bool
    {
        return $user->hasRole('author');
    }

    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id || $user->hasRole('admin');
    }

    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->user_id || $user->hasRole('admin');
    }
}
```

### 10. Testing

**Feature Testing:**

```php
namespace Tests\Feature;

use App\Models\User;
use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PostControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_post(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->postJson('/api/posts', [
                'title' => 'Test Post',
                'content' => 'This is a test post with enough content to pass validation.',
                'status' => 'draft',
            ]);

        $response->assertCreated()
            ->assertJsonStructure([
                'data' => ['id', 'title', 'content'],
                'message',
            ]);

        $this->assertDatabaseHas('posts', [
            'title' => 'Test Post',
            'user_id' => $user->id,
        ]);
    }
}
```

## Project Structure

**Recommended Laravel Project Structure:**

```
app/
├── Console/
│   └── Commands/
├── Events/
├── Exceptions/
├── Http/
│   ├── Controllers/
│   │   └── Api/
│   ├── Middleware/
│   ├── Requests/
│   └── Resources/
├── Jobs/
├── Listeners/
├── Models/
├── Notifications/
├── Policies/
├── Providers/
└── Services/
```

## Best Practices

1. **Use Service Layer** for complex business logic
2. **Implement Repository Pattern** for data access abstraction
3. **Use Form Requests** for validation
4. **Apply Policy Classes** for authorization
5. **Leverage Events** for decoupled architecture
6. **Queue Long-Running Tasks** with Laravel Jobs
7. **Use API Resources** for consistent API responses
8. **Implement Proper Error Handling** with custom exceptions
9. **Write Tests** (feature and unit tests)
10. **Follow PSR Standards** for code style

## Additional Resources

For more advanced patterns, see:
- [authentication.md](authentication.md) - Advanced authentication patterns
- [testing.md](testing.md) - Comprehensive testing strategies
- [performance.md](performance.md) - Performance optimization techniques
