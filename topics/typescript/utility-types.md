# TypeScript Utility Types

**Abstraction level**: language feature  
**Category**: type system / type transformation

---

## Related Topics

- **Depends on this**: advanced generic patterns, conditional types, mapped types
- **Depends on**: TypeScript generics, `keyof`, `typeof`, mapped types, conditional types
- **Works alongside**: type guards, discriminated unions, function overloads
- **Contrast with**: manually written mapped types (utility types are just named versions of these)
- **Temporal neighbors**: learn after TypeScript basics and generics; learn before writing custom utility types

---

## What is it

Utility types are built-in generic types that TypeScript ships with. Each one takes an existing type and transforms it into a new type — for example, making all properties optional, or picking a subset of keys.

They are just names for common type-level transformations. Internally they use mapped types and conditional types, but you do not need to understand those internals to use utility types effectively.

- **Data**: the "data" here is the type itself — the shape of an object, the keys, the values
- **Where it lives**: compile-time only; no runtime impact
- **Who uses it**: the type checker, to validate and infer types across your codebase
- **How it changes**: you pass a base type in, and get a derived type back

---

## What problem does it solve

When you have an existing type, you often need variations of it. Without utility types, you copy-paste and manually rewrite types, which leads to duplication and drift.

**Scenario: a User object**

```ts
type User = {
  id: number;
  name: string;
  email: string;
};
```

You need:
- A form where all fields are optional (partial update)
- A read-only version for a cache
- A type with only `id` and `name` (public profile)

Without utility types:
```ts
type PartialUser = { id?: number; name?: string; email?: string };
type ReadonlyUser = { readonly id: number; readonly name: string; readonly email: string };
type PublicUser = { id: number; name: string };
```

Problems:
- All three drift from `User` if `User` changes
- You have to update three types every time you add a field
- Duplication hides the relationship between types

---

## How does it solve it

**Principle 1 — Derive, don't duplicate**  
Express a new type as a transformation of an existing one. If the base type changes, all derived types update automatically.

**Principle 2 — Encode intent in the type**  
`Readonly<User>` signals immutability. `Partial<User>` signals optionality. The name carries meaning about how the type should be used.

**Principle 3 — Compose transformations**  
Utility types can be nested: `Readonly<Partial<User>>` produces a type where all properties are both optional and read-only.

**Principle 4 — Separate the schema from the use case**  
The base type (`User`) is the source of truth. Utility types produce task-specific views without polluting the base.

---

## What if we didn't have it

**Manual copy-paste approach**

```ts
type PartialUser = {
  id?: number;
  name?: string;
  // forgot email — now it's missing
};
```
Breaks when the base type evolves. Silent mismatch between `User` and `PartialUser`.

**Overly permissive typing**

```ts
function updateUser(data: Record<string, any>) { ... }
```
Loses all type safety. Accepts garbage input. No autocomplete.

**Reusing the full type where a partial is needed**

```ts
function updateUser(data: User) { ... }
// Caller must pass all fields even for a partial update
```
Forces the caller to provide fields they do not have — or worse, to fabricate them.

---

## Examples

### Example 1 — `Partial<T>`: make all fields optional

```ts
type User = { id: number; name: string; email: string };

type UserUpdate = Partial<User>;
// { id?: number; name?: string; email?: string }

function updateUser(id: number, changes: UserUpdate) { ... }
updateUser(1, { name: "Alice" }); // valid — only sending what changed
```

---

### Example 2 — `Required<T>`: reverse of Partial

```ts
type Config = { timeout?: number; retries?: number };

type StrictConfig = Required<Config>;
// { timeout: number; retries: number }
```

Useful after setting defaults — once you've filled in every field, the type should reflect that nothing is missing.

---

### Example 3 — `Readonly<T>`: prevent mutation

```ts
type Point = { x: number; y: number };

const origin: Readonly<Point> = { x: 0, y: 0 };
origin.x = 1; // Error: Cannot assign to 'x' because it is a read-only property
```

Use for data that should not be mutated after creation — config objects, frozen state, cached values.

---

### Example 4 — `Pick<T, K>` and `Omit<T, K>`: select or exclude fields

```ts
type User = { id: number; name: string; email: string; passwordHash: string };

type PublicUser = Pick<User, "id" | "name">;
// { id: number; name: string }

type SafeUser = Omit<User, "passwordHash">;
// { id: number; name: string; email: string }
```

`Pick` says "only these keys". `Omit` says "everything except these keys". Use `Omit` when the exclusion list is shorter; use `Pick` when the inclusion list is shorter.

---

### Example 5 — `Record<K, V>`: typed dictionary

```ts
type Role = "admin" | "editor" | "viewer";
type Permissions = Record<Role, boolean>;

const perms: Permissions = {
  admin: true,
  editor: true,
  viewer: false,
};
```

`Record<K, V>` enforces that every key in `K` exists, and every value is of type `V`. Better than `{ [key: string]: boolean }` because the keys are constrained.

---

### Example 6 — `ReturnType<T>` and `Parameters<T>`: extract from function types

```ts
function fetchUser(id: number): { id: number; name: string } {
  return { id, name: "Alice" };
}

type FetchResult = ReturnType<typeof fetchUser>;
// { id: number; name: string }

type FetchArgs = Parameters<typeof fetchUser>;
// [id: number]
```

