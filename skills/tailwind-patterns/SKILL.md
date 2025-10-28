---
name: tailwind-patterns
description: Tailwind CSS utility-first patterns, responsive design, custom configurations, and modern CSS development
---

# Tailwind CSS Development Patterns

## When to Use This Skill

- Building responsive UIs with Tailwind CSS
- Creating custom component patterns
- Implementing design systems with Tailwind
- Optimizing Tailwind configurations
- Following utility-first CSS best practices

## Target Agents

- `tailwind-css-expert` - Primary user
- `frontend-developer` - UI styling
- `react-expert`, `vue-expert` - Component styling

## Core Patterns

### 1. Component Patterns

```jsx
// Button variants
const Button = ({ variant = 'primary', size = 'md', children, ...props }) => {
  const baseClasses = 'font-semibold rounded-lg transition-colors duration-200'

  const variants = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700',
    secondary: 'bg-gray-200 text-gray-800 hover:bg-gray-300',
    danger: 'bg-red-600 text-white hover:bg-red-700',
  }

  const sizes = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  }

  return (
    <button
      className={`${baseClasses} ${variants[variant]} ${sizes[size]}`}
      {...props}
    >
      {children}
    </button>
  )
}
```

### 2. Responsive Design

```html
<!-- Mobile-first approach -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
  <div class="p-4 bg-white rounded-lg">Content</div>
</div>

<!-- Container patterns -->
<div class="container mx-auto px-4 sm:px-6 lg:px-8">
  <div class="max-w-7xl mx-auto">
    <!-- Content -->
  </div>
</div>
```

### 3. Custom Configuration

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f0f9ff',
          500: '#0ea5e9',
          900: '#0c4a6e',
        },
      },
      spacing: {
        '128': '32rem',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

### 4. Dark Mode

```jsx
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
  <button class="bg-blue-500 hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-700">
    Click me
  </button>
</div>
```

## Best Practices

1. Use **@apply** sparingly
2. Follow **mobile-first** approach
3. Create **reusable components**
4. Use **custom properties** for theming
5. Optimize with **PurgeCSS** in production
