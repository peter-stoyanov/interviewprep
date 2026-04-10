# Closures and Scope

- **Abstraction level**: language feature
- **Category**: JavaScript / general programming fundamentals

---

## Related Topics

- **Depends on this**: module patterns, memoization, currying, event handlers, async callbacks
- **Works alongside**: higher-order functions, the execution context / call stack
- **Contrast with**: global state, class-based encapsulation (private fields)
- **Temporal neighbors**: learn execution context and the call stack before this; learn currying and partial application after

---

## What is it

Scope determines where in your code a variable is visible and accessible. Closures are what happen when a function retains access to variables from the scope in which it was defined, even after that outer scope has finished executing.

- **What data**: any variable — strings, numbers, objects, functions — declared inside a function or block
- **Where it lives**: in memory, kept alive by the closure reference
- **Who reads/writes it**: the inner function that captured it
- **How it changes**: the inner function can read and mutate the captured variable; changes persist across calls

Every function in JavaScript is a closure — it always carries a reference to the scope it was born in.

---

## What problem does it solve

### The problem: sharing data without exposing it globally

You have a counter. You need it to persist across multiple function calls. The naive solution is a global variable:

```js
let count = 0;
function increment() { count++; }
```

This works, but `count` is now exposed to every part of the program. Any code anywhere can accidentally reset or corrupt it.

As complexity grows, this becomes a serious problem:

- **Duplication**: multiple counters means multiple globals, easy to confuse
- **Unclear ownership**: any function can change `count` — you lose control of who modifies state
- **Invalid data**: nothing prevents `count = "oops"` from being written somewhere else
- **Hard-to-track changes**: a bug in the counter could come from anywhere in the codebase

Closures solve this by letting you create **private, persistent state** tied to a specific function, not to the global environment.

---

## How does it solve it

### 1. Lexical scoping — scope is determined at write time, not run time

When you write a function, JavaScript looks at where it is defined (not where it is called) to decide which variables it can see. This is called **lexical scope**.

```js
const x = 10;
function foo() {
  console.log(x); // always sees x = 10, regardless of where foo() is called
}
```

The scope chain is fixed at the moment the function is written.

### 2. Closures — captured variables outlive the outer scope

When an inner function references a variable from an outer function, the JavaScript engine keeps that variable alive in memory — even after the outer function has returned.

```js
function makeCounter() {
  let count = 0;        // lives inside makeCounter's scope
  return function() {
    count++;
    return count;
  };
}
```

When `makeCounter()` returns, its local scope normally would be garbage collected. But because the returned function still references `count`, the engine keeps `count` alive. The inner function has closed over it.

### 3. Encapsulation — controlling what is exposed

By returning only the inner function (not `count` directly), you decide what is public and what is private. The variable `count` cannot be accessed or corrupted from outside.

### 4. Persistent state per instance

Each call to `makeCounter()` creates a new, independent closure with its own `count`. Closures give you instance-like behavior without classes.

---

## What if we didn't have it (Alternatives)

### Global variables

```js
let count = 0;
function increment() { count++; }
```

Works for trivial cases. Breaks immediately when you need two counters, or when other code accidentally touches `count`.

### Object with shared state

```js
const counter = { count: 0, increment() { this.count++; } };
```

Better — but `counter.count` is still fully public. Nothing stops `counter.count = -999`.

### Class with private fields (modern JS)

```js
class Counter {
  #count = 0;
  increment() { this.#count++; }
}
```

This solves the same problem as closures, via a different mechanism. Closures are lighter — no instantiation syntax needed. Classes make sense when you need multiple methods or inheritance.

---

## Examples

### Example 1 — Basic closure

```js
function outer() {
  const message = "hello";
  function inner() {
    console.log(message); // accesses outer's variable
  }
  inner();
}
outer(); // "hello"
```

`inner` closes over `message`. This is the most basic form.

---

### Example 2 — Returned function retaining state

```js
function makeCounter() {
  let count = 0;
  return () => ++count;
}

const counter = makeCounter();
counter(); // 1
counter(); // 2
counter(); // 3
```

`makeCounter` is done executing, but `count` lives on because the returned arrow function holds a reference to it.

---

### Example 3 — Two independent closures

```js
const a = makeCounter();
const b = makeCounter();

a(); // 1
a(); // 2
b(); // 1  <- independent, its own count
```

Each call to `makeCounter()` creates a new scope, so each closure owns a separate `count`.

---

### Example 4 — Classic bug (loop + var)

```js
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0);
}
// prints: 3, 3, 3
```

`var` is function-scoped, not block-scoped. All three callbacks close over the same `i`, which ends up as `3` by the time they run.

**Fix with `let`** (block-scoped — creates a new binding per iteration):

```js
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0);
}
// prints: 0, 1, 2
```

---

### Example 5 — Private state pattern

