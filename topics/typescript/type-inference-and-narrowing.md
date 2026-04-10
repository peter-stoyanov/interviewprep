# Type Inference and Type Narrowing

**Abstraction level**: language feature
**Category**: type system / static analysis

---

## Related Topics

- **Depends on this**: discriminated unions, exhaustive checks, generic constraints
- **Works alongside**: union types, optional chaining, control flow analysis
- **Contrast with**: explicit type annotations, `any`, type casting (`as`)
- **Implementations of this**: TypeScript, Rust, Kotlin, Haskell (similar mechanisms)
- **Temporal neighbors**: learn union types before narrowing; learn generics after inference

---

## What is it

Type inference is the compiler's ability to deduce the type of a value without you explicitly writing it. Type narrowing is the compiler's ability to refine a broader type to a more specific one based on control flow (e.g. an `if` check).

- **Data**: types are metadata about values — they describe what shape a value has and what operations are valid on it.
- **Where it lives**: in the compiler/type-checker at build time; no runtime cost.
- **Who uses it**: the developer reads inferred types in the IDE; the compiler enforces them.
- **How it changes**: narrowing is local to a branch — outside the branch, the broader type is restored.

---

## What Problem Does it Solve

### Without inference: annotation noise

Every variable needs a manual type, even when the value makes the type obvious:

```ts
const count: number = 0;           // redundant
const name: string = "Alice";      // redundant
const items: number[] = [1, 2, 3]; // redundant
```

This is verbose and adds no information. The type is already clear from the value.

### Without narrowing: unsafe union handling

You often have values that can be one of several types — a `string | number`, or a `User | null`. Without narrowing, you cannot safely access type-specific properties:

```ts
function print(value: string | number) {
  console.log(value.toUpperCase()); // Error: toUpperCase does not exist on number
}
```

Without a way to narrow, you must cast unsafely or abandon union types entirely. This loses the safety guarantees the type system provides.

---

## How Does it Solve It

### Inference: the compiler reads the right-hand side

When you assign a value, the compiler looks at what you assigned and sets the type accordingly. The annotation is optional:

```ts
const x = 42;       // inferred: number
const s = "hello";  // inferred: string
const arr = [1, 2]; // inferred: number[]
```

Inference also propagates through functions:

```ts
function add(a: number, b: number) {
  return a + b; // return type inferred as number
}
```

The rule: if the compiler can determine the type from context, it does.

### Narrowing: control flow as evidence

TypeScript tracks what you've checked. After a check, the compiler knows more about the type inside that branch. This is called control flow analysis.

The key insight: a type check in code is evidence. The compiler uses it to narrow the set of possible types.

Narrowing mechanisms:
- `typeof` — checks primitive type
- `instanceof` — checks class/constructor
- truthiness — filters out `null`, `undefined`, `0`, `""`
- `in` operator — checks if a property exists
- discriminant property — a shared field with a literal type that identifies the variant
- custom type guard — a function returning `value is SomeType`

---

## What if We Didn't Have It (Alternatives)

### Manual casting everywhere

```ts
function print(value: string | number) {
  console.log((value as string).toUpperCase()); // unsafe: crashes if value is a number
}
```

This silences the compiler but does not make the code correct. A runtime error occurs if the assumption is wrong. You have traded safety for convenience.

### Using `any`

```ts
function print(value: any) {
  console.log(value.toUpperCase()); // no error, but no safety either
}
```

`any` opts out of the type system entirely. You lose all guarantees. The type system can no longer catch mistakes.

### Runtime-only checks without type awareness

```ts
if (typeof value === "string") {
  // compiler still thinks value is string | number here
  // (in a language without narrowing)
}
```

Without narrowing, the runtime check does not inform the type checker. You would need to cast manually after every check, re-introducing the unsafe pattern.

---

## Examples

### Example 1: Basic inference

```ts
const age = 30;         // inferred: number
const name = "Alice";   // inferred: string
let flag = true;        // inferred: boolean

flag = "yes"; // Error: Type 'string' is not assignable to type 'boolean'
```

Inference locks in the type at the point of assignment.

---

### Example 2: Function return type inference

```ts
function double(n: number) {
  return n * 2;
}

const result = double(5); // result inferred as number
```

You don't need to annotate the return type. The compiler derives it from the return expression.

---

### Example 3: typeof narrowing

```ts
function format(value: string | number): string {
  if (typeof value === "string") {
    return value.toUpperCase(); // value: string here
  }
  return value.toFixed(2);     // value: number here
}
```

After the `typeof` check, each branch has a precise type. The compiler enforces this.

---

### Example 4: Truthiness narrowing (null/undefined guard)

```ts
function greet(name: string | null) {
  if (name) {
    console.log(name.toUpperCase()); // name: string (null filtered out)
  }
}
```

A truthy check eliminates falsy values (`null`, `undefined`, `""`, `0`) from the type.

---

### Example 5: Discriminated union narrowing

```ts
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "square"; side: number };

function area(shape: Shape): number {
  if (shape.kind === "circle") {
    return Math.PI * shape.radius ** 2; // shape: { kind: "circle"; radius: number }
  }
  return shape.side ** 2;              // shape: { kind: "square"; side: number }
}
```

