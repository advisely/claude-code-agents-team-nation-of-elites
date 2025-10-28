---
name: react-patterns
description: React architecture, hooks patterns, and performance optimization for building modern frontend applications
---

# React Development Patterns

## When to Use This Skill

- Building React frontend applications
- Implementing component architecture
- Optimizing React performance
- Managing state effectively
- Following React best practices

## Target Agents

- `react-expert` - Primary user for React development
- `react-typescript-expert` - Type-safe React development
- `frontend-developer` - General frontend development with React
- `nextjs-expert` - Next.js-specific patterns

## Core Patterns

### 1. Component Architecture

**Container/Presentational Pattern:**

```jsx
// Container Component (Logic)
function UserListContainer() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers().then(data => {
      setUsers(data);
      setLoading(false);
    });
  }, []);

  return <UserList users={users} loading={loading} />;
}

// Presentational Component (UI)
function UserList({ users, loading }) {
  if (loading) return <Spinner />;

  return (
    <ul>
      {users.map(user => (
        <UserItem key={user.id} user={user} />
      ))}
    </ul>
  );
}
```

**Compound Components Pattern:**

```jsx
function Accordion({ children }) {
  const [openIndex, setOpenIndex] = useState(null);

  return (
    <AccordionContext.Provider value={{ openIndex, setOpenIndex }}>
      <div className="accordion">{children}</div>
    </AccordionContext.Provider>
  );
}

function AccordionItem({ index, title, children }) {
  const { openIndex, setOpenIndex } = useContext(AccordionContext);
  const isOpen = openIndex === index;

  return (
    <div>
      <button onClick={() => setOpenIndex(isOpen ? null : index)}>
        {title}
      </button>
      {isOpen && <div>{children}</div>}
    </div>
  );
}

// Usage
<Accordion>
  <AccordionItem index={0} title="Section 1">Content 1</AccordionItem>
  <AccordionItem index={1} title="Section 2">Content 2</AccordionItem>
</Accordion>
```

### 2. Custom Hooks Patterns

**Data Fetching Hook:**

```jsx
function useFetch(url) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const abortController = new AbortController();

    setLoading(true);
    fetch(url, { signal: abortController.signal })
      .then(res => res.json())
      .then(data => {
        setData(data);
        setLoading(false);
      })
      .catch(err => {
        if (err.name !== 'AbortError') {
          setError(err);
          setLoading(false);
        }
      });

    return () => abortController.abort();
  }, [url]);

  return { data, loading, error };
}

// Usage
function UserProfile({ userId }) {
  const { data: user, loading, error } = useFetch(`/api/users/${userId}`);

  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  return <UserCard user={user} />;
}
```

**Form Handling Hook:**

```jsx
function useForm(initialValues, onSubmit) {
  const [values, setValues] = useState(initialValues);
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setValues(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      await onSubmit(values);
    } catch (error) {
      setErrors(error.errors || {});
    } finally {
      setIsSubmitting(false);
    }
  };

  return {
    values,
    errors,
    isSubmitting,
    handleChange,
    handleSubmit,
  };
}
```

### 3. State Management

**Context + useReducer Pattern:**

```jsx
// reducer.js
export const initialState = {
  user: null,
  theme: 'light',
  notifications: [],
};

export function appReducer(state, action) {
  switch (action.type) {
    case 'SET_USER':
      return { ...state, user: action.payload };
    case 'TOGGLE_THEME':
      return { ...state, theme: state.theme === 'light' ? 'dark' : 'light' };
    case 'ADD_NOTIFICATION':
      return { ...state, notifications: [...state.notifications, action.payload] };
    default:
      return state;
  }
}

// AppContext.jsx
const AppContext = createContext();

export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  return (
    <AppContext.Provider value={{ state, dispatch }}>
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within AppProvider');
  return context;
}

// Usage
function UserProfile() {
  const { state, dispatch } = useApp();

  const handleLogin = (user) => {
    dispatch({ type: 'SET_USER', payload: user });
  };

  return <div>{state.user?.name || 'Guest'}</div>;
}
```

### 4. Performance Optimization

**Memoization Patterns:**

