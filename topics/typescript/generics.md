# Generics in TypeScript

**Abstraction level**: language feature
**Category**: type system, static analysis

---

## Related Topics

- **Depends on this**: utility types (`Partial`, `Record`, `ReturnType`), mapped types, conditional types
- **Works alongside**: interfaces, type aliases, union types, function overloads
- **Contrast with**: `any`, `unknown`, function overloads (alternative ways to handle multiple types)
- **Temporal neighbors**: learn after TypeScript basics and interfaces; learn before advanced mapped/conditional types

---

## What is it

Generics let you write code that works with multiple types while still enforcing type safety. Instead of hardcoding a specific type, you define a placeholder — called a type parameter — and let the caller decide what type to use at the point of invocation.

- **Data**: any value whose type is not fixed at write time but must remain consistent within a usage
- **Where it lives**: purely in the type system — no runtime cost, erased during compilation
- **Who reads/writes it**: the developer writing reusable functions, classes, or interfaces; TypeScript's compiler resolves the actual type
- **How it changes**: the type parameter is fixed per call site — each call gets its own concrete type substituted in

---

## What problem does it solve

Without generics, you face a choice between two bad options:

**Option 1 — be specific**: write `identity(x: number): number`. Works, but only for `number`. You must duplicate the function for every type.

**Option 2 — use `any`**: write `identity(x: any): any`. Works for all types, but you lose type information. The return type is `any`, so TypeScript can no longer catch errors downstream.

As complexity grows, these problems compound:

- A `wrap(value)` function that boxes a value loses the type of what it wrapped
- A `getFirst(arr)` function returning `any` means you lose autocomplete and type checking on the result
- Duplication of logic for `string`, `number`, `object` variants causes maintenance problems
- Inconsistencies creep in when copies diverge

---

## How does it solve it

### Type Parameters as Placeholders

You declare a generic with angle brackets: `<T>`. `T` is just a name — by convention single uppercase letters or descriptive names like `TItem`, `TKey`.

```ts
function identity<T>(value: T): T {
  return value;
}
```

TypeScript infers `T` from what you pass in. When you call `identity(42)`, `T` becomes `number`. The return type is then `number`, not `any`.

### Preserving the Relationship Between Input and Output

The power is in expressing relationships. If a function takes `T[]` and returns `T`, TypeScript knows the array element type and the return type are the same thing.

```ts
function first<T>(arr: T[]): T {
  return arr[0];
}

const n = first([1, 2, 3]);  // n is number
const s = first(["a", "b"]); // s is string
```

### Constraints — Narrowing What T Can Be

Sometimes you need the type to have certain properties. Use `extends` to constrain what `T` is allowed to be:

```ts
function getLength<T extends { length: number }>(value: T): number {
  return value.length;
}
```

Now `T` can be a string, array, or any object with a `length` — but not a plain number.

### Multiple Type Parameters

You can declare multiple parameters to express relationships between several types:

```ts
function pair<A, B>(a: A, b: B): [A, B] {
  return [a, b];
}
```

### Generic Interfaces and Types

Generics are not limited to functions. You can parameterize interfaces and type aliases:

```ts
interface Box<T> {
  value: T;
  label: string;
}

const numBox: Box<number> = { value: 42, label: "count" };
```

### Default Type Parameters

You can provide a default if the caller does not specify:

```ts
interface Response<T = unknown> {
  data: T;
  status: number;
}
```

---

## What if we didn't have it (Alternatives)

### Approach 1 — Function per type

```ts
function wrapNumber(x: number): { value: number } { return { value: x }; }
function wrapString(x: string): { value: string } { return { value: x }; }
```

Breaks at scale: N types = N copies. Any logic change must be applied everywhere.

### Approach 2 — Use `any`

```ts
function wrap(x: any): { value: any } { return { value: x }; }

const result = wrap(42);
result.value.toFixed(2); // no error — but what if wrap("hello") was passed?
```

Breaks type safety. Errors only appear at runtime, not compile time.

### Approach 3 — Union types

```ts
function wrap(x: number | string): { value: number | string } { ... }
```

Works for a known set of types, but forces callers to narrow the result every time. Does not scale to unknown or user-defined types.

---

## Examples

### Example 1 — Minimal: identity function

```ts
function identity<T>(x: T): T {
  return x;
}

identity(true);   // boolean
identity("hi");   // string
```

One function, any type, full type safety.

---

### Example 2 — Preserving array element type

```ts
function last<T>(arr: T[]): T {
  return arr[arr.length - 1];
}

const n = last([10, 20, 30]); // number
const s = last(["a", "b"]);   // string
```

Without generics, `last` would return `any`.

---

### Example 3 — Generic with constraint

```ts
function pluck<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { name: "Alice", age: 30 };
const name = pluck(user, "name"); // string
const age  = pluck(user, "age");  // number
```

`K` is constrained to be a key of `T`. The return type is `T[K]` — the type of that specific property.

---

### Example 4 — Generic interface for API responses

```ts
interface ApiResponse<T> {
  data: T;
  error: string | null;
}

interface User { id: number; name: string; }

const response: ApiResponse<User> = {
  data: { id: 1, name: "Alice" },
  error: null,
};
```