Useful when you want to reuse a function's inferred return type or parameter list without defining a named type separately.

---

### Example 7 — `NonNullable<T>`: strip null and undefined

```ts
type MaybeString = string | null | undefined;

type DefinitelyString = NonNullable<MaybeString>;
// string
```

Useful after validation — once you have confirmed a value is not null, narrow its type to reflect that.

---

### Example 8 — composing utility types

```ts
type Config = {
  host: string;
  port: number;
  debug?: boolean;
};

type FrozenRequiredConfig = Readonly<Required<Config>>;
// { readonly host: string; readonly port: number; readonly debug: boolean }
```

After resolving defaults and freezing the config, the type reflects both constraints.

---

## Quickfire (Interview Q&A)

**Q: What is a utility type?**  
A built-in generic type in TypeScript that transforms an existing type into a new one — for example, making all properties optional or read-only.

**Q: What does `Partial<T>` do?**  
Makes all properties of `T` optional. Used for partial update payloads where not every field needs to be provided.

**Q: What is the difference between `Pick` and `Omit`?**  
`Pick` creates a type with only the specified keys; `Omit` creates a type with all keys except the specified ones. They are inverses of each other.

**Q: What does `Record<K, V>` give you over a plain index signature?**  
`Record<K, V>` constrains the keys to a specific union type, so the compiler enforces that every key in the union is present. A plain index signature allows any string key.

**Q: Do utility types have any runtime cost?**  
No. They exist only at compile time. They produce zero JavaScript output.

**Q: When would you use `ReturnType<T>`?**  
When you want to type something as "whatever this function returns" without duplicating the return type as a named type. Keeps types in sync automatically.

**Q: What is `NonNullable<T>` used for?**  
To strip `null` and `undefined` from a union type, typically after a null check has been performed and you want the type to reflect that.

**Q: What does `Required<T>` do and when is it useful?**  
It makes all properties of `T` required (removes optionality). Useful after applying defaults — once all fields have been filled in, the type should stop treating them as optional.

**Q: Can utility types be composed?**  
Yes. `Readonly<Partial<T>>` produces a type where all fields are both optional and immutable. Composition is a key part of their power.

**Q: Where do utility types come from?**  
They are defined in TypeScript's standard library (`lib.es5.d.ts`). They are implemented using mapped types and conditional types internally.

---

## Key Takeaways

- Utility types transform existing types into new ones — derive, don't duplicate
- They have zero runtime cost; they exist only during type checking
- `Partial`, `Required`, and `Readonly` modify property modifiers across all keys
- `Pick` and `Omit` select a subset of keys from a type
- `Record<K, V>` enforces a typed dictionary with constrained keys
- `ReturnType` and `Parameters` extract type information from function signatures
- Utility types can be composed to express layered constraints
- The base type remains the single source of truth; utility types create views of it

---

## Vocabulary

### Nouns (concepts)

**Utility type** — a built-in generic type that transforms another type. TypeScript ships ~20 of them in its standard library.

**Mapped type** — a type that is constructed by iterating over the keys of another type. Utility types like `Partial` and `Readonly` are implemented as mapped types.

**Conditional type** — a type that resolves to one of two types based on a condition (`T extends U ? X : Y`). `NonNullable` is implemented using a conditional type.

**Type transformation** — the process of producing a new type from an existing type by modifying its structure, keys, or property modifiers.

**Generic type** — a type that accepts one or more type parameters. All utility types are generic: `Partial<T>` takes `T` as input.

**Type parameter** — the placeholder in a generic type definition, e.g. `T` in `Partial<T>`.

**Property modifier** — a flag on an object type's property that controls mutability (`readonly`) or presence (`?` for optional).

**Index signature** — a type notation that allows any key of a given type: `{ [key: string]: number }`. Less precise than `Record`.

**Union type** — a type that can be one of several types, e.g. `string | null`. Utility types like `NonNullable` operate on unions.

**Source of truth** — the single authoritative definition from which other types are derived. The base type is the source of truth; utility types create views of it.

### Verbs (actions)

**Derive** — to produce a new type from an existing one using a transformation, rather than writing it from scratch.

**Compose** — to nest utility types to apply multiple transformations at once, e.g. `Readonly<Partial<T>>`.

**Pick** — to select a subset of keys from a type and produce a new type containing only those keys.

**Omit** — to exclude specific keys from a type and produce a new type with the remaining keys.

**Narrow** — to refine a type to a more specific subtype, often used with `NonNullable` after a null check.

**Infer** — for TypeScript to deduce a type automatically. `ReturnType` uses `infer` internally to extract the return type.

### Adjectives (properties)

**Optional** — a property that may or may not be present. Marked with `?`. `Partial<T>` makes all properties optional.

**Required** — a property that must be present. `Required<T>` removes the `?` from all properties.

**Readonly** — a property that cannot be reassigned after initialization. `Readonly<T>` applies this to all properties.

**Nullable** — a type that includes `null` or `undefined` in its union. `NonNullable<T>` removes these.

**Derived** — a type that was produced from another type rather than defined independently.
