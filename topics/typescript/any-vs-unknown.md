# any vs unknown

**Abstraction level**: language feature
**Category**: type system, TypeScript

---

## Related Topics

- **Depends on this**: type narrowing, type guards, generic constraints
- **Works alongside**: union types, type guards, `never`, `void`
- **Contrast with**: `never` (bottom type), `object`, `{}` (non-nullable top type)
- **Temporal neighbors**: learn after TypeScript basics; before advanced generics and type narrowing

---

## What is it

`any` and `unknown` are TypeScript's two "escape hatch" types — both can hold a value of any shape. The difference is in what you are allowed to do with that value after you store it.

`any` disables the type checker entirely for that value. You can read any property, call it as a function, pass it anywhere — TypeScript trusts you completely.

`unknown` also accepts any value, but it refuses to let you use it until you prove its shape through a type check. It is the safe version of `any`.

- Data: any runtime value — string, number, object, null, function, etc.
- Where it lives: anywhere in code — function parameters, return values, variables
- Who reads/writes it: the developer decides shape; TypeScript enforces it for `unknown`, not for `any`

---

## What problem does it solve

When you receive data whose shape you do not know at compile time — a JSON API response, a `catch` block error, a dynamic config file — you cannot assign it a precise type.

Without an escape hatch, TypeScript forces you to lie about the type or use verbose assertions.

**Problems `any` creates:**

- Silently disables type checking — bugs hide until runtime
- Spreads unsafety: passing an `any` to a typed function infects it
- Refactoring becomes risky because TypeScript stops protecting you

**What `unknown` solves:**

- Lets you accept any value while forcing you to check before use
- Keeps the rest of the code safe — you cannot pass `unknown` where a `string` is expected
- Makes intent explicit: "I do not know the shape yet, but I will check"

---

## How does it solve it

**Principle 1: Permissive intake, zero trust on output (`unknown`)**

`unknown` accepts anything. But TypeScript treats the value as opaque until you narrow it. You must run a runtime check (`typeof`, `instanceof`, a type guard) before reading properties or calling the value.

Control: TypeScript enforces narrowing at the call site, not at the assignment site.

**Principle 2: Total trust, no checking (`any`)**

`any` opts out of the type system for that value. TypeScript will not warn you, no matter what you do with it. It is a deliberate "I know better" declaration to the compiler.

Control: none. The developer takes full responsibility.

**Principle 3: Explicit vs implicit unsafety**

`unknown` makes the unsafety visible — you are forced to write a guard. `any` hides it — the code looks typed but is not checked.

**Principle 4: Assignability rules**

- `any` is assignable to and from every type.
- `unknown` is assignable from every type, but assignable to almost nothing (only `unknown` and `any`).

This is the key mechanical difference.

---

## What if we didn't have it (Alternatives)

**Naive approach: lie with a specific type**

```ts
const data = JSON.parse(input) as User;
data.name.toUpperCase(); // crashes at runtime if shape is wrong
```

No safety — you told TypeScript it is a `User` and it believed you.

**Quick hack: use `any` everywhere**

```ts
function process(data: any) {
  data.doSomething(); // compiles, may crash
}
```

Works short-term. Scales poorly — errors appear only at runtime, often in production.

**Without `unknown` in catch blocks:**

Before TypeScript 4.0, caught errors were `any`. You could call `.message` on a number — TypeScript would not warn you. `unknown` forces a guard before access.

---

## Examples

### Example 1: Basic assignability

```ts
let a: any = 42;
a.toUpperCase(); // no error — TypeScript trusts you

let u: unknown = 42;
u.toUpperCase(); // Error: Object is of type 'unknown'
```

### Example 2: Narrowing `unknown` before use

```ts
function printLength(value: unknown) {
  if (typeof value === "string") {
    console.log(value.length); // safe: narrowed to string
  }
}
```

You must narrow before use. TypeScript will not let you skip the check.

### Example 3: `any` spreading unsafety

```ts
function greet(name: string) {
  return "Hello, " + name.toUpperCase();
}

const data: any = 42;
greet(data); // compiles — TypeScript accepts any as string
// crashes at runtime: .toUpperCase is not a function
```

### Example 4: `unknown` blocking the spread

```ts
const data: unknown = 42;
greet(data); // Error: Argument of type 'unknown' is not assignable to type 'string'
```

You are forced to narrow first — the unsafety cannot leak out.

### Example 5: Error handling (catch block)

```ts
try {
  riskyOperation();
} catch (err) {
  // err is 'unknown' in strict mode (TypeScript 4.0+)
  if (err instanceof Error) {
    console.log(err.message); // safe
  }
}
```

