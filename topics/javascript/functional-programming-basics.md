# Functional Programming Basics in JavaScript

- **Abstraction level**: concept / pattern
- **Category**: programming paradigm, software design

---

## Related Topics

- **Implementations of this**: Ramda, lodash/fp, fp-ts
- **Depends on this**: function composition pipelines, reactive programming (RxJS)
- **Works alongside**: immutability patterns, event-driven architecture
- **Contrast with**: object-oriented programming, imperative/procedural style
- **Temporal neighbors**: closures and scope, higher-order functions, array methods (map/filter/reduce)

---

## What is it

Functional programming (FP) is a style of writing code where you build programs by composing pure functions — functions that always produce the same output for the same input and have no side effects.

- **Data**: values and collections (strings, numbers, arrays, objects)
- **Where it lives**: in memory, passed between functions as arguments and return values
- **Who reads/writes it**: each function receives input and returns a new value — nothing is modified in place
- **How it changes**: data is never mutated; new versions of data are produced by transforming old ones

FP treats functions as first-class values: they can be stored in variables, passed as arguments, and returned from other functions.

---

## What Problem Does it Solve

### The core problem: hidden, unpredictable change

In a large program, many functions read and write to shared state. A function in one module changes a variable. Another function somewhere else reads it. A third one changes it again. Over time:

- You can't tell why a value changed
- Running the same function twice gives different results
- A bug in one place breaks something unrelated
- Testing requires setting up the right global state first

```js
// Imperative style — hidden mutation
let total = 0;

function addItem(price) {
  total += price; // modifies external state
}

addItem(10);
addItem(20);
console.log(total); // 30 — but what if addItem was called elsewhere?
```

Without FP discipline, code becomes hard to test, reason about, and refactor — especially as complexity grows.

---

## How Does it Solve it

### 1. Pure functions

A function is pure if:
- Given the same inputs, it always returns the same output
- It does not modify anything outside itself (no side effects)

This makes each function a predictable, isolated unit. You can test it, reuse it, and reason about it without knowing anything else about the program.

```js
// Pure
function add(a, b) {
  return a + b;
}

// Impure — reads from external state
let tax = 0.1;
function addTax(price) {
  return price + price * tax; // depends on external variable
}
```

### 2. Immutability

Instead of changing data in place, you create a new version with the change applied. The original is left untouched.

This eliminates a whole class of bugs where two parts of the program share a reference to the same object and one of them mutates it unexpectedly.

```js
// Mutation — bad
const user = { name: 'Alice', age: 30 };
user.age = 31; // original is changed

// Immutable — good
const updated = { ...user, age: 31 }; // new object, original intact
```

### 3. First-class and higher-order functions

In JavaScript, functions are values. You can:
- Assign them to variables
- Pass them as arguments
- Return them from other functions

A higher-order function either takes a function as an argument, returns one, or both.

This is the mechanism that makes FP composable — you build behavior by combining functions.

### 4. Function composition

You combine small, focused functions into larger ones by chaining them. The output of one becomes the input of the next.

Each step is a pure transformation. The composed pipeline is easy to test piece by piece.

```js
const double = x => x * 2;
const addOne = x => x + 1;

// Compose manually
const result = addOne(double(5)); // 11

// Or with a helper
const compose = (f, g) => x => f(g(x));
const doubleThenAdd = compose(addOne, double);
doubleThenAdd(5); // 11
```

### 5. Avoiding shared state

Each function works only on its inputs and produces its outputs. There is no shared mutable variable that multiple functions read and write. This makes the data flow explicit and traceable.

---

## What If We Didn't Have it (Alternatives)

### Imperative / procedural style

Direct instructions: do this, then do that, update this variable.

```js
let results = [];
for (let i = 0; i < items.length; i++) {
  if (items[i].active) {
    results.push(items[i].value * 2);
  }
}
```

Works fine for small programs. Breaks down when:
- The loop logic is duplicated in many places
- The mutation (`results.push`) happens inside other functions too
- You want to reuse just part of the logic

### Object-oriented mutation

Encapsulation in objects can reduce global mutation, but methods often mutate `this`, which creates the same hidden-change problem at a smaller scale.

```js
class Cart {
  constructor() { this.items = []; }
  add(item) { this.items.push(item); } // mutates internal state
}
```

Debugging this cart means tracing who called `.add()` and when — the same problem FP eliminates.

### Ad-hoc global variables

Quick and common in beginner code. Any function can change anything. Testing is nearly impossible because you must reconstruct exact global state to reproduce a bug.

---

## Examples

### Example 1: Pure vs impure

```js
// Impure — result depends on external state
let discount = 5;
function finalPrice(price) {
  return price - discount; // reads from outer scope
}

// Pure — all inputs are explicit
function finalPrice(price, discount) {
  return price - discount;
}
```

### Example 2: Immutability with arrays

```js
const nums = [1, 2, 3];

// Mutation — changes original
nums.push(4);

// Immutable — produces new array
const newNums = [...nums, 4];
```

