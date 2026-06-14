---
name: typescript-best-practices
description: Guides writing, reviewing, and refactoring TypeScript strictness, inference, unknown handling, interfaces, enums, functions, variables, and naming. Use when working on TypeScript code, TSX, type definitions, or type-safe refactors.
---

# TypeScript Best Practices

Applies TypeScript conventions that keep code strict, readable, and easy to refactor.

Project conventions override these defaults when they are already established. When editing React TSX, also apply React best practices.

## Review Workflow

1. Check strictness first: avoid `any`, unsafe indexing, and loose optional properties.
2. Prefer inference for local implementation details.
3. Add explicit boundaries for exported functions, public APIs, and complex return types.
4. Choose `interface` for object shapes and `type` for unions, primitives, and intersections.
5. Replace enums with const objects unless project conventions require enums.
6. Check naming, unused variables, and file naming against local project conventions.

## Do Not Use For

- Plain JavaScript unless the task involves adding types, migrating to TypeScript, or editing JSDoc types.
- Generated TypeScript files unless the generator or schema is being changed.

## Strictness

- Follow TypeScript strict mode with `exactOptionalPropertyTypes` and `noUncheckedIndexedAccess`
- Avoid using the `any` type unless absolutely necessary; prefer `unknown` for unknown types
- Narrow `unknown` before use
- Do not use `var` declarations; use `let` or `const` instead

```typescript
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}
```

## Types vs Interfaces

- Use `interface` for object definitions, especially for React component props and object inheritance
- Use `type` for primitives, unions, and intersections

## Enums

Avoid using `enum` due to runtime cost and potential type safety issues. Prefer const objects with `as const`:

```typescript
// Bad
enum Status {
  Active = "active",
  Inactive = "inactive",
}

// Good
const Status = {
  Active: "active",
  Inactive: "inactive",
} as const;

type Status = (typeof Status)[keyof typeof Status];
```

## Type Declaration

- Prefer implicit return types when TypeScript can infer them for local implementation details
- Use explicit return types for exported functions, public APIs, and complex return values
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
- Prefer kebab-case for filenames unless the project already uses another convention