```jsx
// useMemo for expensive calculations
function ProductList({ products, searchTerm }) {
  const filteredProducts = useMemo(() => {
    return products.filter(p =>
      p.name.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [products, searchTerm]);

  return <div>{filteredProducts.map(p => <ProductCard key={p.id} product={p} />)}</div>;
}

// useCallback for function props
function Parent() {
  const [count, setCount] = useState(0);

  const handleClick = useCallback(() => {
    console.log('Button clicked');
  }, []); // Stable reference

  return <Child onClick={handleClick} />;
}

const Child = memo(({ onClick }) => {
  console.log('Child rendered');
  return <button onClick={onClick}>Click me</button>;
});

// React.memo for component optimization
const ExpensiveComponent = memo(
  function ExpensiveComponent({ data }) {
    // Complex rendering logic
    return <div>{/* ... */}</div>;
  },
  (prevProps, nextProps) => {
    // Custom comparison
    return prevProps.data.id === nextProps.data.id;
  }
);
```

**Code Splitting:**

```jsx
// Lazy loading components
const Dashboard = lazy(() => import('./Dashboard'));
const Settings = lazy(() => import('./Settings'));

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}

// Lazy loading with retry logic
function lazyWithRetry(componentImport) {
  return lazy(async () => {
    const pageHasAlreadyBeenForceRefreshed = JSON.parse(
      window.localStorage.getItem('page-has-been-force-refreshed') || 'false'
    );

    try {
      const component = await componentImport();
      window.localStorage.setItem('page-has-been-force-refreshed', 'false');
      return component;
    } catch (error) {
      if (!pageHasAlreadyBeenForceRefreshed) {
        window.localStorage.setItem('page-has-been-force-refreshed', 'true');
        return window.location.reload();
      }
      throw error;
    }
  });
}
```

### 5. Error Handling

**Error Boundary:**

```jsx
class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
    // Log to error reporting service
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || <ErrorFallback error={this.state.error} />;
    }

    return this.props.children;
  }
}

// Usage
function App() {
  return (
    <ErrorBoundary fallback={<ErrorPage />}>
      <Dashboard />
    </ErrorBoundary>
  );
}
```

### 6. Testing Patterns

**Component Testing with React Testing Library:**

```jsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('LoginForm', () => {
  it('submits form with user credentials', async () => {
    const handleSubmit = jest.fn();
    render(<LoginForm onSubmit={handleSubmit} />);

    // Find elements
    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const submitButton = screen.getByRole('button', { name: /login/i });

    // Interact with elements
    await userEvent.type(emailInput, 'test@example.com');
    await userEvent.type(passwordInput, 'password123');
    fireEvent.click(submitButton);

    // Assert
    await waitFor(() => {
      expect(handleSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123',
      });
    });
  });
});
```

### 7. Folder Structure

**Feature-Based Structure:**

```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   │   ├── LoginForm.jsx
│   │   │   └── RegisterForm.jsx
│   │   ├── hooks/
│   │   │   └── useAuth.js
│   │   ├── api/
│   │   │   └── authAPI.js
│   │   └── index.js
│   ├── dashboard/
│   └── profile/
├── shared/
│   ├── components/
│   │   ├── Button.jsx
│   │   └── Input.jsx
│   ├── hooks/
│   │   └── useFetch.js
│   └── utils/
│       └── helpers.js
├── App.jsx
└── index.jsx
```

## Best Practices

1. **Use functional components and hooks** (avoid class components)
2. **Keep components small and focused** (single responsibility)
3. **Extract reusable logic into custom hooks**
4. **Use TypeScript** for type safety (when possible)
5. **Implement proper error boundaries**
6. **Optimize with React.memo, useMemo, useCallback** (when needed)
7. **Use key prop correctly** (stable, unique identifiers)
8. **Avoid inline function definitions** in render
9. **Leverage code splitting** for large applications
10. **Write tests for critical functionality**

## Common Anti-Patterns to Avoid

❌ **Don't mutate state directly**
```jsx
// Bad
state.items.push(newItem);

// Good
setState(prev => ({ ...prev, items: [...prev.items, newItem] }));
```

❌ **Don't use index as key**
```jsx
// Bad
{items.map((item, index) => <Item key={index} {...item} />)}

// Good
{items.map(item => <Item key={item.id} {...item} />)}
```

❌ **Don't forget cleanup in useEffect**
```jsx
// Bad
useEffect(() => {
  const subscription = api.subscribe();
}, []);

// Good
useEffect(() => {
  const subscription = api.subscribe();
  return () => subscription.unsubscribe();
}, []);
```

## Additional Resources

For more advanced patterns, see:
- [typescript-patterns.md](typescript-patterns.md) - TypeScript-specific React patterns
- [performance.md](performance.md) - Advanced performance optimization
- [testing.md](testing.md) - Comprehensive testing strategies
