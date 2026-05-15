---
name: typescript-best-practices
description: TypeScript coding standards and patterns. Use when writing, reviewing, or refactoring TypeScript code to ensure type safety and consistent conventions.
---

# TypeScript Best Practices

## Strictness

- Follow TypeScript strict mode with `exactOptionalPropertyTypes` and `noUncheckedIndexedAccess`
- Avoid using the `any` type unless absolutely necessary; prefer `unknown` for unknown types
- Do not use `var` declarations; use `let` or `const` instead

## Types vs Interfaces

- Use `interface` for object definitions, especially for React component props and object inheritance
- Use `type` for primitives, unions, and intersections

## Enums

Avoid using `enum` due to runtime cost and potential type safety issues. Prefer const objects with `as const`:

```typescript
// Bad
enum Status {
  Active = 'active',
  Inactive = 'inactive'
}

// Good
const Status = {
  Active: 'active',
  Inactive: 'inactive'
} as const;

type Status = typeof Status[keyof typeof Status];
```

## Type Declaration

- Prefer implicit return types when TypeScript can infer them
- Prefer array brackets (`Type[]`) over the `Array<Type>` generic for array types
- Avoid explicit type annotations when TypeScript can infer the type (e.g., in `.map()` callbacks, variable assignments)

## Functions

- Use `function` instead of `const` for top-level functions
- Use `const` for callback functions inside React components

## Variables

- Prefix unused variables with an underscore (`_var`)
- Use descriptive names with auxiliary verbs (e.g., `isLoading`, `hasError`)

## Naming Conventions

- camelCase for variables and functions
- PascalCase for components and types
- kebab-case for filenames