The `kind` field is a literal type (a discriminant). Checking it narrows the entire union to one variant.

---

### Example 6: Custom type guard

```ts
type Cat = { meow: () => void };
type Dog = { bark: () => void };

function isCat(animal: Cat | Dog): animal is Cat {
  return (animal as Cat).meow !== undefined;
}

function makeNoise(animal: Cat | Dog) {
  if (isCat(animal)) {
    animal.meow(); // animal: Cat
  } else {
    animal.bark(); // animal: Dog
  }
}
```

A type guard is a function whose return type is a type predicate (`x is T`). It tells the compiler: if this returns true, the argument is of type `T`.

---

### Example 7: Inference failure — `let` vs `const`

```ts
const x = "hello"; // inferred: "hello" (literal type)
let y = "hello";   // inferred: string  (widened)
```

`const` values can never change, so TypeScript infers the narrowest possible type (a literal). `let` values can be reassigned, so the type is widened to the general type.

---

## Quickfire (Interview Q&A)

**What is type inference?**
The compiler deduces the type of a value from context, without requiring an explicit annotation.

**What is type narrowing?**
The compiler refines a broad type (e.g. `string | null`) to a more specific one within a control flow branch, based on checks the developer writes.

**Does narrowing happen at runtime or compile time?**
The narrowing analysis is compile-time. The runtime checks (e.g. `typeof`) are ordinary JavaScript code.

**What is a discriminated union?**
A union of object types where each variant has a shared literal-typed field (a discriminant) that uniquely identifies it.

**What is a type guard?**
A function with a return type of the form `value is T` that tells the compiler to narrow the type of `value` to `T` inside the truthy branch.

**Why does `const` produce a literal type but `let` does not?**
`const` cannot be reassigned, so the compiler infers the most specific type possible. `let` can change, so the compiler widens the type to allow reassignment.

**Can narrowing be "lost"?**
Yes. Narrowing is local to a branch. Once you leave the branch, the broader type is restored. Async code can also invalidate narrowing.

**What is the difference between narrowing and casting (`as`)?**
Narrowing is verified by the compiler through control flow analysis. Casting (`as`) overrides the compiler's understanding without verification — it is unsafe.

**What does `never` mean in a narrowed branch?**
If all union variants have been handled, the remaining type is `never` — a type with no values. This is used for exhaustiveness checks.

**When should you write explicit annotations instead of relying on inference?**
For function parameters (inference has no source to derive from), public API return types, and complex initialization where the inferred type is too broad.

---

## Key Takeaways

- Inference eliminates redundant type annotations when the value already tells the compiler the type.
- Narrowing is the compiler tracking what runtime checks you have made and updating the type accordingly.
- Control flow is evidence: an `if` branch narrows the type inside it.
- Discriminated unions + narrowing make sum types safe and exhaustive.
- Casting (`as`) bypasses the type system; prefer narrowing wherever possible.
- `never` in a narrowed branch means all cases have been handled — useful for exhaustiveness checks.
- Inference widens on `let` and narrows on `const` — the mutability of a binding affects its inferred type.

---

## Vocabulary

### Nouns (concepts)

**Type inference**: the compiler's process of determining the type of an expression from context, without an explicit annotation.

**Type narrowing**: the compiler's refinement of a union or broad type to a more specific subtype within a control flow branch.

**Union type**: a type that can be one of several types, written as `A | B`. Narrowing is the main tool for working with union types safely.

**Discriminated union**: a union where each member has a shared literal-typed field (the discriminant) that identifies the variant.

**Discriminant**: the shared field in a discriminated union whose value distinguishes the variants (e.g. `kind: "circle"`).

**Literal type**: a type that represents exactly one value, such as `"circle"` or `42`. Used as discriminants and in `const` inference.

**Type predicate**: the `value is T` syntax in a function return type, which declares the function as a type guard.

**Type guard**: a runtime check that also informs the type system. Can be a built-in check (`typeof`, `instanceof`) or a custom function returning a type predicate.

**Control flow analysis**: the compiler's ability to track the possible types of a value across different branches of code.

**`never` type**: the bottom type — a type with no values. Appears in narrowed branches when all union variants have been eliminated.

**Widening**: the compiler expanding an inferred type to a broader one (e.g. from the literal `"hello"` to `string`) when the value might change.

### Verbs (actions)

**Infer**: to deduce a type from context without an explicit annotation.

**Narrow**: to reduce a type from a broad set (e.g. `string | number`) to a more specific one (e.g. `string`) within a branch.

**Guard**: to protect a code path with a check that ensures a specific type.

**Cast** (type cast): to override the compiler's type using `as`, bypassing type safety.

**Widen**: to expand a type to a more general one, typically when a `let` variable is declared.

### Adjectives (properties)

**Inferred**: a type determined by the compiler rather than written by the developer.

**Narrowed**: a type that has been refined within a control flow branch.

**Exhaustive**: a union handling where all variants are covered; the compiler can verify this if narrowing reaches `never`.

**Safe**: a pattern that cannot produce a runtime type error by relying on verified type information.

**Unsafe**: a pattern (like `as` casting) that silences the compiler without actually verifying correctness.
