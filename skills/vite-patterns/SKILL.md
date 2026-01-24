---
name: vite-patterns
description: Vite configuration best practices including plugins, build optimization, environment variables, SSR setup, and production deployment patterns.
---

# Vite Patterns & Best Practices

## Project Configuration

### vite.config.ts
```typescript
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  return {
    plugins: [
      react(),
      tsconfigPaths(),
      mode === 'analyze' && visualizer({
        open: true,
        filename: 'dist/stats.html',
      }),
    ],

    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
    },

    server: {
      port: 3000,
      proxy: {
        '/api': {
          target: env.VITE_API_URL || 'http://localhost:8000',
          changeOrigin: true,
        },
      },
    },

    build: {
      target: 'esnext',
      sourcemap: mode !== 'production',
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom'],
            router: ['react-router-dom'],
          },
        },
      },
    },

    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: './src/test/setup.ts',
    },
  };
});
```

## Environment Variables

### Type-Safe Env Variables
```typescript
// src/env.d.ts
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_APP_TITLE: string;
  readonly VITE_ENABLE_ANALYTICS: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

// src/config/env.ts
import { z } from 'zod';

const envSchema = z.object({
  VITE_API_URL: z.string().url(),
  VITE_APP_TITLE: z.string().default('My App'),
  VITE_ENABLE_ANALYTICS: z.string().transform(v => v === 'true'),
});

export const env = envSchema.parse(import.meta.env);
```

### .env Files
```bash
# .env (shared defaults)
VITE_APP_TITLE="My App"

# .env.development
VITE_API_URL=http://localhost:8000
VITE_ENABLE_ANALYTICS=false

# .env.production
VITE_API_URL=https://api.production.com
VITE_ENABLE_ANALYTICS=true
```

## Build Optimization

### Code Splitting
```typescript
// Route-based splitting
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

// Manual chunks
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          if (id.includes('node_modules')) {
            // Group large libraries
            if (id.includes('@tiptap')) return 'editor';
            if (id.includes('chart')) return 'charts';
            if (id.includes('date-fns')) return 'dates';
            return 'vendor';
          }
        },
      },
    },
  },
});
```

### Asset Optimization
```typescript
export default defineConfig({
  build: {
    // Inline small assets
    assetsInlineLimit: 4096,

    // CSS code splitting
    cssCodeSplit: true,

    // Minification
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },
  },
});
```

## Plugins

### Custom Plugin Example
```typescript
function timestampPlugin(): Plugin {
  return {
    name: 'timestamp-plugin',
    transformIndexHtml(html) {
      return html.replace(
        '<!-- BUILD_TIMESTAMP -->',
        `<!-- Built: ${new Date().toISOString()} -->`
      );
    },
  };
}

// SVG as component
import svgr from 'vite-plugin-svgr';

export default defineConfig({
  plugins: [
    react(),
    svgr({
      svgrOptions: {
        icon: true,
      },
    }),
    timestampPlugin(),
  ],
});
```

### Useful Plugin Stack
```typescript
import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';
import { compression } from 'vite-plugin-compression2';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    tsconfigPaths(),

    // Gzip/Brotli compression
    compression({
      algorithm: 'brotliCompress',
    }),

    // PWA support
    VitePWA({
      registerType: 'autoUpdate',
      manifest: {
        name: 'My App',
        short_name: 'App',
        theme_color: '#ffffff',
      },
    }),
  ],
});
```

## Development Server

### Proxy Configuration
```typescript
export default defineConfig({
  server: {
    port: 3000,
    host: true, // Expose to network

    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },

      // WebSocket proxy
      '/ws': {
        target: 'ws://localhost:8000',
        ws: true,
      },
    },

    // HTTPS for local development
    https: {
      key: fs.readFileSync('./certs/localhost-key.pem'),
      cert: fs.readFileSync('./certs/localhost.pem'),
    },
  },
});
```

### HMR Configuration
```typescript
export default defineConfig({
  server: {
    hmr: {
      overlay: true, // Show errors as overlay
      port: 3001,    // Separate port for HMR
    },

    watch: {
      // Ignore large directories
      ignored: ['**/node_modules/**', '**/dist/**'],
    },
  },
});
```

## Testing with Vitest

### Configuration
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'src/test/'],
    },
  },
});
```

### Test Setup
```typescript
// src/test/setup.ts
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

afterEach(() => {
  cleanup();
});

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});
```

## Library Mode

### Building a Library
```typescript
export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'MyLib',
      fileName: (format) => `my-lib.${format}.js`,
    },
    rollupOptions: {
      // Externalize peer dependencies
      external: ['react', 'react-dom'],
      output: {
        globals: {
          react: 'React',
          'react-dom': 'ReactDOM',
        },
      },
    },
  },
});
```

## Production Deployment

### Build Script
```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "build:analyze": "vite build --mode analyze",
    "test": "vitest",
    "test:coverage": "vitest run --coverage"
  }
}
```

### Docker
```dockerfile
# Build stage
FROM node:20-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### nginx.conf for SPA
```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;

    # Cache static assets
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # SPA fallback
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```
