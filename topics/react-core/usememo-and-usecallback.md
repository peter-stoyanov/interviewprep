# React useMemo and useCallback

**Abstraction level**: language feature (React hooks)
**Category**: frontend performance optimization, React rendering model

---

## Related Topics

- **Depends on this**: memoized child components (`React.memo`), expensive derived data in UI
- **Works alongside**: `React.memo`, `useReducer`, virtualized lists
- **Contrast with**: premature optimization, plain variable declarations, `useEffect`
- **Temporal neighbors**: learn after React rendering basics, props, and `useState`; before advanced performance profiling

---

## What is it

`useMemo` and `useCallback` are React hooks that cache a value or function between renders. They both accept a computation and a dependency array, and only recompute when a dependency changes. Without them, every render recreates functions and computed values from scratch. They exist entirely to control when referential identity changes — not to change the logic itself.

- **Data**: memoized values (objects, arrays, numbers) and function references
- **Lives in**: component memory, managed by React's fiber tree
- **Who reads/writes**: the component that declares them, plus any child components that receive them as props
- **Changes over time**: recomputed only when listed dependencies change

---

## What problem does it solve

### The problem: renders create new references

React re-renders a component whenever state or props change. On each render, every `const` is re-evaluated. This means:

```js
const filtered = items.filter(x => x.active); // new array every render
const handleClick = () => doSomething(id);     // new function every render
```

These are new references on every render, even if the values are logically identical.

This becomes a problem in two scenarios:

**1. Expensive computations run unnecessarily**

If `filtered` involves sorting 10,000 items, recomputing on every keystroke (even ones unrelated to `items`) wastes CPU.

**2. Children re-render unnecessarily**

If a child component is wrapped in `React.memo` (skip re-render if props are equal), but the parent passes a new function reference on every render, the memo is bypassed — the child always re-renders because the prop is a new reference, even though the function body is identical.

Without a way to stabilize references, you cannot reliably prevent unnecessary renders.

---

## How does it solve it

### Principle 1: Cache the result of a computation (`useMemo`)

`useMemo` runs a function once and stores the return value. On the next render, if dependencies haven't changed, it returns the cached value instead of rerunning the function.

```js
const filtered = useMemo(() => items.filter(x => x.active), [items]);
```

The reference to `filtered` only changes when `items` changes. All other renders return the same object reference.

**What this controls**: referential stability of derived data.

### Principle 2: Cache a function reference (`useCallback`)

`useCallback` is the same mechanism, but for functions. Instead of caching a computed value, it caches the function itself.

```js
const handleClick = useCallback(() => doSomething(id), [id]);
```

`handleClick` is the same function reference across renders, as long as `id` hasn't changed.

**What this controls**: referential stability of event handlers and callbacks passed to children.

### The dependency array is the control surface

Both hooks accept a dependency array. React uses shallow equality (`===`) to compare each dependency on every render. If any dependency changed, the memo is invalidated and recomputed.

- Empty array `[]`: compute once, never recompute
- `[a, b]`: recompute only when `a` or `b` changes (by reference or value)
- No array: recompute on every render (pointless — do not do this)

---

## What if we didn't have it (Alternatives)

### Option 1: Plain variable (always recomputes)

```js
const filtered = items.filter(x => x.active);
```

Works fine if the component is cheap and has no memoized children. Breaks when the computation is expensive or the result is passed as a prop to a `React.memo` child.

### Option 2: Move logic outside the component

```js
const filterItems = (items) => items.filter(x => x.active);
```

Extracting pure functions avoids recreation of the function reference — the function itself is stable. But this doesn't cache the *result* of calling it. The filter still runs on every render.

### Option 3: Store derived data in state

```js
const [filtered, setFiltered] = useState([]);
useEffect(() => { setFiltered(items.filter(x => x.active)); }, [items]);
```

This works but adds unnecessary complexity: an extra state variable, a side effect, and an extra render cycle. `useMemo` is the correct tool for synchronous derived state.

### Option 4: Ignore the problem

For simple components that don't pass callbacks to memoized children, doing nothing is often correct. This is not always a problem — only optimize when you can measure the cost.

---

## Examples

### Example 1: useMemo — cached derived value

```js
const expensiveTotal = useMemo(() => {
  return cart.items.reduce((sum, item) => sum + item.price * item.qty, 0);
}, [cart.items]);
```

The total only recalculates when `cart.items` changes. Typing into an unrelated search input won't trigger the calculation.

---

### Example 2: useCallback — stable handler passed to a child

```js
// Parent
const handleDelete = useCallback((id) => {
  setItems(prev => prev.filter(item => item.id !== id));
}, []);

return <List onDelete={handleDelete} />;
```

```js
// Child (memoized)
const List = React.memo(({ onDelete }) => { ... });
```

Without `useCallback`, `List` re-renders on every parent render because `handleDelete` is a new function each time. With it, `List` only re-renders if `onDelete` actually changes.

---

### Example 3: Wrong dependency array — stale closure bug

```js
// BUG: count is stale inside the callback
const handleClick = useCallback(() => {
  console.log(count); // always logs initial value
}, []); // missing [count]
```

The function was created when `count` was 0. It closed over that value. React never recreates it because the dependency array is empty. The fix: include `count` in the array.

