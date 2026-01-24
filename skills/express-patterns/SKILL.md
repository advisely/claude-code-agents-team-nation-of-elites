---
name: express-patterns
description: Express.js best practices including middleware patterns, error handling, authentication, validation, and production-ready API architecture.
---

# Express.js Patterns & Best Practices

## Project Structure

```
src/
├── app.ts                 # Express app setup
├── server.ts              # Server entry point
├── config/
│   ├── index.ts           # Configuration loader
│   └── database.ts        # Database config
├── routes/
│   ├── index.ts           # Route aggregator
│   ├── users.routes.ts
│   └── auth.routes.ts
├── controllers/
│   ├── users.controller.ts
│   └── auth.controller.ts
├── services/
│   ├── users.service.ts
│   └── auth.service.ts
├── middleware/
│   ├── auth.middleware.ts
│   ├── error.middleware.ts
│   └── validate.middleware.ts
├── models/
│   └── user.model.ts
├── utils/
│   ├── logger.ts
│   └── asyncHandler.ts
└── types/
    └── express.d.ts       # Express type extensions
```

## Application Setup

### App Configuration
```typescript
import express, { Application } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import rateLimit from 'express-rate-limit';

export function createApp(): Application {
  const app = express();

  // Security middleware
  app.use(helmet());
  app.use(cors({
    origin: process.env.CORS_ORIGIN,
    credentials: true
  }));

  // Rate limiting
  app.use(rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
  }));

  // Body parsing
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(compression());

  // Routes
  app.use('/api/v1', routes);

  // Error handling (must be last)
  app.use(errorHandler);

  return app;
}
```

## Middleware Patterns

### Async Handler Wrapper
```typescript
import { Request, Response, NextFunction, RequestHandler } from 'express';

export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<any>
): RequestHandler => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Usage
router.get('/users', asyncHandler(async (req, res) => {
  const users = await userService.findAll();
  res.json(users);
}));
```

### Authentication Middleware
```typescript
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  user?: { id: number; email: string; role: string };
}

export const authenticate = asyncHandler(
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedError('No token provided');
    }

    const token = authHeader.split(' ')[1];

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
      req.user = decoded;
      next();
    } catch (error) {
      throw new UnauthorizedError('Invalid token');
    }
  }
);

export const authorize = (...roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      throw new ForbiddenError('Insufficient permissions');
    }
    next();
  };
};
```

### Validation Middleware
```typescript
import { z, ZodSchema } from 'zod';

export const validate = (schema: ZodSchema) => {
  return asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse({
      body: req.body,
      query: req.query,
      params: req.params,
    });

    if (!result.success) {
      throw new ValidationError(result.error.errors);
    }

    req.body = result.data.body;
    req.query = result.data.query;
    req.params = result.data.params;
    next();
  });
};

// Usage
const createUserSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(8),
    name: z.string().min(2),
  }),
});

router.post('/users', validate(createUserSchema), userController.create);
```

## Error Handling

### Custom Error Classes
```typescript
export class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number,
    public code: string,
    public isOperational = true
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string) {
    super(`${resource} not found`, 404, 'NOT_FOUND');
  }
}

export class ValidationError extends AppError {
  constructor(public errors: any[]) {
    super('Validation failed', 400, 'VALIDATION_ERROR');
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
  }
}
```

### Global Error Handler
```typescript
import { ErrorRequestHandler } from 'express';

export const errorHandler: ErrorRequestHandler = (err, req, res, next) => {
  // Log error
  logger.error({
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  // Operational errors - send to client
  if (err instanceof AppError && err.isOperational) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        ...(err instanceof ValidationError && { errors: err.errors }),
      },
    });
  }

  // Programming errors - don't leak details
  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    },
  });
};
```

## Controllers

### Controller Pattern
```typescript
import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';

export class UserController {
  constructor(private userService: UserService) {}

  findAll = asyncHandler(async (req: Request, res: Response) => {
    const { page = 1, limit = 10 } = req.query;
    const users = await this.userService.findAll({
      page: Number(page),
      limit: Number(limit),
    });
    res.json(users);
  });

  findOne = asyncHandler(async (req: Request, res: Response) => {
    const user = await this.userService.findById(req.params.id);
    if (!user) {
      throw new NotFoundError('User');
    }
    res.json(user);
  });

  create = asyncHandler(async (req: Request, res: Response) => {
    const user = await this.userService.create(req.body);
    res.status(201).json(user);
  });

  update = asyncHandler(async (req: AuthRequest, res: Response) => {
    const user = await this.userService.update(req.params.id, req.body);
    res.json(user);
  });

  delete = asyncHandler(async (req: Request, res: Response) => {
    await this.userService.delete(req.params.id);
    res.status(204).send();
  });
}
```

## Routes

### Router Configuration
```typescript
import { Router } from 'express';

const router = Router();

router.route('/')
  .get(userController.findAll)
  .post(
    authenticate,
    authorize('admin'),
    validate(createUserSchema),
    userController.create
  );

router.route('/:id')
  .get(userController.findOne)
  .put(
    authenticate,
    validate(updateUserSchema),
    userController.update
  )
  .delete(
    authenticate,
    authorize('admin'),
    userController.delete
  );

export default router;
```

## Testing

### Integration Tests
```typescript
import request from 'supertest';
import { createApp } from '../src/app';

describe('Users API', () => {
  const app = createApp();

  describe('GET /api/v1/users', () => {
    it('returns list of users', async () => {
      const response = await request(app)
        .get('/api/v1/users')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('returns 401 without token', async () => {
      await request(app)
        .get('/api/v1/users')
        .expect(401);
    });
  });

  describe('POST /api/v1/users', () => {
    it('creates a new user', async () => {
      const response = await request(app)
        .post('/api/v1/users')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          email: 'new@example.com',
          password: 'password123',
          name: 'New User',
        })
        .expect(201);

      expect(response.body.email).toBe('new@example.com');
    });
  });
});
```

## Production Checklist

```typescript
// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});
```
