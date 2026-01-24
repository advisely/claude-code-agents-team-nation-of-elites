---
name: typescript-patterns
description: TypeScript best practices including advanced types, generics, utility types, discriminated unions, and type-safe patterns for enterprise applications.
---

# TypeScript Patterns & Best Practices

## Advanced Types

### Discriminated Unions
```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

function handleResult<T>(result: Result<T>): T | null {
  if (result.success) {
    return result.data; // TypeScript knows data exists here
  }
  console.error(result.error); // TypeScript knows error exists here
  return null;
}

// API Response pattern
type ApiResponse<T> =
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string };
```

### Template Literal Types
```typescript
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type ApiEndpoint = `/api/${string}`;
type ApiRoute = `${HttpMethod} ${ApiEndpoint}`;

const route: ApiRoute = 'GET /api/users'; // ✅
const badRoute: ApiRoute = 'PATCH /api/users'; // ❌ Error

// Event handlers
type EventName = 'click' | 'focus' | 'blur';
type EventHandler = `on${Capitalize<EventName>}`;
// 'onClick' | 'onFocus' | 'onBlur'
```

### Mapped Types
```typescript
// Make all properties optional and readonly
type Immutable<T> = {
  readonly [K in keyof T]: T[K] extends object
    ? Immutable<T[K]>
    : T[K];
};

// Extract only certain property types
type ExtractStrings<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K];
};

// Prefix all keys
type Prefixed<T, P extends string> = {
  [K in keyof T as `${P}${Capitalize<string & K>}`]: T[K];
};
```

## Generic Patterns

### Constrained Generics
```typescript
// Ensure T has an id property
function findById<T extends { id: string | number }>(
  items: T[],
  id: T['id']
): T | undefined {
  return items.find(item => item.id === id);
}

// Generic with default
function createState<T = {}>(initial: T): [T, (update: Partial<T>) => void] {
  let state = initial;
  const setState = (update: Partial<T>) => {
    state = { ...state, ...update };
  };
  return [state, setState];
}
```

### Generic Constraints with keyof
```typescript
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

function setProperty<T, K extends keyof T>(
  obj: T,
  key: K,
  value: T[K]
): void {
  obj[key] = value;
}

// Pick certain keys
function pick<T, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
  const result = {} as Pick<T, K>;
  keys.forEach(key => {
    result[key] = obj[key];
  });
  return result;
}
```

### Conditional Types
```typescript
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;
type UnwrapArray<T> = T extends Array<infer U> ? U : T;

// Recursive unwrap
type DeepUnwrap<T> = T extends Promise<infer U>
  ? DeepUnwrap<U>
  : T extends Array<infer U>
  ? DeepUnwrap<U>[]
  : T;

// Function return type extraction
type AsyncReturnType<T extends (...args: any) => Promise<any>> =
  T extends (...args: any) => Promise<infer R> ? R : never;
```

## Utility Types

### Built-in Utility Types
```typescript
interface User {
  id: number;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

// Partial - all optional
type UserUpdate = Partial<User>;

// Required - all required
type RequiredUser = Required<User>;

// Readonly - immutable
type ReadonlyUser = Readonly<User>;

// Pick - select properties
type UserPreview = Pick<User, 'id' | 'name'>;

// Omit - exclude properties
type UserWithoutPassword = Omit<User, 'password'>;

// Record - object type
type UserRoles = Record<string, 'admin' | 'user' | 'guest'>;

// Extract/Exclude - filter unions
type NumericKeys = Extract<keyof User, number>;
type StringKeys = Exclude<keyof User, 'id'>;
```

### Custom Utility Types
```typescript
// Deep Partial
type DeepPartial<T> = T extends object
  ? { [P in keyof T]?: DeepPartial<T[P]> }
  : T;

// Nullable
type Nullable<T> = T | null;

// NonNullableKeys
type NonNullableKeys<T> = {
  [K in keyof T]: null extends T[K] ? never : K;
}[keyof T];

// RequiredKeys
type RequiredKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? never : K;
}[keyof T];

// Mutable (remove readonly)
type Mutable<T> = {
  -readonly [P in keyof T]: T[P];
};
```

## Type Guards

### Custom Type Guards
```typescript
interface Cat { meow(): void; }
interface Dog { bark(): void; }

function isCat(animal: Cat | Dog): animal is Cat {
  return (animal as Cat).meow !== undefined;
}

function handleAnimal(animal: Cat | Dog) {
  if (isCat(animal)) {
    animal.meow(); // TypeScript knows it's a Cat
  } else {
    animal.bark(); // TypeScript knows it's a Dog
  }
}

// Assertion function
function assertIsString(value: unknown): asserts value is string {
  if (typeof value !== 'string') {
    throw new Error('Value is not a string');
  }
}
```

### Type Narrowing
```typescript
function processValue(value: string | number | null) {
  // typeof narrowing
  if (typeof value === 'string') {
    return value.toUpperCase();
  }

  // Truthiness narrowing
  if (value) {
    return value.toFixed(2);
  }

  return 'null value';
}

// in operator narrowing
type Fish = { swim: () => void };
type Bird = { fly: () => void };

function move(animal: Fish | Bird) {
  if ('swim' in animal) {
    animal.swim();
  } else {
    animal.fly();
  }
}
```

## Class Patterns

### Builder Pattern
```typescript
class RequestBuilder {
  private url = '';
  private method: HttpMethod = 'GET';
  private headers: Record<string, string> = {};
  private body?: unknown;

  setUrl(url: string): this {
    this.url = url;
    return this;
  }

  setMethod(method: HttpMethod): this {
    this.method = method;
    return this;
  }

  setHeader(key: string, value: string): this {
    this.headers[key] = value;
    return this;
  }

  setBody<T>(body: T): this {
    this.body = body;
    return this;
  }

  build(): Request {
    return new Request(this.url, {
      method: this.method,
      headers: this.headers,
      body: this.body ? JSON.stringify(this.body) : undefined,
    });
  }
}
```

### Repository Pattern
```typescript
interface Repository<T, ID> {
  findById(id: ID): Promise<T | null>;
  findAll(): Promise<T[]>;
  create(entity: Omit<T, 'id'>): Promise<T>;
  update(id: ID, entity: Partial<T>): Promise<T>;
  delete(id: ID): Promise<void>;
}

class UserRepository implements Repository<User, number> {
  async findById(id: number): Promise<User | null> {
    // Implementation
  }
  // ... other methods
}
```

## Module Patterns

### Barrel Exports
```typescript
// types/index.ts
export type { User, UserCreate, UserUpdate } from './user';
export type { Post, PostCreate } from './post';
export type { ApiResponse, PaginatedResponse } from './api';

// Usage
import type { User, Post, ApiResponse } from './types';
```

### Strict Exports
```typescript
// Only export what's needed
export { UserService };
export type { User, UserCreate };

// Don't export implementation details
// private helper functions stay private
function internalHelper() { }
```

## Error Handling

### Typed Errors
```typescript
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

class NotFoundError extends AppError {
  constructor(resource: string) {
    super(`${resource} not found`, 'NOT_FOUND', 404);
  }
}

// Type-safe error handling
function handleError(error: unknown): AppError {
  if (error instanceof AppError) {
    return error;
  }
  if (error instanceof Error) {
    return new AppError(error.message, 'UNKNOWN');
  }
  return new AppError('Unknown error', 'UNKNOWN');
}
```
