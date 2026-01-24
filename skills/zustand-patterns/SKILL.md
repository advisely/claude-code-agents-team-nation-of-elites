---
name: zustand-patterns
description: Zustand state management best practices including store design, slices pattern, persistence, devtools, and TypeScript integration.
---

# Zustand Patterns & Best Practices

## Basic Store

### Simple Store
```typescript
import { create } from 'zustand';

interface CounterState {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
}

const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));

// Usage
function Counter() {
  const { count, increment, decrement } = useCounterStore();
  return (
    <div>
      <span>{count}</span>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
    </div>
  );
}
```

## Slices Pattern

### Modular Store with Slices
```typescript
import { create, StateCreator } from 'zustand';

// User slice
interface UserSlice {
  user: User | null;
  setUser: (user: User | null) => void;
  logout: () => void;
}

const createUserSlice: StateCreator<
  UserSlice & CartSlice,
  [],
  [],
  UserSlice
> = (set) => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
});

// Cart slice
interface CartSlice {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
  clearCart: () => void;
}

const createCartSlice: StateCreator<
  UserSlice & CartSlice,
  [],
  [],
  CartSlice
> = (set) => ({
  items: [],
  addItem: (item) => set((state) => ({
    items: [...state.items, item]
  })),
  removeItem: (id) => set((state) => ({
    items: state.items.filter((i) => i.id !== id)
  })),
  clearCart: () => set({ items: [] }),
});

// Combined store
const useStore = create<UserSlice & CartSlice>()((...a) => ({
  ...createUserSlice(...a),
  ...createCartSlice(...a),
}));
```

## Async Actions

### Async Operations with Loading State
```typescript
interface AsyncState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

interface UserState extends AsyncState<User[]> {
  fetchUsers: () => Promise<void>;
  createUser: (user: UserCreate) => Promise<void>;
}

const useUserStore = create<UserState>((set, get) => ({
  data: null,
  loading: false,
  error: null,

  fetchUsers: async () => {
    set({ loading: true, error: null });
    try {
      const response = await fetch('/api/users');
      const users = await response.json();
      set({ data: users, loading: false });
    } catch (error) {
      set({ error: (error as Error).message, loading: false });
    }
  },

  createUser: async (user) => {
    set({ loading: true, error: null });
    try {
      const response = await fetch('/api/users', {
        method: 'POST',
        body: JSON.stringify(user),
      });
      const newUser = await response.json();
      set((state) => ({
        data: state.data ? [...state.data, newUser] : [newUser],
        loading: false,
      }));
    } catch (error) {
      set({ error: (error as Error).message, loading: false });
    }
  },
}));
```

## Middleware

### Persist Middleware
```typescript
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface SettingsState {
  theme: 'light' | 'dark';
  language: string;
  setTheme: (theme: 'light' | 'dark') => void;
  setLanguage: (lang: string) => void;
}

const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      theme: 'light',
      language: 'en',
      setTheme: (theme) => set({ theme }),
      setLanguage: (language) => set({ language }),
    }),
    {
      name: 'settings-storage',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        theme: state.theme,
        language: state.language,
      }),
    }
  )
);
```

### DevTools Middleware
```typescript
import { devtools } from 'zustand/middleware';

const useStore = create<StoreState>()(
  devtools(
    (set) => ({
      // ... store definition
    }),
    {
      name: 'MyStore',
      enabled: process.env.NODE_ENV === 'development',
    }
  )
);
```

### Immer Middleware
```typescript
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface TodoState {
  todos: Todo[];
  addTodo: (text: string) => void;
  toggleTodo: (id: string) => void;
  updateTodo: (id: string, text: string) => void;
}

const useTodoStore = create<TodoState>()(
  immer((set) => ({
    todos: [],

    addTodo: (text) =>
      set((state) => {
        state.todos.push({
          id: crypto.randomUUID(),
          text,
          completed: false,
        });
      }),

    toggleTodo: (id) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id);
        if (todo) {
          todo.completed = !todo.completed;
        }
      }),

    updateTodo: (id, text) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id);
        if (todo) {
          todo.text = text;
        }
      }),
  }))
);
```

