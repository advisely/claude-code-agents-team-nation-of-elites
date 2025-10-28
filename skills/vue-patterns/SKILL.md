---
name: vue-patterns
description: Vue.js 3 Composition API patterns, state management with Pinia, and modern component architecture for reactive web applications
---

# Vue.js Development Patterns

## When to Use This Skill

- Building Vue.js 3 applications with Composition API
- Implementing state management with Pinia
- Creating reusable Vue components
- Building reactive user interfaces
- Following Vue.js best practices

## Target Agents

- `vue-expert` - Primary user for Vue development
- `frontend-developer` - General frontend development with Vue
- `nextjs-expert` - When using Nuxt.js (Vue meta-framework)

## Core Patterns

### 1. Composition API

**Script Setup Syntax:**

```vue
<script setup>
import { ref, computed, watch, onMounted } from 'vue'

// Reactive state
const count = ref(0)
const doubled = computed(() => count.value * 2)

// Methods
const increment = () => {
  count.value++
}

// Watchers
watch(count, (newValue, oldValue) => {
  console.log(`Count changed from ${oldValue} to ${newValue}`)
})

// Lifecycle hooks
onMounted(() => {
  console.log('Component mounted')
})
</script>

<template>
  <div>
    <p>Count: {{ count }}</p>
    <p>Doubled: {{ doubled }}</p>
    <button @click="increment">Increment</button>
  </div>
</template>
```

### 2. Composables (Custom Hooks)

**Reusable Composition Functions:**

```javascript
// composables/useFetch.js
import { ref, watch } from 'vue'

export function useFetch(url) {
  const data = ref(null)
  const error = ref(null)
  const loading = ref(false)

  const fetchData = async () => {
    loading.value = true
    error.value = null

    try {
      const response = await fetch(url.value)
      data.value = await response.json()
    } catch (err) {
      error.value = err
    } finally {
      loading.value = false
    }
  }

  watch(url, fetchData, { immediate: true })

  return { data, error, loading, refetch: fetchData }
}

// Usage in component
<script setup>
import { ref } from 'vue'
import { useFetch } from '@/composables/useFetch'

const userId = ref(1)
const url = computed(() => `/api/users/${userId.value}`)
const { data: user, loading, error, refetch } = useFetch(url)
</script>
```

**Form Handling Composable:**

```javascript
// composables/useForm.js
import { reactive, computed } from 'vue'

export function useForm(initialValues, onSubmit) {
  const values = reactive({ ...initialValues })
  const errors = reactive({})
  const touched = reactive({})
  const submitting = ref(false)

  const handleChange = (field, value) => {
    values[field] = value
    touched[field] = true
    delete errors[field]
  }

  const validateField = (field, rules) => {
    if (!touched[field]) return true

    for (const rule of rules) {
      const error = rule(values[field])
      if (error) {
        errors[field] = error
        return false
      }
    }
    return true
  }

  const handleSubmit = async () => {
    submitting.value = true

    try {
      await onSubmit(values)
    } catch (err) {
      Object.assign(errors, err.errors || {})
    } finally {
      submitting.value = false
    }
  }

  const isValid = computed(() => Object.keys(errors).length === 0)

  return {
    values,
    errors,
    touched,
    submitting,
    isValid,
    handleChange,
    validateField,
    handleSubmit,
  }
}
```

### 3. State Management with Pinia

**Store Definition:**

```javascript
// stores/user.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useUserStore = defineStore('user', () => {
  // State
  const user = ref(null)
  const token = ref(localStorage.getItem('token'))

  // Getters
  const isAuthenticated = computed(() => !!user.value)
  const fullName = computed(() => {
    if (!user.value) return ''
    return `${user.value.firstName} ${user.value.lastName}`
  })

  // Actions
  async function login(credentials) {
    const response = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
    })

    const data = await response.json()

    if (response.ok) {
      user.value = data.user
      token.value = data.token
      localStorage.setItem('token', data.token)
    } else {
      throw new Error(data.message)
    }
  }

  function logout() {
    user.value = null
    token.value = null
    localStorage.removeItem('token')
  }

  return { user, token, isAuthenticated, fullName, login, logout }
})

// Usage in component
<script setup>
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()

const handleLogin = async () => {
  try {
    await userStore.login({ email, password })
    router.push('/dashboard')
  } catch (error) {
    console.error('Login failed:', error)
  }
}
</script>
```

### 4. Component Patterns

**Props and Emits:**

```vue
<script setup>
defineProps({
  modelValue: {
    type: String,
    required: true
  },
  placeholder: {
    type: String,
    default: 'Enter text...'
  },
  disabled: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue', 'submit'])

const updateValue = (event) => {
  emit('update:modelValue', event.target.value)
}

const handleSubmit = () => {
  emit('submit')
}
</script>

<template>
  <div>
    <input
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      @input="updateValue"
      @keyup.enter="handleSubmit"
    />
  </div>
</template>
```

