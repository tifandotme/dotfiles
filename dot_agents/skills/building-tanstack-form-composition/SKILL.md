---
name: building-tanstack-form-composition
description: Builds portable TanStack Form composition for React apps. Use when adding, migrating, or reviewing composed form hooks, reusable field components, form options, validation, submit buttons, or form sections.
disable-model-invocation: true
---

# Building TanStack Form Composition

Build portable React forms with TanStack Form's composition API: `createFormHookContexts`, `createFormHook`, `formOptions`, `useAppForm`, `withForm`, `AppField`, and `AppForm`.

## Reference docs

Read the official guide before changing form infrastructure:

```text
https://raw.githubusercontent.com/tanstack/form/main/docs/framework/react/guides/form-composition.md
```

It covers the APIs this skill uses, including `createFormHookContexts`, pre-bound field components, pre-bound form components, `withForm`, `withFieldGroup`, context fallback, extension, and lazy-loaded field components.

If the form reads, submits, or invalidates server data and the host project has a TanStack Query skill or guide, load it before wiring queries or mutations.

## Inspect the host project

Before adding files, check for existing conventions:

```bash
find . -path '*form*' -o -path '*field*'
grep -R "createFormHook\|useAppForm\|withForm\|formOptions\|AppField" -n src . 2>/dev/null
```

If the project already has a form stack, extend it instead of creating a second one.

## Target shape

Use app-local paths that match the host project. A common React layout is:

```text
src/hooks/form-context.ts
src/hooks/form.tsx
src/components/form-composition/fields.tsx
src/components/form-composition/forms.tsx
src/lib/form-validators.ts
src/features/<feature>/<thing>-form-opts.ts
src/features/<feature>/components/<thing>-form-fields.tsx
```

Add dependencies only when missing:

```bash
bun add @tanstack/react-form zod
```

Use the host project's package manager if it is not Bun.

## Pattern

1. `form-context.ts` exports `fieldContext`, `formContext`, `useFieldContext`, and `useFormContext` from `createFormHookContexts()`.
2. `fields.tsx` defines reusable field components that call `useFieldContext<T>()`, bind value/blur/change, and render the host UI's field, label, control, description, and error components.
3. `forms.tsx` defines form-level components such as `SubmitButton` using `useFormContext()` and `form.Subscribe`.
4. `form.tsx` creates and exports `useAppForm` and `withForm` using `createFormHook({ fieldComponents, formComponents, fieldContext, formContext })`.
5. `<thing>-form-opts.ts` owns `formOptions({ formId, defaultValues, validationLogic, validators })` and the schema type.
6. `<thing>-form-fields.tsx` uses `withForm({ ...formOpts, render })` and renders fields through `form.AppField`.
7. The route, dialog, or page calls `useAppForm({ ...formOpts, onSubmit })`, wraps the JSX in a native `<form>`, calls `form.handleSubmit()`, and passes `form` into the field component.

## Server data

Keep TanStack Form responsible for form state and keep the host data layer responsible for server state. Preserve the project's existing query keys, loading states, invalidation, optimistic updates, and navigation behavior around submit.

## Rules

- Keep submitted form values inside TanStack Form. Do not mirror field values in `useState`.
- Keep unrelated UI state outside the form when it is not submitted.
- Use `formOptions` once per form and spread the same options into both `withForm` and `useAppForm`.
- Prefer schema validation plus a small adapter such as `createZodValidator`.
- Keep hand-written submit guards only for constraints that depend on external async state.
- Use `form.Subscribe` for conditional fields, derived UI, and submit-state UI.
- Use `form.AppField`, not raw `form.Field`, so field components stay pre-bound and reusable.
- Wrap form-level components in `form.AppForm`; it provides the context required by registered form components.
- Use `withForm` to split large forms into typed sections. Prefer `render: function Render(...) { ... }` if hooks are needed inside the section.
- Use `withFieldGroup` only for reusable groups of closely related fields.
- Use typed form context only as a last resort when the child component cannot receive a `form` prop.
- Keep shared field components generic. Feature language belongs in form field composition files.
- Use the host project's UI primitives. Do not copy imports from another repository.

## Migration checklist

- [ ] Existing submitted values moved from `useState` to `defaultValues` and TanStack Form fields.
- [ ] Existing validation moved into a schema or `validators`.
- [ ] Mutations read from `onSubmit({ value })`, not captured local state.
- [ ] Submit button uses `form.SubmitButton` or equivalent subscribed state.
- [ ] Server errors still surface through toast, inline alerts, or the host project's error UI.
- [ ] Query invalidation and navigation still match the previous behavior.
- [ ] Relevant typecheck and lint commands pass.

## Example skeleton

```tsx
const form = useAppForm({
  ...createProjectFormOpts,
  onSubmit: async ({ value }) => {
    await createMutation.mutateAsync(value);
  },
});

return (
  <form
    onSubmit={(event) => {
      event.preventDefault();
      event.stopPropagation();
      form.handleSubmit();
    }}
  >
    <CreateProjectFormFields form={form} />
    <form.AppForm>
      <form.SubmitButton>Create project</form.SubmitButton>
    </form.AppForm>
  </form>
);
```