```js
function createWallet(initialBalance) {
  let balance = initialBalance;
  return {
    deposit(amount)  { balance += amount; },
    withdraw(amount) { balance -= amount; },
    getBalance()     { return balance; },
  };
}

const w = createWallet(100);
w.deposit(50);
w.getBalance(); // 150
// balance is not accessible directly — only through the returned methods
```

This is the **module pattern**: closures create private state, returned methods form a public API.

---

### Example 6 — Scope chain lookup

```js
const name = "global";

function outer() {
  const name = "outer";
  function inner() {
    console.log(name); // "outer" — walks up the chain, finds it before "global"
  }
  inner();
}
outer();
```

JavaScript looks up the scope chain starting from the innermost scope. It stops at the first match.

---

## Quickfire (Interview Q&A)

**Q: What is a closure?**
A closure is a function that retains access to variables from its outer scope, even after that scope has finished executing.

**Q: What is lexical scope?**
Scope is determined by where a function is written in the source code, not where it is called.

**Q: What is the scope chain?**
The ordered list of scopes that JavaScript searches when resolving a variable — from the current scope outward to the global scope.

**Q: What is the difference between `var`, `let`, and `const` in terms of scope?**
`var` is function-scoped (ignores blocks like `if`/`for`). `let` and `const` are block-scoped (each `{}` creates a new scope).

**Q: Why does the classic `var`-in-loop bug happen?**
All iterations share the same `var` binding, so every closure captures the same variable, which holds the final value after the loop.

**Q: How do closures enable private state?**
By declaring a variable in an outer function and returning inner functions that access it, the variable is inaccessible from outside but persists in memory.

**Q: Does each closure have its own copy of the captured variable?**
No — each closure captures a reference to the variable, not a copy. But each outer function call creates a new scope, so each returned closure has its own independent binding.

**Q: What keeps a closed-over variable from being garbage collected?**
As long as the inner function (the closure) is reachable, the engine keeps the outer variable alive because the function still references it.

**Q: What is the module pattern?**
A pattern where a function returns an object of methods that share access to private variables via closures, simulating a module with a controlled public API.

**Q: How are closures different from classes for encapsulation?**
Closures use function scope to create private state; classes use syntactic constructs (`#privateField`). Closures are lighter and need no `new`; classes support inheritance and multiple methods more naturally.

---

## Key Takeaways

- Scope controls visibility: a variable is only accessible within the block or function it was declared in.
- Scope is lexical — determined by where code is written, not where it runs.
- A closure is what happens when a function remembers the scope it was created in.
- Closed-over variables stay alive in memory as long as the function holding them is reachable.
- Each call to an outer function creates a new, independent closure — not shared state.
- The `var`/`let` difference matters most inside loops: `var` shares one binding, `let` creates one per iteration.
- Closures are the foundation of the module pattern, memoization, currying, and private state in JavaScript.

---

## Vocabulary

### Nouns (concepts)

**Scope** — the region of code where a variable is defined and accessible. In JavaScript, created by functions and blocks (`{}`).

**Scope chain** — the ordered lookup path JavaScript walks when resolving a variable name, from the current scope outward to global.

**Closure** — a function paired with the environment (scope) in which it was created; it retains references to variables from that environment.

**Lexical scope** — a scoping rule where variable visibility is determined at write time (by code structure), not at call time. JavaScript uses lexical scope.

**Execution context** — the runtime record of a function call: includes the function's local variables, `this`, and a reference to its outer scope.

**Environment record** — the internal data structure that holds variable bindings for a given scope.

**Module pattern** — a design pattern using a closure to expose a limited public API while keeping internal state private.

**Block scope** — scope created by any `{}` block (e.g. `if`, `for`, plain blocks); applies to `let` and `const` but not `var`.

**Function scope** — scope created by a function body; the scope that `var` declarations live in.

**Global scope** — the outermost scope; variables here are accessible everywhere in the program.

### Verbs (actions)

**Capture** — when a function retains a reference to a variable from an outer scope, it is said to capture that variable.

**Close over** — a function closes over a variable when it captures a reference to it from an enclosing scope.

**Hoist** — JavaScript moves `var` declarations (and function declarations) to the top of their scope before execution. `let`/`const` are hoisted but not initialized (temporal dead zone).

**Resolve** — looking up a variable name by walking the scope chain until a binding is found.

### Adjectives (properties)

**Lexical** — relating to the written structure of source code (as opposed to runtime behavior).

**Block-scoped** — a variable (declared with `let` or `const`) whose visibility is limited to the surrounding `{}` block.

**Function-scoped** — a variable (declared with `var`) whose visibility spans the entire enclosing function.

**Private** — a variable that is inaccessible from outside a given scope; in closures, enforced by not exposing the variable directly.

**Persistent** — a closed-over variable persists in memory beyond the lifetime of the outer function call that created it.
