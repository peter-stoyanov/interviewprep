# Immutability vs Mutation

- **Abstraction level**: concept / language feature
- **Category**: data modeling, state management, correctness

---

## Related Topics

- **Depends on this**: state management in SPAs, React rendering model, Redux
- **Works alongside**: pure functions, referential equality, structural sharing
- **Contrast with**: in-place updates, mutable data structures
- **Temporal neighbors**: closures and scope (before), state management patterns (after)

---

## What is it

Mutation means changing a value in place — modifying the same object or array that already exists in memory. Immutability means never changing a value in place — instead, producing a new value with the change applied.

In concrete terms:
- **Data**: objects, arrays, primitives
- **Where it lives**: memory (heap for objects/arrays, stack for primitives)
- **Who reads/writes it**: any code that holds a reference to the value
- **How it changes**: with mutation, the same reference reflects the new value; with immutability, a new reference is created and the old one is left untouched

Primitives in JavaScript (numbers, strings, booleans) are always immutable. Objects and arrays are mutable by default.

---

## What problem does it solve

### Simple scenario

You have a user object:

```js
const user = { name: "Alice", age: 30 };
```

Multiple parts of your app hold a reference to `user`. One part updates the age:

```js
user.age = 31; // mutates the original
```

Now every part of the app that holds that reference sees the changed value — even parts that did not expect it to change. This is **implicit shared state**.

### How complexity grows

- A component renders based on `user`. It cached the old value to compare. The comparison says "same object" — so it does not re-render, even though the data changed.
- A function receives `user`, modifies it, and the caller's data is silently changed.
- A bug appears: the user object was modified somewhere, but you cannot tell where, when, or by what.

### Failure modes

- **Hidden coupling**: any function with a reference can change data that others depend on
- **Unpredictable state**: the same reference may hold different values at different times
- **Broken equality checks**: `prev === next` returns `true` even when the data is logically different (shallow reference equality)
- **Difficult debugging**: mutations can happen anywhere; tracking the source requires full program trace

---

## How does it solve it

### 1. Ownership is explicit

When data cannot be mutated, no function can silently change another's data. The only way to "change" something is to return a new value — making the transformation visible in the call chain.

### 2. Change is detectable by reference

```js
const a = { x: 1 };
const b = { ...a, x: 2 }; // new object

a === b; // false — change is detectable
```

Immutability makes equality checks cheap and reliable. If the reference is the same, the data is the same.

### 3. Time is preserved

Old versions of data are not destroyed. You can keep a history of previous states because no state was overwritten.

### 4. Functions become predictable

A function that does not mutate its inputs is a **pure function**. Given the same input, it always returns the same output. This makes functions easy to test, reason about, and compose.

---

## What if we didn't have it (Alternatives)

### Direct mutation

```js
function addItem(cart, item) {
  cart.items.push(item); // mutates the original
  return cart;
}
```

The caller's `cart` is now changed, even if it did not expect to be. Any other reference to that cart in the app is also changed.

### Object assign without discipline

```js
const updated = Object.assign(cart, { total: 99 }); // mutates cart
```

`Object.assign` with the target as the first argument mutates in place. A common mistake.

### Shared mutable state across components

```js
const sharedState = { count: 0 };

// Component A
sharedState.count++;

// Component B reads sharedState.count — gets unexpected value
```

Any component can overwrite any other's assumptions. At scale, the source of a change becomes impossible to trace.

---

## Examples

### Example 1 — Mutation vs immutability side by side

```js
// Mutation
const arr = [1, 2, 3];
arr.push(4); // arr is now [1, 2, 3, 4]

// Immutability
const arr = [1, 2, 3];
const next = [...arr, 4]; // arr is still [1, 2, 3], next is [1, 2, 3, 4]
```

### Example 2 — Object update

```js
// Mutation
user.age = 31;

// Immutable
const updatedUser = { ...user, age: 31 };
```

The spread operator copies all existing properties and overrides `age`. The original `user` is unchanged.

### Example 3 — Reference equality and rendering

In a UI framework that uses reference equality to decide whether to re-render:

```js
// Mutation — reference unchanged, no re-render triggered
state.count = state.count + 1;
render(state); // framework sees same reference, skips

// Immutability — new reference, re-render triggered
const next = { ...state, count: state.count + 1 };
render(next); // framework sees new reference, re-renders
```

### Example 4 — Detecting change in a list

```js
const prev = [1, 2, 3];
const next = [...prev, 4];

prev === next; // false — change detected cheaply
```

Without immutability, you would need to deep-compare every element.

### Example 5 — History (undo/redo)

