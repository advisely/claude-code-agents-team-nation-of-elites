---
name: nextjs-patterns
description: Next.js 14+ App Router patterns, Server Components, Server Actions, and full-stack React development with TypeScript
---

# Next.js Development Patterns

## When to Use This Skill

- Building Next.js applications with App Router
- Implementing Server Components and Server Actions
- Creating full-stack React applications
- SEO-optimized web applications
- Following Next.js 14+ best practices

## Target Agents

- `nextjs-expert` - Primary user for Next.js development
- `react-typescript-expert` - TypeScript React patterns
- `frontend-developer` - Full-stack web development

## Core Patterns

### 1. App Router Structure

```
app/
├── (marketing)/
│   ├── page.tsx           # /
│   └── about/
│       └── page.tsx       # /about
├── (dashboard)/
│   ├── layout.tsx
│   └── dashboard/
│       └── page.tsx       # /dashboard
├── api/
│   └── users/
│       └── route.ts       # API route
├── layout.tsx             # Root layout
└── page.tsx              # Home page
```

### 2. Server Components (Default)

```typescript
// app/posts/page.tsx
async function getPosts() {
  const res = await fetch('https://api.example.com/posts', {
    next: { revalidate: 3600 } // ISR: revalidate every hour
  })
  return res.json()
}

export default async function PostsPage() {
  const posts = await getPosts()

  return (
    <div>
      <h1>Posts</h1>
      {posts.map((post) => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
        </article>
      ))}
    </div>
  )
}
```

### 3. Client Components

```typescript
'use client'

import { useState } from 'react'

export default function Counter() {
  const [count, setCount] = useState(0)

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  )
}
```

### 4. Server Actions

```typescript
// app/actions.ts
'use server'

import { revalidatePath } from 'next/cache'

export async function createPost(formData: FormData) {
  const title = formData.get('title')
  const content = formData.get('content')

  await db.post.create({
    data: { title, content }
  })

  revalidatePath('/posts')
  return { success: true }
}

// app/posts/new/page.tsx
import { createPost } from '@/app/actions'

export default function NewPost() {
  return (
    <form action={createPost}>
      <input name="title" required />
      <textarea name="content" required />
      <button type="submit">Create Post</button>
    </form>
  )
}
```

### 5. Dynamic Routes & Params

```typescript
// app/posts/[id]/page.tsx
interface PageProps {
  params: { id: string }
  searchParams: { [key: string]: string | string[] | undefined }
}

export async function generateMetadata({ params }: PageProps) {
  const post = await getPost(params.id)
  return { title: post.title }
}

export default async function PostPage({ params }: PageProps) {
  const post = await getPost(params.id)
  return <article>{/* post content */}</article>
}

export async function generateStaticParams() {
  const posts = await getPosts()
  return posts.map((post) => ({ id: post.id }))
}
```

### 6. API Routes

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const users = await db.user.findMany()
  return NextResponse.json(users)
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  const user = await db.user.create({ data: body })
  return NextResponse.json(user, { status: 201 })
}
```

### 7. Middleware

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')

  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*']
}
```

### 8. Data Fetching Patterns

```typescript
// Parallel Data Fetching
async function getData() {
  const [posts, users] = await Promise.all([
    fetch('https://api.example.com/posts'),
    fetch('https://api.example.com/users')
  ])

  return {
    posts: await posts.json(),
    users: await users.json()
  }
}

// Sequential (when dependent)
async function getPostAndComments(id: string) {
  const post = await getPost(id)
  const comments = await getComments(post.id)
  return { post, comments }
}
```

### 9. Streaming & Suspense

```typescript
import { Suspense } from 'react'

export default function Page() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<LoadingSkeleton />}>
        <Posts />
      </Suspense>
      <Suspense fallback={<LoadingSkeleton />}>
        <Analytics />
      </Suspense>
    </div>
  )
}
```

### 10. Image Optimization

```typescript
import Image from 'next/image'

export default function Profile() {
  return (
    <Image
      src="/profile.jpg"
      alt="Profile"
      width={500}
      height={500}
      priority
      quality={90}
    />
  )
}
```

## Best Practices

1. Use **Server Components** by default
2. Add `'use client'` only when needed (interactivity)
3. Leverage **Server Actions** for mutations
4. Implement proper **caching strategies**
5. Use **Suspense** for streaming
6. Optimize images with `next/image`
7. Implement proper **SEO metadata**
8. Use **TypeScript** for type safety
9. Follow App Router conventions
10. Implement **error boundaries**

## Additional Resources

- [caching.md](caching.md) - Caching strategies
- [authentication.md](authentication.md) - Auth patterns
- [deployment.md](deployment.md) - Deployment best practices
