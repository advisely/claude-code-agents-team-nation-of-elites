---
name: pytest-patterns
description: Pytest testing patterns, fixtures, mocking, parametrization, and comprehensive Python testing strategies
---

# Pytest Testing Patterns

## When to Use This Skill

- Writing Python tests with pytest
- Creating test fixtures
- Mocking external dependencies
- Parametrized testing
- Testing best practices

## Target Agents

- `backend-developer` - Testing Python code
- `django-expert` - Django testing
- `qa-engineer` - Test automation

## Core Patterns

### 1. Basic Test Structure

```python
import pytest

def test_addition():
    assert 1 + 1 == 2

def test_subtraction():
    assert 5 - 3 == 2

class TestMath:
    def test_multiply(self):
        assert 2 * 3 == 6

    def test_divide(self):
        assert 10 / 2 == 5
```

### 2. Fixtures

```python
import pytest
from myapp import create_app, db

@pytest.fixture
def app():
    app = create_app('testing')
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def user(app):
    user = User(email='test@example.com')
    db.session.add(user)
    db.session.commit()
    return user

def test_user_creation(user):
    assert user.email == 'test@example.com'
```

### 3. Parametrization

```python
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert input * 2 == expected

@pytest.mark.parametrize("email,valid", [
    ("test@example.com", True),
    ("invalid-email", False),
    ("", False),
])
def test_email_validation(email, valid):
    assert validate_email(email) == valid
```

### 4. Mocking

```python
from unittest.mock import Mock, patch

def test_api_call():
    with patch('requests.get') as mock_get:
        mock_get.return_value.json.return_value = {'data': 'test'}
        mock_get.return_value.status_code = 200

        result = fetch_data()

        assert result == {'data': 'test'}
        mock_get.assert_called_once()
```

## Best Practices

1. Use **fixtures** for setup
2. **Parametrize** similar tests
3. **Mock** external dependencies
4. Use **pytest marks** for categorization
5. Implement **conftest.py** for shared fixtures
6. Use **pytest-cov** for coverage
7. Write **descriptive test names**
8. Test **edge cases**
9. Keep tests **independent**
10. Use **pytest-django** for Django