### Example 3: Higher-order function

```js
function applyTwice(fn, value) {
  return fn(fn(value));
}

const double = x => x * 2;
applyTwice(double, 3); // 12
```

`applyTwice` is a higher-order function. It doesn't know what `fn` does — it just calls it. This separation of "what to do" from "how many times" is core FP thinking.

### Example 4: map, filter, reduce as FP primitives

```js
const orders = [
  { id: 1, amount: 100, paid: true },
  { id: 2, amount: 200, paid: false },
  { id: 3, amount: 50,  paid: true },
];

const total = orders
  .filter(o => o.paid)         // keep only paid
  .map(o => o.amount)          // extract amounts
  .reduce((sum, n) => sum + n, 0); // sum them

// total = 150
```

No mutation. No intermediate variables storing half-computed state. Each step is a pure transformation.

### Example 5: Composition pipeline

```js
const trim    = s => s.trim();
const lower   = s => s.toLowerCase();
const replace = s => s.replace(/\s+/g, '-');

const toSlug = s => replace(lower(trim(s)));
toSlug('  Hello World  '); // 'hello-world'
```

Each function has one job. They compose cleanly because they're pure — no side effects, no shared state.

### Example 6: Incorrect vs correct — mutation inside map

```js
// Wrong — mutates original objects
const users = [{ name: 'alice' }, { name: 'bob' }];
users.map(u => { u.name = u.name.toUpperCase(); return u; });

// Correct — returns new objects
users.map(u => ({ ...u, name: u.name.toUpperCase() }));
```

The wrong version violates immutability: the original `users` array is now changed. The correct version leaves originals untouched.

---

## Quickfire (Interview Q&A)

**Q: What is a pure function?**
A function that always returns the same output for the same inputs and causes no side effects.

**Q: What is a side effect?**
Any change that happens outside the function's scope — modifying a variable, writing to DOM, making a network request.

**Q: What does "first-class function" mean?**
Functions can be stored in variables, passed as arguments, and returned from other functions — they are values like any other.

**Q: What is a higher-order function?**
A function that takes another function as an argument or returns one.

**Q: Why does immutability matter?**
It prevents unexpected changes to shared data, making programs easier to reason about and debug.

**Q: What is function composition?**
Combining small functions so the output of one feeds into the input of the next.

**Q: How is `map` an example of FP?**
`map` is a higher-order function that applies a pure transformation to each item and returns a new array — it never mutates the original.

**Q: What is the difference between `map` and `forEach`?**
`map` returns a new array (transformation); `forEach` performs side effects and returns nothing.

**Q: Can JavaScript be fully functional?**
No — JavaScript has mutable state, classes, and side effects built in. FP is a style you apply, not something the language enforces.

**Q: What is a closure in the context of FP?**
A function that captures variables from its surrounding scope — used heavily in FP for factories and partial application.

**Q: What is partial application?**
Pre-filling some arguments of a function to produce a new, specialized function.

```js
const add = a => b => a + b;
const add5 = add(5);
add5(3); // 8
```

---

## Key Takeaways

- FP is a style where you compose pure, stateless functions to transform data
- Pure functions have no side effects and always return the same result for the same input
- Immutability means creating new data instead of modifying existing data
- Functions are values: they can be passed around, returned, and stored like any other data
- Higher-order functions (map, filter, reduce) are the primary tools for transforming collections
- Composition lets you build complex behavior from simple, testable pieces
- The core benefit: data flow becomes explicit, predictable, and easy to test

---

## Vocabulary

### Nouns (concepts)

- **Pure function**: a function with no side effects whose output depends only on its inputs
- **Side effect**: any change a function causes outside its own scope (mutation, I/O, DOM updates)
- **Immutability**: the property of data that cannot be changed after creation; new values are produced instead
- **Higher-order function**: a function that accepts or returns another function
- **First-class function**: a function treated as a value — storable, passable, returnable
- **Function composition**: combining functions so the output of one feeds into the input of the next
- **Closure**: a function that captures and remembers variables from its outer scope
- **Partial application**: producing a new function by pre-supplying some arguments to an existing function
- **Currying**: transforming a multi-argument function into a chain of single-argument functions
- **Referential transparency**: the property of a pure function expression — it can be replaced by its return value without changing behavior

### Verbs (actions)

- **Compose**: combine functions into a pipeline
- **Map**: apply a function to each element of a collection, returning a new collection
- **Filter**: produce a new collection containing only elements that pass a test
- **Reduce**: fold a collection into a single value by accumulating results
- **Transform**: produce a new data value from an input without mutating it
- **Curry**: convert a function to take arguments one at a time

### Adjectives (properties)

- **Pure**: free from side effects, deterministic
- **Immutable**: cannot be changed after creation
- **Declarative**: expressing what to compute, not how to do it step by step
- **Stateless**: not depending on or modifying external state
- **Composable**: can be combined cleanly with other functions
