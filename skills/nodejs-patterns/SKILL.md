---
name: nodejs-patterns
description: Node.js best practices including async patterns, streams, worker threads, error handling, and performance optimization for server-side JavaScript.
---

# Node.js Patterns & Best Practices

## Async Patterns

### Proper Promise Handling
```javascript
// ✅ Good - Parallel execution
const [users, orders] = await Promise.all([
  fetchUsers(),
  fetchOrders()
]);

// ✅ Good - Error handling with Promise.allSettled
const results = await Promise.allSettled([
  riskyOperation1(),
  riskyOperation2()
]);

results.forEach((result, index) => {
  if (result.status === 'rejected') {
    console.error(`Operation ${index} failed:`, result.reason);
  }
});

// ❌ Bad - Sequential when parallel is possible
const users = await fetchUsers();
const orders = await fetchOrders();
```

### Async Iteration
```javascript
// Stream processing with for-await
async function* readLines(stream) {
  for await (const chunk of stream) {
    yield* chunk.toString().split('\n');
  }
}

// Process large files without memory issues
for await (const line of readLines(fileStream)) {
  await processLine(line);
}
```

## Error Handling

### Custom Error Classes
```javascript
class AppError extends Error {
  constructor(message, statusCode, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    Error.captureStackTrace(this, this.constructor);
  }
}

class NotFoundError extends AppError {
  constructor(resource) {
    super(`${resource} not found`, 404);
  }
}

class ValidationError extends AppError {
  constructor(errors) {
    super('Validation failed', 400);
    this.errors = errors;
  }
}
```

### Global Error Handler
```javascript
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
```

## Streams

### Transform Stream
```javascript
import { Transform } from 'stream';

const upperCaseTransform = new Transform({
  transform(chunk, encoding, callback) {
    this.push(chunk.toString().toUpperCase());
    callback();
  }
});

readStream.pipe(upperCaseTransform).pipe(writeStream);
```

### Pipeline for Error Handling
```javascript
import { pipeline } from 'stream/promises';
import { createGzip } from 'zlib';

await pipeline(
  fs.createReadStream('input.txt'),
  createGzip(),
  fs.createWriteStream('output.txt.gz')
);
```

## Worker Threads

### CPU-Intensive Tasks
```javascript
import { Worker, isMainThread, parentPort, workerData } from 'worker_threads';

if (isMainThread) {
  const worker = new Worker(__filename, {
    workerData: { numbers: [1, 2, 3, 4, 5] }
  });

  worker.on('message', (result) => console.log('Result:', result));
  worker.on('error', (error) => console.error('Worker error:', error));
} else {
  const sum = workerData.numbers.reduce((a, b) => a + b, 0);
  parentPort.postMessage(sum);
}
```

### Worker Pool
```javascript
import { Worker } from 'worker_threads';
import os from 'os';

class WorkerPool {
  constructor(workerScript, poolSize = os.cpus().length) {
    this.workers = [];
    this.queue = [];

    for (let i = 0; i < poolSize; i++) {
      this.workers.push(this.createWorker(workerScript));
    }
  }

  async runTask(data) {
    return new Promise((resolve, reject) => {
      this.queue.push({ data, resolve, reject });
      this.processQueue();
    });
  }
}
```

## Performance Optimization

### Event Loop Best Practices
```javascript
// ✅ Good - Break up long operations
async function processLargeArray(items) {
  const batchSize = 100;
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    await Promise.all(batch.map(process));
    // Allow event loop to handle other tasks
    await setImmediate(() => {});
  }
}

// ❌ Bad - Blocking the event loop
function processSync(items) {
  items.forEach(item => heavyComputation(item));
}
```

### Memory Management
```javascript
// Use WeakMap for caches that shouldn't prevent GC
const cache = new WeakMap();

function getCachedResult(obj) {
  if (!cache.has(obj)) {
    cache.set(obj, expensiveComputation(obj));
  }
  return cache.get(obj);
}
```

## Module Patterns

### ES Modules Best Practices
```javascript
// Named exports for utilities
export { fetchUser, fetchOrders, fetchProducts };

// Default export for main class/function
export default class UserService { }

// Re-export pattern
export * from './users.js';
export * from './orders.js';
```

### Dependency Injection
```javascript
class UserService {
  constructor(database, cache, logger) {
    this.db = database;
    this.cache = cache;
    this.logger = logger;
  }
}

// Factory function
function createUserService(config) {
  const db = new Database(config.db);
  const cache = new Redis(config.redis);
  const logger = new Logger(config.logLevel);
  return new UserService(db, cache, logger);
}
```

## Configuration Management

### Environment Variables
```javascript
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  PORT: z.string().transform(Number).default('3000'),
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(32),
});

export const env = envSchema.parse(process.env);
```

## Testing Patterns

### Mocking with Node Test Runner
```javascript
import { test, mock } from 'node:test';
import assert from 'node:assert';

test('user service creates user', async (t) => {
  const mockDb = {
    insert: mock.fn(() => Promise.resolve({ id: 1 }))
  };

  const service = new UserService(mockDb);
  const user = await service.create({ name: 'Test' });

  assert.strictEqual(user.id, 1);
  assert.strictEqual(mockDb.insert.mock.calls.length, 1);
});
```
