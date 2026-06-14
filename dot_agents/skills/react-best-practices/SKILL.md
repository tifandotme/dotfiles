---
name: react-best-practices
description: Guides writing, reviewing, and refactoring React component architecture, props, state, hooks, effects, and React Query usage. Use when working on React components, hooks, JSX, TSX, or async UI code.
---

# React Best Practices

Applies React conventions that keep components derived, readable, and easy to test.

Project conventions override these defaults when they are already established. When editing TSX, also apply TypeScript best practices.

## Review Workflow

1. Check whether state can be derived from props, query data, or existing state.
2. Move avoidable effect logic into derived values or event handlers.
3. Simplify JSX by extracting components or using early returns.
4. Check prop interfaces, destructuring, callback names, and prop spreading.
5. Prefer React Query for async server state and repeated fetching.

## Do Not Use For

- Non-React frontend work unless React code is involved.
- CSS-only or visual-design-only changes unless component structure is part of the task.

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

- For complex state, prefer a reducer or external store such as Zustand over many loosely coupled `useState` calls
- `useState` should only be used for state that is truly reactive and cannot be derived

## Component Architecture

- Favor named exports for components
- Create new component abstractions to avoid deeply nested conditional logic in JSX
- Use ternaries only for small, easily readable logic

### Avoid nested conditionals in JSX

```tsx
// Bad
return <div>{user ? user.isAdmin ? <AdminPanel /> : <BasicDashboard /> : <LoginForm />}</div>;

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
- Avoid effects that only react to user actions; put that logic in the event handler instead
- When `useEffect` is necessary, be explicit about its dependencies and include cleanup functions

## React Query Integration

- Prefer React Query for async operations and periodic data fetching over manual intervals
- Use React Query's built-in defaults, avoid overriding `retry` and `retryDelay` unless specifically required
- Let React Query handle network awareness, focus refetching, and error recovery automatically
