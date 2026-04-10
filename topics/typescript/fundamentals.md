# TypeScript Fundamentals

**Abstraction level**: language feature / type system layer  
**Category**: static typing, JavaScript superset, tooling

---

## Related Topics

- **Implementations of this**: TypeScript compiler (`tsc`), `ts-node`, Babel with TypeScript preset
- **Depends on this**: advanced TypeScript patterns (generics, conditional types, mapped types)
- **Works alongside**: ESLint with TypeScript rules, Zod/io-ts for runtime validation, Jest with ts-jest
- **Contrast with**: JavaScript (dynamic typing), Flow (alternative static type checker)
- **Temporal neighbors**: learn after JavaScript fundamentals; learn before framework-specific TypeScript (React + TS, Node + TS)

---

## What Is It

TypeScript is a statically typed superset of JavaScript. It adds a type layer on top of JavaScript that is checked at compile time, before the code runs. All valid JavaScript is valid TypeScript.

- **Data**: types describe the shape and kind of data — what fields it has, what values are allowed, what functions accept and return
- **Where it lives**: types exist only at compile time; they are erased before the code reaches the browser or Node.js
- **Who reads/writes it**: the developer writes types; the TypeScript compiler (`tsc`) reads and checks them
- **How it changes**: as data flows through functions and modules, TypeScript tracks what type each value has at each point

---

## What Problem Does It Solve

JavaScript is dynamically typed — a variable can hold any value at any time. This is flexible, but it creates problems as codebases grow.

**Simple scenario**: a function expects a user object with a `name` field.

```js
function greet(user) {
  return "Hello, " + user.name;
}
```

Nothing stops a caller from passing `null`, a number, or an object with no `name`. The bug surfaces at runtime, in production.

**Failure modes without types**:

- **Duplication**: developers document expected shapes in comments that drift out of sync with the code
- **Inconsistency**: a function is called with different shaped objects in different files; no single source of truth
- **Invalid data**: `undefined` or `null` flows into a function that cannot handle it; crash at runtime
- **Hard-to-track changes**: renaming a field in one file silently breaks callers in other files
- **Unclear ownership**: no way to know what a function accepts without reading its full body

TypeScript solves these by making contracts explicit and machine-checked.

---

## How Does It Solve It

### 1. Types as contracts

A type describes what shape data must have. Every function input and output is a contract. The compiler rejects code that violates the contract before it runs.

```ts
type User = { name: string; age: number };

function greet(user: User): string {
  return "Hello, " + user.name;
}
```

Passing `null` or `{ name: 123 }` is a compile error — caught before any test runs.

### 2. Type inference

TypeScript infers types from context. You do not have to annotate everything. The compiler tracks what type a value has as it flows through the program.

```ts
const x = 42;          // inferred: number
const y = x + " hi";   // inferred: string
```

You add explicit annotations at boundaries (function parameters, return types, public APIs) where inference is ambiguous.

### 3. Structural typing

TypeScript uses structural typing: a value satisfies a type if it has at least the required fields. The name of the type does not matter, only the shape.

```ts
type Point = { x: number; y: number };

const p = { x: 1, y: 2, z: 3 }; // valid as Point — extra fields are fine
```

### 4. Union types and narrowing

A value can be one of several types. TypeScript tracks which branch you are in, narrowing the type as control flow proceeds.

```ts
function display(value: string | number) {
  if (typeof value === "string") {
    // TypeScript knows: value is string here
    console.log(value.toUpperCase());
  } else {
    // TypeScript knows: value is number here
    console.log(value.toFixed(2));
  }
}
```

### 5. Interfaces and type aliases

Two ways to name a shape. Both describe the structure of an object.

- `interface`: preferred for object shapes, extensible via `extends`
- `type`: more flexible — can describe unions, primitives, tuples, and mapped forms

### 6. Generics

Generics let you write code that works over many types while preserving type information. The type is a parameter.

```ts
function identity<T>(value: T): T {
  return value;
}

identity(42);       // T is number
identity("hello");  // T is string
```

