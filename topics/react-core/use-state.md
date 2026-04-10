# React useState

- **Abstraction level**: library API / language feature (React Hook)
- **Category**: component-level state management, React runtime

---

## Related Topics

- **Depends on this**: derived state, controlled components, lifting state up
- **Works alongside**: useEffect (reacting to state changes), useReducer (complex state logic), useContext (shared state)
- **Contrast with**: useReducer (explicit action model), props (read-only, passed down), useRef (mutable but no re-render)
- **Temporal neighbors**: learn props before this; learn useReducer and useContext after

---

## What is it

`useState` is a React Hook that lets a function component declare a piece of local state — a value that persists between renders and, when updated, causes the component to re-render.

Without it, a function component is pure and stateless: it receives inputs (props) and returns output (JSX). `useState` breaks that purity in a controlled way, letting a component remember data across renders.

- **What data**: any JavaScript value — string, number, boolean, array, object
- **Where it lives**: in React's internal memory (the fiber tree), scoped to a component instance
- **Who reads/writes it**: only the component that declared it (and its children via props)
- **How it changes**: only through the setter function returned by `useState`

---

## What problem does it solve

A UI often needs to remember things. A counter needs to know its current count. A form needs to know what the user has typed. A dropdown needs to know if it is open.

Without state, every render starts from zero. The component cannot remember what happened before.

### What goes wrong without it

**Using a plain variable:**

```js
let count = 0;

function Counter() {
  return <button onClick={() => count++}>{count}</button>;
}
```

`count` increments, but React does not know anything changed. The component never re-renders. The UI is stuck.

**Using module-level state:**

```js
let count = 0; // outside component

function Counter() { ... }
```

Now every instance of `Counter` shares the same variable. Two counters on the page interfere with each other.

**Core failure modes:**

- UI does not update when data changes
- Multiple component instances share state they should not
- State changes are invisible to React — it cannot schedule a re-render

---

## How does it solve it

### 1. Declare state explicitly

```js
const [count, setCount] = useState(0);
```

React stores `count` in memory tied to this specific component instance. The initial value (`0`) is used only on the first render.

### 2. Force re-renders through the setter

When you call `setCount(newValue)`, React:
1. Stores the new value
2. Schedules a re-render of this component
3. On the next render, returns the new value from `useState`

The setter is the only valid way to change state. This gives React full control over when and how the UI updates.

### 3. Isolate state per instance

Each instance of a component gets its own state slot. Two `<Counter />` elements each have their own `count`, stored separately.

### 4. State is a snapshot

During a single render, `count` is a fixed value — not a live reference. Closures capture the value from the render they belong to.

---

## What if we didn't have it (Alternatives)

### Class component `this.state`

```js
class Counter extends React.Component {
  state = { count: 0 };
  render() {
    return <button onClick={() => this.setState({ count: this.state.count + 1 })}>
      {this.state.count}
    </button>;
  }
}
```

Works, but requires classes, `this` binding, and more boilerplate. `useState` is the function-component equivalent.

### useRef for mutable values

```js
const count = useRef(0);
count.current++;
```

Mutations are immediate, but React does not re-render. Valid for values you want to track without affecting the UI (e.g. a timer ID), but not for values that drive rendering.

### External variable (wrong)

```js
let count = 0;
```

Changes are invisible to React. UI never updates.

---

## Examples

### Example 1 — Minimal: toggle a boolean

```js
function Toggle() {
  const [on, setOn] = useState(false);
  return <button onClick={() => setOn(!on)}>{on ? 'ON' : 'OFF'}</button>;
}
```

One piece of state, one setter call. React re-renders on each click.

---

### Example 2 — Functional update form

When the new state depends on the previous state, use a function:

```js
setCount(prev => prev + 1);
```

This is safer than `setCount(count + 1)` in async contexts, because `prev` is guaranteed to be the latest value, not the stale closure value.

---

### Example 3 — Object state

```js
const [user, setUser] = useState({ name: '', age: 0 });

// Wrong — mutating the object directly:
user.name = 'Alice'; // React does not know

// Right — replace the whole object:
setUser({ ...user, name: 'Alice' });
```

React uses reference equality to detect changes. Mutating the existing object does not trigger a re-render. Always produce a new object.

---

### Example 4 — Stale closure (common bug)

