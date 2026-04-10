# React Re-rendering Behavior

**Abstraction level**: library behavior / rendering model
**Category**: frontend architecture, UI component lifecycle

---

## Related Topics

- **Depends on this**: React.memo, useMemo, useCallback, React Profiler
- **Works alongside**: reconciliation, virtual DOM diffing, component tree structure
- **Contrast with**: Angular change detection, Vue reactivity system
- **Implementations of this**: React 18 concurrent rendering, React DevTools flame graph
- **Temporal neighbors**: Learn component lifecycle first; learn performance optimization after

---

## What is it

Re-rendering is React's process of re-executing a component function to produce updated UI output. When state or props change, React calls the component function again, computes a new virtual DOM tree, diffs it against the previous one, and updates only the parts of the real DOM that changed.

- **Data involved**: component state, props passed from parent, context values
- **Where it lives**: in memory — React maintains a virtual representation of the UI tree
- **Who triggers it**: state updates (`setState`/`useState`), prop changes, context updates, parent re-renders
- **How it changes**: React re-runs the component function from top to bottom on every render

A re-render does not always mean a DOM update. React re-renders (re-executes the function), then separately decides whether the DOM needs to change.

---

## What Problem Does It Solve

UI is a function of data. When data changes, the screen needs to reflect that change.

**Simple scenario**: A counter value is stored in state. When the user clicks a button, the count increments. Something needs to re-draw the number on screen.

**Without a system**:
- You manually call `element.innerText = count` after every update
- You forget to update one part of the UI that also depends on count
- Two parts of the UI show different values for the same data (inconsistency)
- You write imperative update logic scattered across event handlers

**As complexity grows**:
- Multiple components depend on shared data
- An update in one place needs to cascade to many places
- It becomes impossible to track what updated what and when
- Stale values appear in the UI

React solves this by making rendering **declarative and automatic**: describe what the UI should look like given current data, and React handles when and how to update the DOM.

---

## How Does It Solve It

### 1. Components are functions of their inputs

A component takes props and state as input and returns a description of the UI. When inputs change, the function re-runs and returns a new description.

```
render = f(state, props)
```

This is the core mental model. The output is always derived from current data.

### 2. Re-renders propagate downward

When a component re-renders, all of its children re-render by default — even if their own props did not change. React does not diff props before deciding to re-render; it re-renders the subtree and lets reconciliation handle what actually updates the DOM.

**Implication**: a re-render high in the tree can cause many components lower in the tree to re-execute.

### 3. State updates trigger re-renders at the owning component

Calling `setState` or the setter from `useState` schedules a re-render for that component and its children. React batches multiple state updates within the same event handler into a single render cycle (React 18 also batches in async contexts).

### 4. Reconciliation limits actual DOM changes

After re-rendering, React diffs the new virtual DOM tree against the previous one (reconciliation). Only elements that actually changed get updated in the real DOM. So re-rendering is cheap; DOM mutation is not — and React minimizes it.

### 5. Referential equality determines prop change

React compares props using `===` (strict equality). For primitives this is value comparison. For objects, arrays, and functions, two separately created instances are never equal even if they have the same contents. This is why passing `{}` or `() => {}` inline as a prop causes a child to see a "new" prop on every render.

---

## What If We Didn't Have It (Alternatives)

### Manual DOM manipulation

```js
document.getElementById('count').innerText = count;
```

Works for one element. Breaks as soon as the same data drives multiple parts of the UI. No coordination, no consistency guarantee.

### jQuery-style event binding

```js
$('#btn').on('click', function() {
  const count = parseInt($('#count').text()) + 1;
  $('#count').text(count);
  $('#summary').text('Total: ' + count); // easy to forget
});
```

Imperative updates are scattered. Missing one update causes stale UI. Impossible to audit what drives what.

### Global mutable variables with polling

```js
setInterval(() => {
  if (globalState.count !== lastRendered) {
    renderCount(globalState.count);
    lastRendered = globalState.count;
  }
}, 16);
```

Wastes cycles, causes flicker, creates race conditions, hard to extend.

**Why all of these fail at scale**: they require manual synchronization between data and UI. React automates this by making re-rendering a consequence of state change, not a separate imperative step.

---

## Examples

### Example 1 — Basic state update triggers re-render

```jsx
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

Clicking the button calls `setCount`. React re-renders `Counter`. The function runs again, `count` is now 1, and the button shows "1".

---

### Example 2 — Parent re-render causes child re-render

```jsx
function Parent() {
  const [value, setValue] = useState(0);
  return (
    <>
      <button onClick={() => setValue(v => v + 1)}>Update</button>
      <Child />
    </>
  );
}

function Child() {
  console.log('Child rendered');
  return <p>I am a child</p>;
}
```

Every time `Parent` re-renders, `Child` also re-renders — even though `Child` receives no props and its output never changes. This is the default behavior.

---

### Example 3 — Inline objects cause unnecessary re-renders

```jsx
// Bad: new object created on every Parent render
<Child style={{ color: 'red' }} />

// Better: defined outside or memoized
const style = { color: 'red' };
<Child style={style} />
```

In the first case, `style` is a new object reference on every render. Even `React.memo` cannot save `Child` from re-rendering because `{} !== {}`.

---

### Example 4 — Inline functions cause the same problem

```jsx
// Bad: new function reference on every render
<Child onClick={() => doSomething(id)} />

