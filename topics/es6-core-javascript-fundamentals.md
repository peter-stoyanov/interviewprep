# ES6+ and Core JavaScript Fundamentals

- **Abstraction level**: language feature set / syntax evolution
- **Category**: programming language fundamentals

---

## Related Topics

- **Depends on this**: async/await patterns, React component logic, Node.js module system
- **Works alongside**: TypeScript (type layer on top of ES6+), Babel (transpilation), bundlers (Webpack/Vite)
- **Contrast with**: CommonJS (older module system), ES5 (callback-heavy patterns, `var` scoping)
- **Temporal neighbors**: learn closures and the event loop before; learn Promises and async/await after

---

## What Is It

ES6 (ECMAScript 2015) and subsequent yearly releases (ES7, ES8, ...) are versioned updates to the JavaScript language specification. Each version adds new syntax and built-in behaviors on top of the core language runtime.

The additions are not new runtime engines — they compile down to the same JS engine. They are new ways to write and organize data, control scope, and express transformations.

- **What data**: variables, functions, objects, arrays, asynchronous values
- **Where it lives**: in-memory, in the browser or Node.js runtime
- **Who reads/writes**: the developer's code and the JS engine
- **How it changes**: variables change through assignment; objects mutate through property access; ES6 gives you tools to control these flows more explicitly

---

## What Problem Does It Solve

Pre-ES6 JavaScript had several recurring pain points:

**Scope leakage with `var`**: `var` is function-scoped, not block-scoped. Loops and conditionals didn't create isolated scopes, causing bugs.

**Verbose object and function syntax**: defining methods, copying objects, and destructuring required many lines of boilerplate.

**No native module system**: code was organized via IIFEs or globals, making dependency management brittle.

**Callback hell**: asynchronous code nested callbacks three or four levels deep, making error handling and sequencing hard to follow.

**Prototype-based inheritance with confusing syntax**: constructors and `Object.create` worked, but were error-prone and hard to read.

Without ES6+:
- Variables leaked into outer scopes unexpectedly
- Sharing and composing data required verbose workarounds
- Async logic became deeply nested and hard to trace
- Modules required third-party tooling or globals

---

## How Does It Solve It

### 1. Block scoping with `let` and `const`

`let` and `const` are block-scoped. They exist only within the `{}` block they're declared in.

