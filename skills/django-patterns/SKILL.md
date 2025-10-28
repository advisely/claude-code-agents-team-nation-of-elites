---
name: django-patterns
description: Django best practices, ORM optimization, and REST API patterns for building scalable Python web applications
---

# Django Development Patterns

## When to Use This Skill

- Building Django REST API backends
- Implementing authentication and authorization
- Database optimization with Django ORM
- Structuring Django projects for scalability
- Following Django and DRF best practices

## Target Agents

- `django-expert` - Primary user for Django-specific development
- `backend-developer` - General backend development with Django
- `api-architect` - REST API design using Django REST Framework

## Core Patterns

### 1. API View Architecture

**Use Django REST Framework's class-based views:**

- **`APIView`** - For custom logic and complex operations
- **`ViewSet`** - For standard CRUD operations
- **`GenericAPIView` with mixins** - For common patterns with customization

```python
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=True, methods=['post'])
    def set_password(self, request, pk=None):
        user = self.get_object()
        serializer = PasswordSerializer(data=request.data)
        if serializer.is_valid():
            user.set_password(serializer.validated_data['password'])
            user.save()
            return Response({'status': 'password set'})
        return Response(serializer.errors, status=400)
```

### 2. Authentication Strategy

**Recommended JWT Authentication Stack:**

```python
# settings.py
INSTALLED_APPS = [
    ...
    'rest_framework',
    'rest_framework_simplejwt',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
}

from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=15),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}
```

**Custom User Model (Always Recommended):**

```python
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models

class CustomUser(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    objects = CustomUserManager()
```

### 3. Database Optimization

**Query Optimization Patterns:**

```python
# ❌ N+1 Query Problem
for post in Post.objects.all():
    print(post.author.name)  # Hits database for each post!

# ✅ Use select_related for ForeignKey
posts = Post.objects.select_related('author').all()
for post in posts:
    print(post.author.name)  # Single query with JOIN

# ✅ Use prefetch_related for ManyToMany
posts = Post.objects.prefetch_related('tags').all()
for post in posts:
    print(post.tags.all())  # Efficient prefetching

# ✅ Combine both for complex queries
posts = Post.objects.select_related('author').prefetch_related('tags', 'comments__user').all()
```

**Database Indexing:**

```python
class Article(models.Model):
    title = models.CharField(max_length=200, db_index=True)
    slug = models.SlugField(unique=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        indexes = [
            models.Index(fields=['created_at', '-id']),  # Compound index
            models.Index(fields=['author', 'status']),    # Common filter combo
        ]
```

### 4. Serializer Patterns

**Nested Serializers:**

```python
class AuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Author
        fields = ['id', 'name', 'email']

class PostSerializer(serializers.ModelSerializer):
    author = AuthorSerializer(read_only=True)
    author_id = serializers.PrimaryKeyRelatedField(
        queryset=Author.objects.all(),
        source='author',
        write_only=True
    )

    class Meta:
        model = Post
        fields = ['id', 'title', 'content', 'author', 'author_id', 'created_at']
```

**Dynamic Field Selection:**

```python
class DynamicFieldsModelSerializer(serializers.ModelSerializer):
    def __init__(self, *args, **kwargs):
        fields = kwargs.pop('fields', None)
        super().__init__(*args, **kwargs)

        if fields is not None:
            allowed = set(fields)
            existing = set(self.fields)
            for field_name in existing - allowed:
                self.fields.pop(field_name)

# Usage: PostSerializer(post, fields=['id', 'title'])
```

### 5. Project Structure

**Recommended Django Project Layout:**

```
project_name/
├── manage.py
├── config/
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py      # Common settings
│   │   ├── dev.py       # Development
│   │   ├── prod.py      # Production
│   │   └── test.py      # Testing
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   ├── users/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── tests/
│   ├── posts/
│   └── comments/
└── requirements/
    ├── base.txt
    ├── dev.txt
    └── prod.txt
```

### 6. Error Handling

**Custom Exception Handler:**

```python
# exceptions.py
from rest_framework.views import exception_handler
from rest_framework.response import Response

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
        response.data = {
            'error': {
                'status_code': response.status_code,
                'message': response.data.get('detail', str(exc)),
                'errors': response.data if isinstance(response.data, dict) else {}
            }
        }

    return response

# settings.py
REST_FRAMEWORK = {
    'EXCEPTION_HANDLER': 'project.exceptions.custom_exception_handler'
}
```

### 7. Testing Patterns

**API Test Example:**

```python
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()

class PostAPITestCase(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        self.client.force_authenticate(user=self.user)

    def test_create_post(self):
        url = '/api/posts/'
        data = {'title': 'Test Post', 'content': 'Test content'}
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Test Post')
        self.assertEqual(response.data['author']['id'], self.user.id)
```

## Best Practices

1. **Always use environment variables** for sensitive data (use `django-environ`)
2. **Implement pagination** for list endpoints (use `PageNumberPagination`)
3. **Use database transactions** for multi-model operations (`@transaction.atomic`)
4. **Implement proper logging** (configure Django logging framework)
5. **Use Django signals carefully** (avoid circular dependencies)
6. **Write comprehensive tests** (aim for >80% coverage)
7. **Document APIs** with drf-spectacular or drf-yasg
8. **Use Django management commands** for recurring tasks
9. **Implement proper CORS** settings for frontend integration
10. **Use Celery** for background tasks and async operations

## Additional Resources

For more advanced patterns, see:
- [security.md](security.md) - Django security hardening checklist
- [performance.md](performance.md) - Advanced performance optimization
- [deployment.md](deployment.md) - Production deployment best practices
