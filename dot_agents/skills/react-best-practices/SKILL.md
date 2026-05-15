---
name: react-best-practices
description: React development guidelines for component architecture, state management, and hooks patterns. Use when writing, reviewing, or refactoring React code to ensure consistent patterns and optimal performance.
---

# React Best Practices

## Core Philosophy

UIs are thin wrappers over data. Avoid local state unless it's independent of business logic and cannot be derived from props or other state.

Prefer derived values over storing computed state:

- Avoid: Effect-driven logic

  ```tsx
  useEffect(() => {
    if (user && user.preferences) {
      setTheme(user.preferences.theme);
    }
  }, [user]);
  ```

- Prefer: Derived values

  ```tsx
  const theme = user?.preferences?.theme ?? "default";
  ```

## State Management

- For complex state, prefer a single state object with reducers (like Zustand) over multiple `useState` calls
- `useState` should only be used for state that is truly reactive and cannot be derived

## Component Architecture

- Favor named exports for components
- Create new component abstractions to avoid deeply nested conditional logic in JSX
- Use ternaries only for small, easily readable logic

### Avoid nested conditionals in JSX

```tsx
// Bad
return (
  <div>
    {user ?
      user.isAdmin ?
        <AdminPanel />
      : <BasicDashboard />
    : <LoginForm />}
  </div>
);

// Good
function UserDashboard({ user }) {
  if (!user) return <LoginForm />;
  if (user.isAdmin) return <AdminPanel />;
  return <BasicDashboard />;
}
```

## Component Props

- Do not inline prop types in the component declaration
- Declare the props `interface` immediately before the component function
- Always destructure props, except when spreading into another component
- Use `onCallback` as the naming convention for callback props instead of `handleCallback`
- When spreading remaining props, use `...props`

```tsx
interface MyComponentProps {
  foo: string;
  bar: number;
}

function MyComponent({ foo, bar }: MyComponentProps) {
  // use foo and bar directly
}
```

## Hooks and Side Effects

- Avoid putting dependent logic in `useEffect`. Prefer derived state and event handlers
- When `useEffect` is necessary, be explicit about its dependencies and include cleanup functions

## React Query Integration

- Prefer React Query for async operations and periodic data fetching over manual intervals
- Use React Query's built-in defaults, avoid overriding `retry` and `retryDelay` unless specifically required
- Let React Query handle network awareness, focus refetching, and error recovery automatically
