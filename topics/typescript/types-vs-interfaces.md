# Types vs Interfaces

- **Abstraction level**: language feature
- **Category**: type system / TypeScript

---

## Related Topics

- **Depends on this**: generics, structural typing, object modeling in TypeScript
- **Works alongside**: enums, utility types (`Partial`, `Pick`, `Omit`), discriminated unions
- **Contrast with**: nominal typing (Java/C# classes), runtime type checking
- **Temporal neighbors**: learn after TypeScript basics, before advanced generics and utility types

---

## What is it

`interface` and `type` are two ways to describe the shape of data in TypeScript. Both tell the compiler: "this value must have this structure." At runtime, neither exists — they are erased during compilation.

- **Data**: structured values — objects, functions, primitives, unions
- **Where it lives**: compile-time only (type-checking phase)
- **Who reads/writes it**: the TypeScript compiler and the developer
- **How it changes**: types are static declarations; they don't change at runtime

The distinction matters for how you compose and extend shapes, and what kinds of shapes each can describe.

---

## What problem does it solve

### Without structured type descriptions:

```ts
function greet(user) {
  return `Hello, ${user.name}`;
}
```

TypeScript infers or accepts `any`. You get no editor support, no error if `user.name` doesn't exist.

### With structured types:

You describe the shape once and reuse it everywhere. The compiler catches mismatches before code runs.

```ts
interface User {
  name: string;
  age: number;
}
```

Without `interface` or `type`, complexity grows through:
- **Duplication**: same shape re-described in multiple places
- **Inconsistency**: one place allows `null`, another doesn't
- **Invalid data passing silently**: wrong shape passed to a function with no warning
- **Hard-to-track contracts**: no central definition of what a "User" looks like

---

## How does it solve it

### Named shapes

Both `type` and `interface` let you give a shape a name and reuse it:

```ts
interface Point { x: number; y: number; }
type Point = { x: number; y: number; };
```

### Composition

Both support combining shapes, but with different syntax:

```ts
// interface: extends keyword
interface Animal { name: string; }
interface Dog extends Animal { breed: string; }

// type: intersection operator
type Animal = { name: string; };
type Dog = Animal & { breed: string; };
```

### Declaration merging (interface only)

Interfaces with the same name in the same scope are automatically merged:

```ts
interface Window { myProp: string; }
interface Window { myOtherProp: number; }
// result: Window has both props
```

This is how libraries augment global types (e.g. adding to `Express.Request`).

### Expressive power (type only)

`type` can describe things `interface` cannot:

```ts
type ID = string | number;           // union
type Pair<T> = [T, T];               // tuple
type Callback = () => void;          // function alias
type Result = "ok" | "error";        // literal union
```

---

## What if we didn't have it (Alternatives)

### Inline annotations everywhere

```ts
function save(user: { name: string; age: number }) {}
function load(): { name: string; age: number } {}
```

Breaks at scale — any change to the shape requires updating every callsite. No single source of truth.

### Using `any`

```ts
function process(data: any) {
  data.nonExistent(); // no error — silent bug
}
```

Removes all type safety. Defeats the purpose of TypeScript.

### Using classes as types

```ts
class User { name: string; age: number; }
function greet(u: User) {}
```

Works, but couples type definition to a runtime construct. Classes exist at runtime and carry methods, constructors, and inheritance baggage. Unnecessarily heavy for describing data shapes.

---

## Examples

### Example 1 — Basic object shape (equivalent)

```ts
interface User { id: number; name: string; }
type User = { id: number; name: string; };
// identical behavior for objects
```

### Example 2 — Union (type only)

```ts
type Status = "active" | "inactive" | "banned";
// interface cannot express this
```

### Example 3 — Extending shapes

```ts
// interface: explicit inheritance
interface Shape { color: string; }
interface Circle extends Shape { radius: number; }

// type: intersection
type Shape = { color: string; };
type Circle = Shape & { radius: number; };
```

Both result in `Circle` having `color` and `radius`.

### Example 4 — Declaration merging (interface only)

```ts
// Useful when augmenting third-party types
interface Request { userId?: string; }  // adds to Express Request
```

With `type`, re-declaring the same name is a compile error.

### Example 5 — Function shapes

```ts
// Both work for function signatures
type Formatter = (value: string) => string;
interface Formatter { (value: string): string; }
// type alias is more common and readable here
```

### Example 6 — Incorrect vs correct

```ts
// Wrong: using interface for a union type
interface Result = "ok" | "fail"; // syntax error

// Correct: use type for unions
type Result = "ok" | "fail";
```

### Example 7 — Implements keyword with interface

```ts
interface Serializable {
  serialize(): string;
}

class Config implements Serializable {
  serialize() { return JSON.stringify(this); }
}
// Classes can implement interfaces — not type aliases (in most cases)
```

---

## Quickfire (Interview Q&A)

**Q: What is the main difference between `type` and `interface`?**
A: `interface` is for describing object shapes and supports declaration merging; `type` is more flexible and can describe unions, tuples, primitives, and intersections.

**Q: Can `interface` describe a union type?**
A: No. Unions (`string | number`) can only be expressed with `type`.

**Q: What is declaration merging?**
A: When two `interface` declarations share the same name, TypeScript merges them into one. This does not apply to `type`.

**Q: Which should you use for objects?**
A: Either works. Many style guides prefer `interface` for public API object shapes because of merging support and cleaner `extends` syntax.

**Q: Can a class `implement` a `type`?**
A: Yes, if the type is an object shape. But `interface` is the conventional choice for this use case.

**Q: Do `type` and `interface` exist at runtime?**
A: No. Both are erased during compilation. They only exist during type checking.

**Q: When would you choose `type` over `interface`?**
A: When you need unions, tuples, function aliases, mapped types, or conditional types.

**Q: Can you extend a `type` with `interface`?**
A: Yes — `interface A extends B {}` works even if `B` is a `type` alias (as long as it's an object shape).

**Q: What is an intersection type?**
A: A `type` combining multiple shapes with `&`, requiring a value to satisfy all of them simultaneously.

**Q: What does TypeScript's structural typing mean for both?**
A: TypeScript checks shapes, not names. A value with the right properties satisfies an interface or type regardless of how it was declared.

---

## Key Takeaways

- Both `type` and `interface` describe the shape of data at compile time; neither exists at runtime.
- `interface` supports declaration merging — useful for augmenting library types.
- `type` is more expressive: unions, tuples, mapped types, and conditional types require it.
- For object shapes, both are interchangeable in most cases — pick one and be consistent.
- Classes can `implement` both `interface` and object-shaped `type` aliases.
- `interface` uses `extends`; `type` uses `&` (intersection) for composition.
- Prefer `interface` for public APIs and object contracts; prefer `type` for complex or composite type expressions.

---

## Vocabulary

### Nouns (concepts)

**Interface**: A named compile-time description of an object's shape. Supports extension and declaration merging.

**Type alias**: A name given to any TypeScript type expression using the `type` keyword. More flexible than `interface`.

**Union type**: A type that allows a value to be one of several specified types (`string | number`). Only expressible with `type`.

**Intersection type**: A type that combines multiple types into one using `&`, requiring all properties to be present.

**Declaration merging**: TypeScript behavior where multiple `interface` declarations with the same name are merged into a single definition.

**Structural typing**: TypeScript's approach to type compatibility — two types are compatible if they have the same shape, regardless of how they were named or declared.

**Tuple**: A fixed-length array with specific types at each index. Only expressible with `type`.

**Literal type**: A type that represents a specific value, like `"ok"` or `42`. Used in union types for constrained values.

### Verbs (actions)

**Extends**: Keyword used by `interface` to inherit from another interface or object type.

**Implements**: Keyword used by a class to declare that it satisfies a given interface or type shape.

**Merge (declaration merging)**: What TypeScript does automatically when two interfaces share the same name in scope.

**Erase**: What the TypeScript compiler does to type information at compile time — types do not appear in the output JavaScript.

### Adjectives (properties)

**Structural**: Compatible based on shape, not name or origin.

**Nominal**: Compatible based on declared type name — TypeScript is not this by default.

**Ambient**: Describes type declarations that have no runtime value (all interfaces and type aliases are ambient in this sense).

**Expressive**: Able to describe a wide range of type shapes — `type` is considered more expressive than `interface`.