```js
const [count, setCount] = useState(0);

useEffect(() => {
  const id = setInterval(() => {
    setCount(count + 1); // count is always 0 — stale closure
  }, 1000);
  return () => clearInterval(id);
}, []);
```

Fix:

```js
setCount(prev => prev + 1); // always uses latest value
```

---

### Example 5 — Controlled input (data flows both ways)

```js
const [text, setText] = useState('');

return <input value={text} onChange={e => setText(e.target.value)} />;
```

The input is controlled: React owns the value. The `value` prop makes it a one-way flow from state to DOM. The `onChange` handler closes the loop by updating state.

---

### Example 6 — Initial state from a function (lazy initialization)

```js
const [data, setData] = useState(() => JSON.parse(localStorage.getItem('data') ?? '{}'));
```

When the initial value is expensive to compute, pass a function. React calls it only on the first render, not on every re-render.

---

## Quickfire (Interview Q&A)

**What does useState return?**
An array of two items: the current state value and a setter function to update it.

**What happens when you call the setter?**
React schedules a re-render of the component. On the next render, `useState` returns the new value.

**Why not just use a plain variable?**
Plain variable changes are invisible to React — it has no way to know a re-render is needed.

**Is state updated immediately after calling the setter?**
No. State updates are asynchronous and batched. The current render's `count` does not change mid-render; the new value is available on the next render.

**What is the difference between `setCount(count + 1)` and `setCount(prev => prev + 1)`?**
The function form receives the latest state value, avoiding stale closure bugs when multiple updates happen in the same render cycle or inside async callbacks.

**Does each component instance get its own state?**
Yes. State is scoped to a component instance, not shared across instances.

**What happens if you call the setter with the same value?**
React bails out and skips the re-render (using `Object.is` comparison).

**Can you store any type of value in useState?**
Yes — primitives, objects, arrays, null, functions. For objects and arrays, you must replace (not mutate) the value to trigger a re-render.

**What is the lazy initializer pattern?**
Passing a function to `useState(() => expensiveCompute())` so the initial value is computed once, not on every render.

**What is the difference between useState and useRef?**
`useState` causes a re-render when updated; `useRef` does not. Use `useRef` for values that need to persist but do not affect the UI.

**What is a controlled component?**
A form element whose value is driven by React state rather than the DOM's internal state.

---

## Key Takeaways

- `useState` lets a function component remember a value across renders
- The setter is the only valid way to change state — direct mutation does nothing
- Calling the setter tells React to re-render; the new value is available on the next render
- State updates are asynchronous and batched within an event handler
- Use the functional update form (`prev => ...`) when the new value depends on the old value
- For objects and arrays, always produce a new reference — React uses reference equality to detect changes
- Each component instance has its own isolated state slot

---

## Vocabulary

### Nouns (concepts)

**State** — data stored by React that persists between renders and drives the UI. Changing it causes a re-render.

**Hook** — a function starting with `use` that lets function components access React features like state and lifecycle. `useState` is the most fundamental hook.

**Setter function** — the second return value of `useState`. Calling it with a new value schedules a re-render and replaces the stored state.

**Re-render** — React calling the component function again to produce a new JSX tree after state changes.

**Snapshot** — during a render, state values are fixed. Closures capture that snapshot. This is why stale closure bugs occur.

**Stale closure** — a closure that captured an old value of state from a previous render, causing it to operate on outdated data.

**Controlled component** — a form element where React state is the source of truth for the element's value, controlled via the `value` prop and an `onChange` handler.

**Lazy initializer** — a function passed to `useState` that computes the initial value once on mount, avoiding repeated computation on re-renders.

**Batching** — React grouping multiple `setState` calls from the same event into a single re-render for performance.

### Verbs (actions)

**Declare state** — calling `useState(initialValue)` to register a state slot for this component instance.

**Update state** — calling the setter function with a new value to trigger a re-render.

**Mutate** — modifying an object or array in place. React cannot detect this; always produce a new reference instead.

**Bail out** — React skipping a re-render when the new state value is the same as the current value (via `Object.is`).

### Adjectives (properties)

**Asynchronous** — state updates do not take effect immediately within the current render; they are applied before the next render.

**Isolated** — each component instance maintains its own independent state, not shared with other instances.

**Immutable** — state should be treated as read-only; updates replace the value rather than modifying it in place.