---

## What If We Didn't Have It (Alternatives)

### JSDoc comments

```js
/**
 * @param {string} name
 * @returns {string}
 */
function greet(name) { return "Hi, " + name; }
```

Works for simple cases, but no refactoring support, no cross-file validation, and comments drift from the real code.

### Runtime validation only

```js
function greet(name) {
  if (typeof name !== "string") throw new Error("Expected string");
  return "Hi, " + name;
}
```

Catches errors at runtime, not before. Does not scale — you add guards to every function and still get no editor assistance.

### Implicit any (TypeScript without discipline)

Writing TypeScript but annotating everything as `any` disables checking:

```ts
function greet(name: any) { return "Hi, " + name; }
```

Compiles, but provides none of the safety. `any` is an escape hatch, not a design pattern.

---

## Examples

### Example 1 — Basic annotation

```ts
let count: number = 0;
count = "hello"; // Error: Type 'string' is not assignable to type 'number'
```

The type annotation makes the contract explicit; the compiler enforces it.

---

### Example 2 — Object type

```ts
type Product = {
  id: number;
  name: string;
  price: number;
};

function formatPrice(product: Product): string {
  return `${product.name}: $${product.price}`;
}
```

Renaming `price` to `cost` in `Product` immediately surfaces every call site that reads `.price`.

---

### Example 3 — Optional fields

```ts
type Config = {
  host: string;
  port?: number; // optional
};

const c: Config = { host: "localhost" }; // valid
```

`?` marks a field as possibly absent. TypeScript forces you to handle the `undefined` case when you access it.

---

### Example 4 — Union type and narrowing

```ts
type Result = { ok: true; value: string } | { ok: false; error: string };

function handle(result: Result) {
  if (result.ok) {
    console.log(result.value); // only accessible here
  } else {
    console.log(result.error); // only accessible here
  }
}
```

This discriminated union pattern makes invalid states unrepresentable.

---

### Example 5 — Generic function

```ts
function first<T>(items: T[]): T | undefined {
  return items[0];
}

const n = first([1, 2, 3]);    // n: number | undefined
const s = first(["a", "b"]);   // s: string | undefined
```

The caller gets the specific type back, not just `any`.

---

### Example 6 — Interface vs type alias

```ts
interface Animal {
  name: string;
}

interface Dog extends Animal {
  breed: string;
}

type StringOrNumber = string | number; // type alias can express this; interface cannot
```

Use `interface` for object shapes that may be extended. Use `type` for unions, intersections, and primitives.

---

### Example 7 — Incorrect vs correct: missing null check

```ts
// Incorrect — TypeScript with strict mode will reject this
function getLength(s: string | null): number {
  return s.length; // Error: Object is possibly 'null'
}

// Correct
function getLength(s: string | null): number {
  if (s === null) return 0;
  return s.length; // TypeScript knows s is string here
}
```

---

## Quickfire (Interview Q&A)

**What is TypeScript?**  
A statically typed superset of JavaScript. It adds compile-time type checking that is stripped away before the code runs.

**What is the difference between `type` and `interface`?**  
Both describe object shapes. `interface` supports declaration merging and `extends`. `type` can express unions, intersections, and mapped types. In practice they are mostly interchangeable for object shapes.

**What is structural typing?**  
TypeScript checks compatibility by shape, not by name. If an object has all the required fields, it satisfies the type — even if it was not declared with that type.

**What does `any` do?**  
It disables type checking for that value. TypeScript accepts anything assigned to or from `any`. It is an escape hatch that removes safety.

**What is the difference between `unknown` and `any`?**  
`unknown` is a safe top type. You can assign anything to `unknown`, but you cannot use it without first narrowing it. `any` disables checking entirely.

**What is type narrowing?**  
TypeScript refining the type of a value inside a conditional branch based on a runtime check (e.g., `typeof`, `instanceof`, equality check).

**What are generics?**  
A way to write code that works over many types while preserving type information. The type is passed as a parameter and tracked through the function or class.

