---
name: python-patterns
description: Python best practices including type hints, async/await, context managers, dataclasses, and modern Python 3.12+ features.
---

# Python Patterns & Best Practices

## Type Hints (Python 3.12+)

### Modern Type Syntax
```python
# Python 3.12+ - No need for Optional, Union imports
def process(data: str | None) -> list[dict[str, int]]:
    pass

# Generic types
def first[T](items: list[T]) -> T | None:
    return items[0] if items else None

# Type aliases
type UserDict = dict[str, str | int | None]
type Callback[T] = Callable[[T], None]
```

### Protocol for Structural Typing
```python
from typing import Protocol

class Drawable(Protocol):
    def draw(self) -> None: ...

class Circle:
    def draw(self) -> None:
        print("Drawing circle")

def render(shape: Drawable) -> None:
    shape.draw()  # Works with any class that has draw()
```

## Dataclasses & Attrs

### Dataclass with Validation
```python
from dataclasses import dataclass, field
from datetime import datetime

@dataclass(frozen=True, slots=True)
class User:
    id: int
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    roles: list[str] = field(default_factory=list)

    def __post_init__(self):
        if '@' not in self.email:
            raise ValueError("Invalid email")
```

### Pydantic Models
```python
from pydantic import BaseModel, EmailStr, Field, field_validator

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    age: int = Field(ge=0, le=150)

    @field_validator('password')
    @classmethod
    def password_strength(cls, v: str) -> str:
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase')
        return v
```

## Async/Await Patterns

### Concurrent Execution
```python
import asyncio
from typing import Coroutine, Any

async def fetch_all(urls: list[str]) -> list[dict]:
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_url(session, url) for url in urls]
        return await asyncio.gather(*tasks, return_exceptions=True)

# Semaphore for rate limiting
async def fetch_with_limit(urls: list[str], limit: int = 10) -> list:
    semaphore = asyncio.Semaphore(limit)

    async def limited_fetch(url: str):
        async with semaphore:
            return await fetch_url(url)

    return await asyncio.gather(*[limited_fetch(u) for u in urls])
```

### Async Context Managers
```python
from contextlib import asynccontextmanager
from typing import AsyncIterator

@asynccontextmanager
async def get_db_connection() -> AsyncIterator[Connection]:
    conn = await create_connection()
    try:
        yield conn
    finally:
        await conn.close()

async def query_users():
    async with get_db_connection() as conn:
        return await conn.fetch("SELECT * FROM users")
```

## Context Managers

### Custom Context Manager
```python
from contextlib import contextmanager
from typing import Iterator
import time

@contextmanager
def timer(name: str) -> Iterator[None]:
    start = time.perf_counter()
    try:
        yield
    finally:
        elapsed = time.perf_counter() - start
        print(f"{name} took {elapsed:.4f}s")

with timer("data processing"):
    process_large_dataset()
```

### Multiple Context Managers
```python
from contextlib import ExitStack

def process_files(filenames: list[str]) -> None:
    with ExitStack() as stack:
        files = [stack.enter_context(open(f)) for f in filenames]
        # All files automatically closed on exit
        for f in files:
            process(f)
```

## Error Handling

### Exception Groups (Python 3.11+)
```python
async def fetch_all_or_fail(urls: list[str]):
    errors = []
    results = []

    for url in urls:
        try:
            results.append(await fetch(url))
        except Exception as e:
            errors.append(e)

    if errors:
        raise ExceptionGroup("Multiple fetch failures", errors)

    return results

# Handling exception groups
try:
    await fetch_all_or_fail(urls)
except* ConnectionError as eg:
    print(f"Connection errors: {eg.exceptions}")
except* TimeoutError as eg:
    print(f"Timeouts: {eg.exceptions}")
```

### Custom Exceptions
```python
class AppError(Exception):
    def __init__(self, message: str, code: str, details: dict | None = None):
        super().__init__(message)
        self.code = code
        self.details = details or {}

class NotFoundError(AppError):
    def __init__(self, resource: str, id: Any):
        super().__init__(
            f"{resource} with id {id} not found",
            code="NOT_FOUND",
            details={"resource": resource, "id": id}
        )
```

## Generators & Iterators

### Generator for Large Data
```python
from typing import Iterator
from pathlib import Path

def read_large_file(path: Path, chunk_size: int = 8192) -> Iterator[str]:
    with open(path) as f:
        while chunk := f.read(chunk_size):
            yield chunk

# Memory-efficient processing
for chunk in read_large_file(Path("large.txt")):
    process(chunk)
```

### Generator Expressions vs List Comprehensions
```python
# ✅ Generator - memory efficient
total = sum(x**2 for x in range(1_000_000))

# ❌ List comprehension - loads all into memory
total = sum([x**2 for x in range(1_000_000)])
```

## Decorators

### Decorator with Arguments
```python
from functools import wraps
from typing import Callable, ParamSpec, TypeVar

P = ParamSpec('P')
R = TypeVar('R')

def retry(max_attempts: int = 3, delay: float = 1.0):
    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        @wraps(func)
        async def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            for attempt in range(max_attempts):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
                    await asyncio.sleep(delay * (2 ** attempt))
        return wrapper
    return decorator

@retry(max_attempts=5, delay=0.5)
async def flaky_operation():
    ...
```

## Testing

### Pytest Fixtures
```python
import pytest
from unittest.mock import AsyncMock, patch

@pytest.fixture
async def db_session():
    session = await create_test_session()
    yield session
    await session.rollback()
    await session.close()

@pytest.fixture
def mock_api():
    with patch("myapp.external_api") as mock:
        mock.fetch = AsyncMock(return_value={"data": "test"})
        yield mock

async def test_user_creation(db_session, mock_api):
    user = await create_user(db_session, "test@example.com")
    assert user.email == "test@example.com"
    mock_api.fetch.assert_called_once()
```

## Performance

### LRU Cache
```python
from functools import lru_cache, cache

@lru_cache(maxsize=128)
def fibonacci(n: int) -> int:
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# Python 3.9+ - Unlimited cache
@cache
def expensive_computation(x: int) -> int:
    return x ** x
```

### `__slots__` for Memory
```python
class Point:
    __slots__ = ('x', 'y')

    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y
# Uses ~40% less memory than regular class
```