// Better: useCallback stabilizes the reference
const handleClick = useCallback(() => doSomething(id), [id]);
<Child onClick={handleClick} />
```

Without `useCallback`, the child sees a new `onClick` prop every render, defeating memoization.

---

### Example 5 — React.memo skips re-render when props are unchanged

```jsx
const Child = React.memo(function Child({ label }) {
  console.log('Child rendered');
  return <p>{label}</p>;
});
```

If `label` is the same string reference between renders, React skips re-rendering `Child`. This only works because strings are primitives and compare by value.

---

### Example 6 — State update with same value skips re-render

```jsx
const [count, setCount] = useState(0);
setCount(0); // count is already 0 — React bails out, no re-render
```

React uses `Object.is` to compare the new state to the old. If they are equal, the component does not re-render. This works for primitives; for objects you must create a new reference to trigger a re-render.

---

### Example 7 — Context triggers re-render in all consumers

```jsx
const ThemeContext = createContext('light');

function App() {
  const [theme, setTheme] = useState('light');
  return (
    <ThemeContext.Provider value={theme}>
      <DeepChild />
    </ThemeContext.Provider>
  );
}
```

When `theme` changes, every component that calls `useContext(ThemeContext)` re-renders — regardless of where it sits in the tree. Context does not diff; any change to the context value re-renders all consumers.

---

## Quickfire (Interview Q&A)

**Q: What triggers a re-render in React?**
A: A state update (`useState`/`setState`), a prop change, or a context value change.

**Q: Does re-rendering always update the DOM?**
A: No. React re-renders the component function but only updates the real DOM if the reconciled output differs from the previous render.

**Q: Why do children re-render when a parent re-renders?**
A: By default, React re-renders the entire subtree of a component that re-renders. React does not check child props before re-rendering.

**Q: What does React.memo do?**
A: It wraps a component and skips re-rendering if all props are shallowly equal to the previous render.

**Q: Why does passing an inline object as a prop break memoization?**
A: A new object is created on every render, so `===` comparison always returns false, making React think the prop changed.

**Q: What is reconciliation?**
A: The process where React compares the new virtual DOM tree against the previous one and computes the minimal set of real DOM mutations needed.

**Q: What does React batch?**
A: React batches multiple `setState` calls within the same event handler (and in React 18, also in async code) into a single re-render.

**Q: When does React bail out of a re-render entirely?**
A: When the new state value is `Object.is`-equal to the current state, React skips the re-render.

**Q: What is the difference between a render and a commit?**
A: The render phase runs component functions and produces a new virtual DOM; the commit phase applies the diff to the real DOM.

**Q: How does context differ from props in terms of re-rendering?**
A: Props re-render only the direct child; context re-renders every consumer in the tree when the context value changes.

**Q: What is the risk of over-memoizing?**
A: Memoization has its own cost (comparison work, memory). Wrapping every component in `React.memo` can add overhead without measurable benefit if re-renders are already cheap.

---

## Key Takeaways

- A re-render is React re-executing a component function — it is not the same as a DOM update.
- State changes trigger re-renders at the owning component and cascade down through all children by default.
- React uses `Object.is` to compare state and `===` to compare props; referential equality is what matters.
- Inline objects and functions create new references on every render, causing downstream components to see "changed" props even when the data is the same.
- Reconciliation is what keeps DOM updates minimal — re-rendering is deliberately cheap.
- `React.memo` prevents child re-renders only when props are shallowly stable; it fails when references change.
- Context re-renders all consumers unconditionally when its value changes — splitting contexts is the main mitigation.
- Understanding re-rendering is a prerequisite for understanding all React performance optimization tools.

---

## Vocabulary

### Nouns (concepts)

**Re-render**: The process of React calling a component function again to produce updated output. Happens when state, props, or context changes.

**Render phase**: The phase where React calls component functions and builds a new virtual DOM tree. Pure and side-effect-free in strict mode.

**Commit phase**: The phase where React applies the diff produced by reconciliation to the real DOM. Side effects (`useEffect`) run after this.

**Virtual DOM**: An in-memory JavaScript representation of the UI tree. React uses it to avoid expensive direct DOM manipulations.

**Reconciliation**: React's algorithm for diffing two virtual DOM trees and determining the minimal set of real DOM changes needed.

**Component tree**: The nested hierarchy of components that make up a React application. Re-renders propagate downward through this tree.

**Context consumer**: A component that calls `useContext` and re-renders whenever the context value changes.

**Referential equality**: Two values being `===` equal. For objects and functions, this requires them to be the same instance, not just the same shape.

**Bailout**: React's internal decision to skip re-rendering a component because its inputs have not changed.

**Batching**: Grouping multiple state updates into a single re-render cycle to avoid redundant renders.

### Verbs (actions)

**Re-render**: To re-execute a component function due to a change in state, props, or context.

**Reconcile**: To diff two virtual DOM trees and compute DOM mutations.

**Bail out**: To skip a re-render because state or props are unchanged.

**Memoize**: To cache a computed value or component output and reuse it when inputs have not changed.

**Propagate**: How re-renders flow from a parent component down to its children.

### Adjectives (properties)

**Stale**: Describing a value in the UI or in a closure that no longer reflects the current state of the data.

**Shallow**: A comparison that checks only the top-level keys and their values by reference, not deep equality.

**Pure**: A component whose output depends only on its inputs and has no side effects — a prerequisite for safe memoization.

**Referentially stable**: Describing a value (usually an object or function) whose reference does not change between renders, allowing `===` comparison to succeed.