**What is a discriminated union?**  
A union of types that each share a common literal field (the discriminant). TypeScript uses the field value to narrow to the correct branch.

**What is `strictNullChecks`?**  
A compiler option (on by default in strict mode) that makes `null` and `undefined` separate types. Without it, both can be assigned to any type.

**What happens to types at runtime?**  
They are erased. TypeScript types exist only during compilation. The emitted JavaScript has no type information.

**When should you use explicit annotations vs rely on inference?**  
Annotate function parameters and return types explicitly (they are API boundaries). Let inference handle local variables where the type is obvious from the value.

**What is a type guard?**  
A function that returns `value is SomeType`, telling TypeScript to narrow the type in the truthy branch of a conditional.

---

## Key Takeaways

- TypeScript adds a type layer to JavaScript that is checked at compile time and erased at runtime
- Types are contracts: they describe what shape data must have at each point in the program
- TypeScript uses structural typing — shape matters, not name
- Union types plus narrowing let you represent values that can be one of several forms, safely
- Generics preserve type information across transformations without losing specificity
- `any` disables safety; prefer `unknown` when the type is genuinely unknown
- Strict mode (`"strict": true`) enables the most useful checks including null safety

---

## Vocabulary

### Nouns (concepts)

**Type**: a description of the shape and kind of a value — what fields it has, what operations are valid on it.

**Type annotation**: explicit syntax (`: Type`) that tells TypeScript what type a variable, parameter, or return value has.

**Type inference**: TypeScript's ability to determine the type of a value from context, without an explicit annotation.

**Interface**: a named description of an object shape. Supports `extends` and declaration merging.

**Type alias**: a name given to any type expression, including unions, intersections, and primitives.

**Union type**: a type that can be one of several types, written as `A | B`.

**Intersection type**: a type that combines multiple types into one, requiring all fields, written as `A & B`.

**Generics**: type parameters that allow writing reusable code where the specific type is determined by the caller.

**Type parameter**: the placeholder in a generic (e.g., `T` in `function f<T>`). Resolved when the generic is used.

**Discriminated union**: a union where each member has a shared literal field used to identify which variant is active.

**Type guard**: a runtime check (or a function returning `value is T`) that narrows a type within a block.

**Structural typing**: a type compatibility model where two types are compatible if their shapes match, regardless of name.

**Nominal typing**: a type compatibility model (not used in TypeScript) where types must share the same declared name to be compatible.

**`any`**: a type that disables checking — a value of type `any` can be used as anything and assigned from anything.

**`unknown`**: a safe top type — anything can be assigned to it, but it cannot be used without narrowing first.

**`never`**: a type representing values that never occur — used for exhaustive checks and unreachable code.

**Strict mode**: a TypeScript configuration (`"strict": true`) that enables a set of stricter compiler checks, including null safety.

**`tsc`**: the TypeScript compiler CLI. Transforms `.ts` files into `.js` files and performs type checking.

**Declaration file (`.d.ts`)**: a file containing only type information, used to type-check code that consumes a JavaScript library.

### Verbs (actions)

**Annotate**: to explicitly attach a type to a variable, parameter, or return value using `: Type` syntax.

**Infer**: for the compiler to determine a type automatically from context.

**Narrow**: to refine a union or broad type to a more specific type inside a conditional branch.

**Emit**: to produce JavaScript output from TypeScript source during compilation.

**Erase**: to remove type information from source code during compilation — types do not appear in emitted JavaScript.

**Extend**: to create a type or interface that includes all members of another plus additional ones.

### Adjectives (properties)

**Statically typed**: types are checked before the program runs, at compile time.

**Dynamically typed**: types are checked at runtime, as values are used (JavaScript's default behavior).

**Optional**: a field or parameter that may be absent (`?` suffix). Its type is automatically `T | undefined`.

**Readonly**: a field that cannot be reassigned after the object is created.

**Generic**: parameterized by a type variable — the specific type is supplied at the call site.

**Strict**: referring to compiler settings that enforce the most rigorous checks, especially null safety.