- `const`: the binding cannot be reassigned (the value itself may still mutate if it's an object)
- `let`: the binding can be reassigned, but stays scoped to its block

This limits where data can be read or written — making ownership explicit.

### 2. Arrow functions and `this` binding

Arrow functions don't have their own `this`. They inherit `this` from the enclosing lexical scope.

This matters for callbacks: the `this` inside a regular callback function is usually wrong. Arrow functions fix this without needing `.bind()`.

### 3. Destructuring

Destructuring extracts values from objects and arrays into named variables in one step. It makes data flow explicit: you name exactly which fields you care about.

### 4. Spread and rest operators

- **Spread** (`...array`): expands an iterable into individual values — used for copying, merging, passing args
- **Rest** (`...rest`): collects remaining values into an array — used in function signatures

These are transformations: they convert between one structure (array/object) and multiple values, or vice versa.

### 5. Template literals

Backtick strings allow embedded expressions (`${expr}`) and multi-line strings. They eliminate string concatenation, keeping data and presentation together.

### 6. Default parameters

Functions can declare default values for parameters. This avoids `param = param || default` guards inside the function body.

### 7. Classes

`class` syntax wraps prototype-based inheritance in a familiar structure. Constructor, methods, and inheritance (`extends`) are declared in one block. The underlying mechanism is still prototypes — `class` is syntactic sugar.

### 8. Modules (`import`/`export`)

ES6 modules give each file its own scope. Exports are explicit; imports are explicit. This is static — the bundler can analyze imports at build time (enables tree-shaking).

### 9. Promises and async/await

Promises represent a future value: pending → fulfilled or rejected. `async/await` lets you write asynchronous code that reads like synchronous code. The data still flows asynchronously; the syntax just flattens it.

### 10. Array and object utilities

`Array.prototype.map`, `filter`, `reduce`, `find`, `some`, `every` — these are transformation functions: they take data in, return data out, without mutating the original.

`Object.assign` and spread (`{...obj}`) create shallow copies.

---

## What If We Didn't Have It (Alternatives)

### Scope management without `let`/`const`

```js
// ES5: var leaks out of blocks
for (var i = 0; i < 3; i++) {}
console.log(i); // 3 — leaked

// Workaround: IIFE to create scope
(function() {
  var x = 1;
})();
```

This works but is noisy and easy to forget.

### Object copying without spread

```js
// ES5: verbose
var copy = Object.assign({}, original, { name: 'new' });

// ES6+: clean
const copy = { ...original, name: 'new' };
```

### Async without Promises

```js
// Callback hell — each step nests inside the last
getUser(id, function(user) {
  getOrders(user.id, function(orders) {
    getItems(orders[0].id, function(items) {
      // buried three levels deep
    });
  });
});
```

Error handling had to be repeated at each level. With Promises and `async/await`, the chain flattens.

### Modules without ES6

```js
// Global namespace pattern — fragile
window.MyLib = (function() {
  return { doThing: function() {} };
})();
```

Any naming collision in the global scope breaks things silently.

---

## Examples

### Example 1: `var` vs `let` scope

```js
// var: block doesn't create scope
for (var i = 0; i < 3; i++) {}
console.log(i); // 3

// let: scoped to the block
for (let j = 0; j < 3; j++) {}
console.log(j); // ReferenceError
```

### Example 2: Arrow function and `this`

```js
function Timer() {
  this.count = 0;

  // Regular function: `this` is lost inside the callback
  setInterval(function() {
    this.count++; // `this` is window/undefined
  }, 1000);

  // Arrow function: `this` is Timer's instance
  setInterval(() => {
    this.count++; // works correctly
  }, 1000);
}
```

### Example 3: Destructuring

```js
const user = { name: 'Ana', age: 28, role: 'admin' };

// Instead of:
const name = user.name;
const role = user.role;

// Use:
const { name, role } = user;

// With rename:
const { name: userName } = user; // userName = 'Ana'

// Array destructuring:
const [first, , third] = [10, 20, 30]; // first=10, third=30
```

### Example 4: Spread for immutable updates

```js
const state = { count: 0, user: 'Ana' };

// Add/override a key without mutating:
const next = { ...state, count: 1 };

// state is unchanged — new object created
```

### Example 5: Default parameters

```js
// ES5:
function greet(name) {
  name = name || 'Guest';
  return 'Hello ' + name;
}

// ES6:
function greet(name = 'Guest') {
  return `Hello ${name}`;
}
```

### Example 6: Promise chain vs async/await

```js
// Promise chain
fetch('/api/user')
  .then(res => res.json())
  .then(user => fetch(`/api/orders/${user.id}`))
  .then(res => res.json())
  .catch(err => console.error(err));

// async/await — same flow, flat structure
async function loadOrders() {
  try {
    const res = await fetch('/api/user');
    const user = await res.json();
    const ordersRes = await fetch(`/api/orders/${user.id}`);
    return ordersRes.json();
  } catch (err) {
    console.error(err);
  }
}
```

### Example 7: Array transformation methods

```js
const users = [
  { name: 'Ana', active: true },
  { name: 'Bob', active: false },
];

const activeNames = users
  .filter(u => u.active)
  .map(u => u.name);
// ['Ana']
```

Data in → transformed data out. Original array unchanged.

### Example 8: ES6 module system

```js
// math.js
export function add(a, b) { return a + b; }
export const PI = 3.14;

// main.js
import { add, PI } from './math.js';
```

Each file is its own scope. No globals shared. Bundlers can remove unused exports (tree-shaking).

---

## Quickfire (Interview Q&A)

**Q: What is the difference between `var`, `let`, and `const`?**
`var` is function-scoped and hoisted with `undefined`; `let` and `const` are block-scoped. `const` cannot be reassigned; `let` can.

**Q: Why do arrow functions not have their own `this`?**
Arrow functions capture `this` from their enclosing lexical scope at definition time, not from how they are called.

**Q: What does `const` actually prevent?**
It prevents reassignment of the variable binding, not mutation of the value. A `const` object's properties can still be changed.

**Q: What is destructuring?**
A syntax for extracting values from arrays or objects into named variables in a single expression.

**Q: What is the difference between spread and rest?**
Spread expands an iterable into individual values; rest collects remaining values into an array. Same syntax (`...`), opposite directions.

**Q: What is a Promise?**
An object representing a value that may be available now, in the future, or never — with three states: pending, fulfilled, rejected.

**Q: What does `async/await` do under the hood?**
It is syntactic sugar over Promises. An `async` function always returns a Promise; `await` pauses execution until the Promise settles.

**Q: What is the difference between `map` and `forEach`?**
`map` returns a new array of transformed values; `forEach` returns `undefined` and is used only for side effects.

**Q: What is a closure?**
A function that retains access to variables from its enclosing scope even after that scope has returned.

**Q: What is the difference between ES6 modules and CommonJS?**
ES6 modules use `import`/`export`, are statically analyzed, and natively supported in browsers. CommonJS uses `require`/`module.exports`, is dynamic, and is the default in Node.js.

**Q: What is `typeof null`?**
It returns `"object"` — a known bug in JavaScript from its original implementation that was never fixed for backward compatibility.

**Q: What is the difference between `==` and `===`?**
`==` performs type coercion before comparison; `===` checks value and type without coercion. Prefer `===`.

---

## Key Takeaways

- `let` and `const` confine data to where it's needed — reduce scope = reduce bugs
- Arrow functions fix `this` by binding it lexically, not dynamically
- Destructuring makes data flow explicit: you declare what you extract
- Spread creates shallow copies — safe for immutable updates to objects and arrays
- Promises and async/await flatten asynchronous data flow into readable sequences
- `map`, `filter`, `reduce` transform arrays without mutation — data in, data out
- ES6 modules make dependencies explicit and static — each file owns its own scope
- Classes are syntax sugar over prototypes — the underlying model hasn't changed

---

## Vocabulary

### Nouns (Concepts)

**Scope**: the region of code where a variable is accessible. `var` is function-scoped; `let`/`const` are block-scoped.

**Closure**: a function that captures and retains access to variables from its outer scope even after that scope has exited.

**Hoisting**: the JS engine's behavior of moving variable and function declarations to the top of their scope before execution. `var` is hoisted as `undefined`; `let`/`const` are hoisted but not initialized (temporal dead zone).

**Temporal dead zone (TDZ)**: the period between a `let`/`const` declaration being hoisted and its line being executed — accessing the variable in this period throws a ReferenceError.

**Promise**: an object representing the eventual completion or failure of an asynchronous operation. Has three states: pending, fulfilled, rejected.

**Prototype chain**: the mechanism by which JavaScript objects inherit properties and methods from other objects. `class` syntax wraps this.

**Module**: a file with its own scope that explicitly exports and imports values. ES6 modules are statically analyzable.

**Destructuring**: a syntax for unpacking values from arrays or objects into individual variables.

**Spread operator**: `...` used to expand an iterable (array/object) into individual elements or properties.

**Rest parameter**: `...` used in a function signature to collect all remaining arguments into an array.

**Template literal**: a string delimited by backticks that allows embedded expressions (`${expr}`) and multi-line content.

**Tree-shaking**: a bundler optimization that removes unused exports from ES6 modules, reducing bundle size.

**Coercion**: automatic type conversion JavaScript performs during comparisons or operations (e.g., `"1" == 1` is `true`).

### Verbs (Actions)

**Destructure**: extract named fields from an object or array in one expression.

**Spread**: expand an iterable into individual values.

**Await**: pause execution of an `async` function until a Promise resolves.

**Export / Import**: make a value available from a module / bring a value in from a module.

**Resolve / Reject**: the two ways a Promise settles — success or failure.

### Adjectives (Properties)

**Block-scoped**: a variable whose visibility is limited to the block (`{}`) it was declared in.

**Lexical**: determined by where code is written, not where it is called. Arrow function `this` is lexically bound.

**Immutable**: a value that cannot be changed. `const` does not make values immutable — it makes bindings immutable.

**Asynchronous**: an operation that does not block execution while waiting for a result.

**Static (module)**: imports and exports are resolved at parse/build time, not at runtime.

**Shallow (copy)**: a copy that duplicates top-level properties only — nested objects still share references.