### Combined Middleware
```typescript
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

const useStore = create<StoreState>()(
  devtools(
    persist(
      immer((set) => ({
        // Store definition with Immer
      })),
      { name: 'store' }
    ),
    { name: 'MyApp' }
  )
);
```

## Selectors

### Optimized Selectors
```typescript
import { useShallow } from 'zustand/react/shallow';

// Bad - re-renders on any state change
function Component() {
  const store = useStore();
  return <div>{store.user?.name}</div>;
}

// Good - only re-renders when user changes
function Component() {
  const user = useStore((state) => state.user);
  return <div>{user?.name}</div>;
}

// Good - multiple values with shallow comparison
function Component() {
  const { user, isLoading } = useStore(
    useShallow((state) => ({
      user: state.user,
      isLoading: state.isLoading,
    }))
  );
  return <div>{isLoading ? 'Loading...' : user?.name}</div>;
}
```

### Computed Values
```typescript
interface CartState {
  items: CartItem[];
  // Computed
  totalItems: () => number;
  totalPrice: () => number;
}

const useCartStore = create<CartState>((set, get) => ({
  items: [],

  totalItems: () => get().items.reduce((sum, item) => sum + item.quantity, 0),

  totalPrice: () =>
    get().items.reduce((sum, item) => sum + item.price * item.quantity, 0),
}));

// Usage
function CartSummary() {
  const totalItems = useCartStore((state) => state.totalItems());
  const totalPrice = useCartStore((state) => state.totalPrice());
  // ...
}
```

## TypeScript Patterns

### Typed Store Hook
```typescript
import { StoreApi, UseBoundStore } from 'zustand';

type WithSelectors<S> = S extends { getState: () => infer T }
  ? S & { use: { [K in keyof T]: () => T[K] } }
  : never;

const createSelectors = <S extends UseBoundStore<StoreApi<object>>>(
  _store: S
) => {
  const store = _store as WithSelectors<typeof _store>;
  store.use = {};
  for (const k of Object.keys(store.getState())) {
    (store.use as any)[k] = () => store((s) => s[k as keyof typeof s]);
  }
  return store;
};

// Usage
const useCounterStore = createSelectors(
  create<CounterState>((set) => ({
    count: 0,
    increment: () => set((s) => ({ count: s.count + 1 })),
  }))
);

// Auto-generated selectors
const count = useCounterStore.use.count();
const increment = useCounterStore.use.increment();
```

## Testing

### Testing Stores
```typescript
import { act, renderHook } from '@testing-library/react';
import { useCounterStore } from './counterStore';

describe('counterStore', () => {
  beforeEach(() => {
    // Reset store before each test
    useCounterStore.setState({ count: 0 });
  });

  it('increments count', () => {
    const { result } = renderHook(() => useCounterStore());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('resets count', () => {
    useCounterStore.setState({ count: 10 });
    const { result } = renderHook(() => useCounterStore());

    act(() => {
      result.current.reset();
    });

    expect(result.current.count).toBe(0);
  });
});
```

### Mocking Stores
```typescript
import { vi } from 'vitest';

vi.mock('./stores/userStore', () => ({
  useUserStore: vi.fn(() => ({
    user: { id: 1, name: 'Test User' },
    logout: vi.fn(),
  })),
}));
```

## Best Practices

### Do's
```typescript
// ✅ Use selectors for specific state
const user = useStore((s) => s.user);

// ✅ Use shallow for multiple values
const { a, b } = useStore(useShallow((s) => ({ a: s.a, b: s.b })));

// ✅ Keep actions in store
const increment = useStore((s) => s.increment);

// ✅ Use immer for complex updates
set((state) => { state.nested.deep.value = 'new'; });
```

### Don'ts
```typescript
// ❌ Don't subscribe to entire store
const store = useStore();

// ❌ Don't create new objects in selectors
const data = useStore((s) => ({ user: s.user })); // Creates new object every render

// ❌ Don't mutate state directly
set((state) => { state.count++; }); // Without immer middleware
```