---

### Example 4: useMemo vs plain variable — when it doesn't matter

```js
// No benefit from useMemo here
const label = useMemo(() => `Hello, ${name}`, [name]);

// This is fine and simpler
const label = `Hello, ${name}`;
```

String interpolation is trivial. `useMemo` adds overhead (bookkeeping per render). Only memoize when the computation cost or reference instability is measurable.

---

### Example 5: Referential equality trap with objects

```js
// Each render creates a new options object
function Chart({ data }) {
  const options = { color: 'blue', animated: true }; // new ref every render

  return <ExpensiveChart data={data} options={options} />;
}
```

Even if `ExpensiveChart` is wrapped in `React.memo`, it re-renders every time because `options` is a new object. Fix:

```js
const options = useMemo(() => ({ color: 'blue', animated: true }), []);
```

---

### Example 6: useCallback for event handlers in lists

```js
const handleRemove = useCallback((id) => {
  dispatch({ type: 'REMOVE', id });
}, [dispatch]);

return items.map(item => (
  <Item key={item.id} onRemove={handleRemove} />
));
```

A single stable `handleRemove` is shared across all `Item` components. Without `useCallback`, each render produces a new function, causing all memoized `Item`s to re-render.

---

## Quickfire (Interview Q&A)

**What does useMemo do?**
It caches the return value of a function and only recomputes it when the listed dependencies change.

**What does useCallback do?**
It caches a function reference so it doesn't change on every render, useful when passing callbacks to memoized children.

**What's the difference between useMemo and useCallback?**
`useMemo` caches the result of calling a function. `useCallback` caches the function itself. `useCallback(fn, deps)` is equivalent to `useMemo(() => fn, deps)`.

**When should you use useMemo?**
When a computation is expensive, or when its result is passed as a prop to a memoized child and you need a stable reference.

**When should you use useCallback?**
When a function is passed as a prop to a memoized child or used as a dependency in another hook, and you want to avoid unnecessary re-renders or re-executions.

**What happens if you forget a dependency?**
The hook captures a stale closure — the function or computed value uses old variable values and won't update correctly.

**What's a stale closure?**
A function that closed over a variable's value at creation time and doesn't see later updates because it was never recreated.

**Does useMemo prevent all re-renders?**
No. The component still re-renders. `useMemo` only skips recomputing the memoized value and keeps the reference stable.

**Can you over-use useMemo and useCallback?**
Yes. They add memory overhead and bookkeeping cost. Wrapping every value is a net negative — only apply where you can measure a benefit.

**Why does React.memo need useCallback to work effectively?**
`React.memo` skips re-renders when props are shallowly equal. A function prop is a new reference on every render unless wrapped in `useCallback`, so memo's check always fails without it.

**What does the empty dependency array mean?**
Compute once on mount and never recompute. The memoized value is stable for the lifetime of the component.

---

## Key Takeaways

- `useMemo` and `useCallback` are tools for controlling **referential stability** — they prevent unnecessary new references on every render.
- They do not prevent re-renders on their own; they make props stable so that `React.memo` can skip child re-renders.
- Both use a dependency array with shallow (`===`) comparison to decide when to recompute.
- Stale closures are the main bug: forgetting a dependency means the hook uses an outdated value.
- `useCallback(fn, deps)` is just `useMemo(() => fn, deps)` — same mechanism, different return type.
- Do not add these hooks by default. Measure first — they have overhead, and most components don't need them.
- The real value emerges in three cases: expensive computations, callbacks passed to `React.memo` children, and values used as dependencies in other hooks.

---

## Vocabulary

### Nouns (concepts)

**Memoization**: a caching technique where the result of a computation is stored and reused when the same inputs are seen again, avoiding redundant work.

**Referential equality**: two variables are referentially equal (`===`) if they point to the same object in memory. Two objects with identical contents are not referentially equal unless they are the same reference.

**Dependency array**: the second argument to `useMemo`, `useCallback`, and `useEffect`; a list of values React watches to decide when to rerun the hook.

**Stale closure**: a function that captured a variable's value at creation time and still holds the old value because the function was never recreated.

**Derived data**: data computed from other state or props rather than stored independently. Filtering, sorting, or aggregating a list are examples.

**React.memo**: a higher-order component that wraps a child and skips re-rendering if its props are shallowly equal to the previous render.

**Fiber tree**: React's internal data structure that tracks components, their state, and memoized hook values between renders.

### Verbs (actions)

**Memoize**: to cache a value or function reference so it is reused on subsequent renders without recomputation.

**Invalidate**: to mark a cached value as outdated, forcing recomputation on the next render. Happens when a dependency changes.

**Stabilize**: to keep a reference the same across renders so that downstream consumers don't see a change.

**Close over**: when a function captures a variable from its enclosing scope at the time of creation, forming a closure.

### Adjectives (properties)

**Stable**: a reference or value that does not change between renders, enabling reliable equality checks.

**Stale**: a cached value or reference that is outdated because an upstream dependency changed but the cache was not invalidated.

**Shallow**: a comparison that checks only the top-level reference (`===`), not deep equality of nested structures.

**Expensive**: a computation that takes measurable time or resources — the primary justification for memoization.