```js
const history = [];

function applyChange(state, change) {
  history.push(state); // save old state
  return { ...state, ...change }; // return new state
}

// Undo
const previous = history.pop();
```

Because old states were never mutated, they are still intact in history.

### Example 6 — Accidental mutation bug

```js
function formatUser(user) {
  user.name = user.name.toUpperCase(); // mutates the original
  return user;
}

const alice = { name: "Alice" };
formatUser(alice);
console.log(alice.name); // "ALICE" — unintended
```

Fix: `return { ...user, name: user.name.toUpperCase() }`.

---

## Quickfire (Interview Q&A)

**Q: What is mutation?**
Modifying a value in place — changing an object or array that already exists in memory, affecting all references to it.

**Q: What is immutability?**
Never changing a value in place — instead, creating a new value with the desired change applied.

**Q: Are JavaScript primitives mutable?**
No. Strings, numbers, and booleans are always immutable in JavaScript.

**Q: Why does immutability make equality checks cheap?**
With immutable data, if two references are the same, the data is guaranteed to be the same. You do not need to deep-compare contents.

**Q: What is a pure function?**
A function that does not mutate its inputs and returns the same output for the same input every time.

**Q: How does immutability help with debugging?**
Because data is never changed in place, you always know where a new value came from — the function that returned it. Mutations can come from anywhere.

**Q: What is structural sharing?**
An optimization where immutable data structures share unchanged parts between the old and new version, avoiding full copies.

**Q: What array methods mutate in place?**
`push`, `pop`, `splice`, `sort`, `reverse`. Non-mutating alternatives: `concat`, `slice`, `filter`, `map`, spread.

**Q: What does `Object.freeze` do?**
It prevents mutation of an object's properties at runtime. It is shallow — nested objects are not frozen.

**Q: Why does immutability matter in UI frameworks like React?**
React uses reference equality to decide when to re-render. Immutability ensures that a changed value always has a new reference, making change detection correct and efficient.

**Q: What is the cost of immutability?**
Creating new objects on every change uses more memory and involves garbage collection. For most apps this is negligible; for high-frequency updates (e.g. game loops), it may matter.

---

## Key Takeaways

- Mutation changes a value in place; immutability produces a new value with the change applied.
- Mutating shared objects creates hidden coupling — any code with a reference can silently affect others.
- Immutability makes change detectable by reference: a new reference means the data changed.
- Pure functions depend on immutability — they cannot mutate inputs and must return new values.
- Immutability preserves history — old values are not destroyed.
- JavaScript objects and arrays are mutable by default; discipline or tooling is required to enforce immutability.
- The cost of immutability (extra allocations) is usually negligible compared to the debugging cost of unconstrained mutation.

---

## Vocabulary

### Nouns (concepts)

**Mutation**: The act of changing an existing value in memory. In JavaScript, this applies to objects and arrays. The same reference reflects the updated value after mutation.

**Immutability**: The property of a value that cannot be changed after creation. To "change" an immutable value, you produce a new one.

**Reference**: A pointer to a location in memory where an object or array lives. Two variables can hold references to the same object.

**Pure function**: A function that produces no side effects and always returns the same output for the same input. Requires that inputs are not mutated.

**Side effect**: Any change a function makes to state outside its own scope — including mutating its arguments or global variables.

**Structural sharing**: A technique used by immutable data structure libraries to share unchanged parts between old and new versions, reducing memory usage.

**Shallow copy**: A copy where top-level properties are duplicated but nested objects are still shared by reference (e.g. spread operator `{...obj}`).

**Deep copy**: A copy where all nested objects are also duplicated, creating a fully independent value.

**Referential equality**: Comparing two values by checking if they point to the same memory address (`===` for objects). Immutability makes this a reliable proxy for value equality.

### Verbs (actions)

**Mutate**: To change a value in place. E.g. `arr.push(x)` mutates `arr`.

**Freeze**: To prevent further mutation of an object using `Object.freeze()`.

**Spread**: To copy properties or elements into a new object or array using the `...` syntax — a common immutable update pattern.

**Derive**: To compute a new value from an existing one without altering the original.

### Adjectives (properties)

**Mutable**: Able to be changed in place. Arrays and objects in JavaScript are mutable by default.

**Immutable**: Cannot be changed after creation. Produces a new value on every "change".

**Shallow**: Applies only to the top level of a structure; nested values may still be shared or mutable.

**Pure**: Describes a function that has no side effects and does not mutate its inputs.

**Frozen**: An object that has had `Object.freeze()` applied and cannot have its properties changed.