**Slots and Provide/Inject:**

```vue
<!-- ParentComponent.vue -->
<script setup>
import { provide, ref } from 'vue'

const theme = ref('dark')
provide('theme', theme)
</script>

<template>
  <div :class="theme">
    <header>
      <slot name="header" :theme="theme"></slot>
    </header>

    <main>
      <slot></slot>
    </main>

    <footer>
      <slot name="footer"></slot>
    </footer>
  </div>
</template>

<!-- ChildComponent.vue -->
<script setup>
import { inject } from 'vue'

const theme = inject('theme')
</script>
```

### 5. Vue Router Patterns

**Route Configuration:**

```javascript
// router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/stores/user'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue')
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('@/views/Dashboard.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/users/:id',
    name: 'UserProfile',
    component: () => import('@/views/UserProfile.vue'),
    props: true
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation guards
router.beforeEach((to, from, next) => {
  const userStore = useUserStore()

  if (to.meta.requiresAuth && !userStore.isAuthenticated) {
    next({ name: 'Login', query: { redirect: to.fullPath } })
  } else {
    next()
  }
})

export default router
```

### 6. Async Components & Suspense

**Code Splitting:**

```vue
<script setup>
import { defineAsyncComponent } from 'vue'

const AsyncComponent = defineAsyncComponent(() =>
  import('./HeavyComponent.vue')
)
</script>

<template>
  <Suspense>
    <template #default>
      <AsyncComponent />
    </template>
    <template #fallback>
      <LoadingSpinner />
    </template>
  </Suspense>
</template>
```

### 7. Teleport for Modals

**Modal Component:**

```vue
<!-- Modal.vue -->
<script setup>
import { ref } from 'vue'

const props = defineProps({
  show: Boolean
})

const emit = defineEmits(['close'])
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="show" class="modal-overlay" @click="emit('close')">
        <div class="modal-content" @click.stop>
          <button class="close-btn" @click="emit('close')">×</button>
          <slot></slot>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
</style>
```

### 8. Performance Optimization

**Computed Caching and v-memo:**

```vue
<script setup>
import { ref, computed, shallowRef } from 'vue'

// Use shallowRef for large data structures
const largeList = shallowRef([/* thousands of items */])

// Computed values are cached
const filteredList = computed(() => {
  return largeList.value.filter(item => item.active)
})
</script>

<template>
  <!-- v-memo caches rendering based on dependencies -->
  <div
    v-for="item in filteredList"
    :key="item.id"
    v-memo="[item.name, item.status]"
  >
    {{ item.name }} - {{ item.status }}
  </div>
</template>
```

### 9. Testing with Vitest

**Component Testing:**

```javascript
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Counter from '@/components/Counter.vue'

describe('Counter.vue', () => {
  it('increments count when button clicked', async () => {
    const wrapper = mount(Counter)

    expect(wrapper.text()).toContain('Count: 0')

    await wrapper.find('button').trigger('click')

    expect(wrapper.text()).toContain('Count: 1')
  })

  it('emits update event', async () => {
    const wrapper = mount(Counter)

    await wrapper.find('button').trigger('click')

    expect(wrapper.emitted('update')).toBeTruthy()
    expect(wrapper.emitted('update')[0]).toEqual([1])
  })
})
```

### 10. TypeScript Integration

**Typed Components:**

```vue
<script setup lang="ts">
interface User {
  id: number
  name: string
  email: string
}

interface Props {
  user: User
  editable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  editable: false
})

const emit = defineEmits<{
  (e: 'update', user: User): void
  (e: 'delete', id: number): void
}>()

const handleUpdate = (updates: Partial<User>) => {
  emit('update', { ...props.user, ...updates })
}
</script>
```

## Project Structure

**Recommended Vue 3 Project Structure:**

```
src/
├── assets/
├── components/
│   ├── common/
│   └── features/
├── composables/
├── layouts/
├── router/
├── stores/
├── views/
├── utils/
├── App.vue
└── main.js
```

## Best Practices

1. **Use Composition API** with `<script setup>` syntax
2. **Create Composables** for reusable logic
3. **Use Pinia** for state management
4. **Implement Proper TypeScript** types
5. **Leverage v-memo** for performance
6. **Use Teleport** for modals and overlays
7. **Implement Suspense** for async components
8. **Write Tests** with Vitest
9. **Follow Vue Style Guide** conventions
10. **Optimize with shallowRef/shallowReactive** for large data

## Additional Resources

For more advanced patterns, see:
- [nuxt-patterns.md](nuxt-patterns.md) - Nuxt.js specific patterns
- [testing.md](testing.md) - Comprehensive testing strategies
- [performance.md](performance.md) - Performance optimization techniques