The shape of `data` changes per endpoint, but the wrapper structure stays the same.

---

### Example 5 — Incorrect vs correct

```ts
// Bad: loses type
function toArray(x: any): any[] {
  return [x];
}
const arr = toArray(5);
arr[0].toFixed(); // no compile error even if this breaks

// Good: preserves type
function toArray<T>(x: T): T[] {
  return [x];
}
const arr2 = toArray(5);       // number[]
arr2[0].toFixed();             // valid
arr2[0].toUpperCase();         // compile error — good!
```

---

### Example 6 — Generic class

```ts
class Stack<T> {
  private items: T[] = [];

  push(item: T): void {
    this.items.push(item);
  }

  pop(): T | undefined {
    return this.items.pop();
  }
}

const stack = new Stack<number>();
stack.push(1);
stack.push("a"); // compile error
```

---

### Example 7 — Real-world: typed fetch wrapper

```ts
async function fetchJson<T>(url: string): Promise<T> {
  const res = await fetch(url);
  return res.json() as T;
}

interface Post { id: number; title: string; }

const post = await fetchJson<Post>("/api/post/1");
post.title; // TypeScript knows this is a string
```

---

## Quickfire (Interview Q&A)

**What is a generic in TypeScript?**
A type parameter that acts as a placeholder, letting you write one function or type that works safely across multiple concrete types.

**What is the difference between `any` and a generic?**
`any` discards type information; a generic preserves it. With a generic, the caller's type flows through and TypeScript can still check usage.

**What does `T extends SomeType` mean?**
It constrains `T` so it must be assignable to `SomeType` — it restricts what types the caller is allowed to pass.

**When does TypeScript infer the type parameter vs when must you specify it?**
TypeScript infers from the argument when it can. You must specify explicitly when there is no argument to infer from (e.g., `fetchJson<User>(url)`).

**What is `keyof T`?**
A type operator that produces a union of the string literal keys of `T`. Used with generics to constrain key access.

**Can generics have default values?**
Yes: `interface Foo<T = string>` — if the caller does not provide `T`, it defaults to `string`.

**What does `T[K]` mean in a generic context?**
It is an indexed access type — the type of the property at key `K` in type `T`.

**Are generics erased at runtime?**
Yes. Generics exist only in the type system and are completely removed during compilation. There is no runtime cost.

**Can a function have more than one type parameter?**
Yes: `function pair<A, B>(a: A, b: B): [A, B]` — each parameter is independent.

**What is a generic constraint used for?**
To ensure `T` has certain properties or methods, so you can safely use them inside the generic body.

**What is the difference between a generic interface and a non-generic one?**
A generic interface is parameterized — its shape depends on the type argument provided. A non-generic interface has a fixed shape.

---

## Key Takeaways

- Generics let you write one piece of code that is type-safe for many types — without duplicating it or losing type information.
- The type parameter `<T>` is just a placeholder resolved at the call site.
- Generics preserve relationships: if input is `T[]`, the output type `T` is known to match.
- `extends` constrains what types are allowed, giving you access to specific properties inside the generic.
- `keyof` and indexed access (`T[K]`) unlock powerful typed property access patterns.
- Generics exist only in the type system — zero runtime overhead.
- Use `any` only when you truly cannot know the type; prefer generics whenever the type is unknown but consistent within a usage.

---

## Vocabulary

### Nouns (concepts)

**Type parameter** — the placeholder declared in angle brackets (e.g., `T`, `K`). It represents an unknown-but-consistent type resolved when the generic is used.

**Generic function / class / interface** — a function, class, or interface that declares one or more type parameters, making it reusable across types.

**Constraint** — a restriction on a type parameter using `extends`, requiring that `T` is assignable to a specific type.

**Type argument** — the concrete type passed when using a generic (e.g., `Stack<number>` — `number` is the type argument).

**Type inference** — TypeScript's ability to automatically determine the type argument from the value passed, without the caller needing to write it explicitly.

**`keyof T`** — a type that produces a union of the keys of `T` as string literals.

**Indexed access type (`T[K]`)** — the type of the value at key `K` in type `T`.

**Default type parameter** — a fallback type used when no type argument is provided (e.g., `<T = string>`).

**Type erasure** — the process of removing all type annotations (including generics) during TypeScript compilation; they do not exist at runtime.

### Verbs (actions)

**Parameterize** — to declare a type parameter, making a function or type generic.

**Infer** — when TypeScript automatically deduces a type parameter from usage without the developer writing it explicitly.

**Constrain** — to restrict `T` using `extends` so only assignable types are allowed.

**Resolve** — when TypeScript substitutes a concrete type for a type parameter at a specific call site.

### Adjectives (properties)

**Generic** — describes a function, class, or interface that works over a range of types via type parameters.

**Constrained** — a type parameter that has an `extends` restriction and cannot be any arbitrary type.

**Inferred** — a type argument that TypeScript determined automatically rather than being written explicitly by the developer.

**Erased** — describes generic type information that is removed at compile time and not present at runtime.
