# Personal Coding Conventions

## Code Comments

Be succinct with code comments. Only add them if truly needed. Do not include conversation-only context in comments that the code itself cannot describe. Do not re-encode logic that the code already describes in the comment itself. For example, if a variable is defined like `const isInvalid = conditionA || conditionB`, a comment like `// Only invalid if conditionA or conditionB is true` is not needed.

## TypeScript Errors

When resolving TypeScript errors, never use `as` typecasting (e.g. `as any`, `as unknown`) to resolve type errors. A `@ts-expect-error` directive with a helpful message explaining the error is a last-ditch approach that can be used, but attempts should be made to resolve the type error properly before falling back to this.

## Prefer arrow functions

Use arrow functions over the `function` keyword wherever possible — for components, handlers, callbacks, and module helpers. They're more concise and keep `this` lexical.

```tsx
// ❌ BAD
function ModList(props: ModListProps) { /* ... */ }
function handleClick() { /* ... */ }

// ✅ GOOD
const ModList = (props: ModListProps) => { /* ... */ };
const handleClick = () => { /* ... */ };
```

## Work Conventions

@~/.claude/work-conventions.md