Without this, you would blindly call `.message` on whatever was thrown — including strings and numbers.

### Example 6: API response — wrong vs right

```ts
// Wrong — lying to TypeScript
const res = await fetch("/api/user");
const user = (await res.json()) as User; // unchecked cast

// Better — treat as unknown, validate explicitly
const data: unknown = await res.json();
if (isUser(data)) {
  console.log(data.name); // safe
}
```

`unknown` forces you to validate before trusting the data.

### Example 7: Generic constraint vs `unknown`

```ts
// any: loses type information
function identity(x: any): any { return x; }

// unknown: safe but too restrictive — can't do anything with T
function identity<T>(x: T): T { return x; } // correct generic approach
```

For reusable functions, generics are better than both `any` and `unknown`.

---

## Quickfire (Interview Q&A)

**Q: What is the difference between `any` and `unknown`?**
Both accept any value, but `unknown` requires a type check before you can use the value; `any` skips type checking entirely.

**Q: When should you use `unknown`?**
When you receive data whose shape you do not control — API responses, `catch` blocks, dynamic input — and you want TypeScript to force you to validate before use.

**Q: When is `any` acceptable?**
When migrating a JavaScript codebase to TypeScript incrementally, or in narrow, well-understood cases where the overhead of narrowing outweighs the benefit.

**Q: Can you assign `unknown` to a `string` variable?**
No. `unknown` is not assignable to any type other than `unknown` and `any` without a type guard or assertion.

**Q: Can you assign `any` to a `string` variable?**
Yes. `any` is assignable to and from every type.

**Q: What happens to `any` when you pass it into a typed function?**
TypeScript accepts it silently — the type check is bypassed. This is how `any` spreads.

**Q: What does TypeScript give you in a `catch (err)` block?**
`unknown` in strict mode (TypeScript 4.0+). You must narrow it before accessing properties.

**Q: Is `unknown` the top type in TypeScript?**
Yes. Every type is assignable to `unknown`. It is the safe top type; `any` is the unsafe escape hatch.

**Q: How do you narrow `unknown`?**
Using `typeof`, `instanceof`, or a user-defined type guard function that returns `value is T`.

**Q: What is a type guard?**
A function that returns `value is T` — it tells TypeScript that after the check passes, the value is of type `T`.

---

## Key Takeaways

- `any` disables the type checker; `unknown` defers it until you prove the shape.
- Both accept any value — they differ in what you can do with that value afterward.
- `unknown` is assignable to nothing (except `unknown` and `any`); `any` is assignable to everything.
- `any` spreads silently — passing it to typed code bypasses all checks downstream.
- `unknown` forces narrowing at the point of use, keeping the rest of the codebase safe.
- Prefer `unknown` over `any` for untyped external data; use type guards to narrow.
- In `catch` blocks, treat `err` as `unknown` and check before accessing `.message`.
- Use `any` sparingly and intentionally — treat it as a technical debt marker.

---

## Vocabulary

### Nouns (concepts)

**top type**: A type that every other type is assignable to. In TypeScript, both `any` and `unknown` act as top types for assignment intake, but differ in how you can use the value.

**bottom type**: `never` — the opposite of a top type. No value is assignable to `never`. Comes up when a function never returns or all branches are exhausted.

**type guard**: A conditional check (`typeof`, `instanceof`, or a custom function returning `value is T`) that narrows the type of a variable within a branch.

**narrowing**: The process TypeScript uses to refine a broad type (like `unknown` or a union) to a more specific type based on control flow.

**assignability**: Whether a value of one type can be used where another type is expected. `any` is assignable to and from all types; `unknown` is only assignable to `any` and itself.

**escape hatch**: A mechanism to opt out of strict checking. `any` is TypeScript's primary escape hatch.

**type assertion**: Using `as SomeType` to tell TypeScript the type of a value without a runtime check. Dangerous when used on `unknown` data without validation.

### Verbs (actions)

**narrow**: To reduce a broad type to a specific type using a runtime check.

**infer**: TypeScript's process of automatically determining a type from context, without explicit annotation.

**assert**: To use `as Type` to override TypeScript's type inference. Does not produce runtime code.

**spread (unsafety)**: When an `any` value is passed into typed code, bypassing type checks — "spreading" the unsafety to consuming code.

### Adjectives (properties)

**unsafe**: Describes `any` — no compile-time guarantees about the shape of the value.

**opaque**: Describes how TypeScript treats `unknown` — the value exists but its shape is not accessible until proven.

**strict**: A TypeScript compiler mode (`strict: true`) that enables stronger checks, including `unknown` in catch blocks.
