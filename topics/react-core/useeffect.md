# React useEffect

**Abstraction level**: language feature / hook (React API)
**Category**: frontend lifecycle management, React

---

## Related Topics

- **Depends on this**: custom hooks, data fetching patterns, subscriptions
- **Works alongside**: useState, useRef, useCallback, useLayoutEffect
- **Contrast with**: useLayoutEffect (synchronous, before paint), class lifecycle methods (componentDidMount, componentDidUpdate, componentWillUnmount)
- **Temporal neighbors**: Learn useState first; learn useReducer and custom hooks after

---

## What is it

`useEffect` is a React hook that lets you run code in response to a component rendering — specifically, code that reaches outside the React rendering system (DOM manipulation, network requests, timers, subscriptions). It runs after the browser has painted the screen. You give it a function, and React calls that function after each render where the specified dependencies have changed. The function can optionally return a cleanup function that React calls before the next run or when the component unmounts.

- **Data involved**: external state (server data, DOM nodes, timers, subscriptions)
- **Lives in**: the function component's execution context; side effects touch the browser or network
- **Who reads/writes it**: React controls when it runs; your code defines what happens
- **Changes over time**: re-runs whenever listed dependencies change

---

## What problem does it solve

React's rendering model is a pure function: given props and state, return UI. But real apps need to do things outside that loop: fetch data, set up event listeners, start timers, sync with external systems.

Without a controlled mechanism, you face these problems:

**Running code at the wrong time**: calling `fetch()` directly in the component body runs on every render, including re-renders triggered by unrelated state changes.

**Memory leaks**: subscribing to a WebSocket or setting an interval without unsubscribing means the subscription lives on even after the component is gone.

**Stale references**: reading props or state inside a callback defined at mount time captures old values — the callback never sees updates.

**No cleanup**: without a teardown step, effects pile up. Each render starts a new timer but none are cancelled.

`useEffect` gives you a structured place to run these operations, control when they re-run, and clean up after themselves.

---

## How does it solve it

### 1. Deferred execution (run after render, not during)

React renders the UI first, commits it to the DOM, then calls effects. Your side effect does not block the paint. This means your component renders correctly even before async data arrives.

### 2. Dependency array (control when it re-runs)

The second argument to `useEffect` is an array of values React watches.

- `[]` — run once after mount, never again
- `[id]` — run after mount and whenever `id` changes
- no array — run after every render (rarely what you want)

This maps directly to: "re-run this effect only when this data changes."

### 3. Cleanup function (teardown before next run or unmount)

Returning a function from the effect body tells React: "before running this effect again, or before this component leaves the screen, do this." It cancels the previous subscription, timer, or request.

### 4. Co-location (effect logic lives with the data it depends on)

Each `useEffect` owns one concern. Instead of spreading lifecycle logic across `componentDidMount`, `componentDidUpdate`, and `componentWillUnmount`, the setup and teardown of one feature live together.

---

## What if we didn't have it

### Calling fetch directly in render

```js
function Profile({ userId }) {
  const data = fetch(`/users/${userId}`).then(r => r.json()); // wrong
  return <div>{data.name}</div>;
}
```

Problems: runs on every render, returns a Promise (not the data), blocks rendering.

### Manually setting up subscriptions with no cleanup

```js
useEffect(() => {
  window.addEventListener('resize', handler);
  // no return — listener is never removed
}, []);
```

Problem: every mount adds a listener; unmounting the component leaves the listener alive, causing memory leaks and stale state updates.

### Forgetting the dependency array

```js
useEffect(() => {
  fetch(`/users/${userId}`).then(setData);
}); // no array
```

Problem: runs after every render — including renders triggered by `setData` itself. Infinite fetch loop.

### Using a ref to "avoid" useEffect

```js
const hasFetched = useRef(false);
if (!hasFetched.current) {
  hasFetched.current = true;
  fetch('/data').then(setData);
}
```

Problem: runs during render, not after. React can render components multiple times before committing (Strict Mode, Suspense). This pattern breaks under those conditions.

---

## Examples

### Example 1: Run once on mount

```js
useEffect(() => {
  document.title = 'Welcome';
}, []);
```

Sets the document title once. The empty array means: no dependencies, so never re-run.

---

### Example 2: Re-run when a dependency changes

```js
useEffect(() => {
  fetch(`/users/${userId}`)
    .then(r => r.json())
    .then(setUser);
}, [userId]);
```

Every time `userId` changes, fetch the new user. React compares `userId` between renders and re-runs if it changed.

---

### Example 3: Cleanup — cancel a timer

```js
useEffect(() => {
  const id = setInterval(() => setCount(c => c + 1), 1000);
  return () => clearInterval(id); // cleanup
}, []);
```

The return value is called before the next effect run and before unmount. Without it, a new interval starts on each render while old ones keep firing.

---

### Example 4: Cleanup — remove an event listener

```js
useEffect(() => {
  const handler = (e) => setKey(e.key);
  window.addEventListener('keydown', handler);
  return () => window.removeEventListener('keydown', handler);
}, []);
```

Same function reference is used for add and remove. If `handler` were recreated each time, `removeEventListener` would not match and the old listener would leak.

---

### Example 5: Subscription with dynamic dependency

```js
useEffect(() => {
  const socket = connectToRoom(roomId);
  socket.on('message', addMessage);
  return () => socket.disconnect();
}, [roomId]);
```

When `roomId` changes: React calls the cleanup (disconnects old room), then runs the effect again (connects to new room). The data flow is explicit.

---

### Example 6: Stale closure bug and fix

```js
// Bug: `count` is captured at mount, never updates
useEffect(() => {
  const id = setInterval(() => {
    console.log(count); // always 0
  }, 1000);
  return () => clearInterval(id);
}, []);

// Fix: use functional update — no need to read count directly
useEffect(() => {
  const id = setInterval(() => {
    setCount(c => c + 1); // no stale read
  }, 1000);
  return () => clearInterval(id);
}, []);
```

Stale closures happen when the effect captures a value but the dependency array does not include it. The captured value never updates.

---

### Example 7: Correct vs incorrect dependency array

```js
// Wrong: userId used inside but not listed
useEffect(() => {
  fetchUser(userId);
}, []);

// Correct: list everything read inside the effect
useEffect(() => {
  fetchUser(userId);
}, [userId]);
```

The ESLint rule `react-hooks/exhaustive-deps` enforces this automatically.

---

## Quickfire (Interview Q&A)

**Q: When does useEffect run?**
After the browser paints — it is asynchronous relative to rendering. It does not block the UI.

**Q: What is the dependency array for?**
It tells React when to re-run the effect. React compares each value between renders using `Object.is`; if any changed, the effect re-runs.

**Q: What does an empty dependency array mean?**
The effect runs once after the initial mount and never again.

**Q: What is the cleanup function?**
A function returned from the effect body. React calls it before running the effect again and before the component unmounts.

**Q: What is a stale closure in useEffect?**
When the effect captures a variable from an earlier render and uses an outdated value because that variable is missing from the dependency array.

**Q: How is useEffect different from useLayoutEffect?**
`useLayoutEffect` runs synchronously after DOM mutations but before the browser paints. Use it for DOM measurements or to avoid flicker. `useEffect` runs after paint and is preferred for most side effects.

**Q: What happens if you omit the dependency array entirely?**
The effect runs after every render. This is usually unintentional and can cause infinite loops if the effect triggers a state update.

**Q: Can useEffect return a Promise?**
No. The cleanup must be a synchronous function or nothing. If you need async work, define an async function inside the effect and call it there.

**Q: Why does React run effects twice in development (Strict Mode)?**
React intentionally mounts, unmounts, and remounts components to detect effects that do not clean up properly. This only happens in development.

**Q: When would you NOT use useEffect?**
When transforming data for rendering (use derived state or `useMemo` instead), or when responding to a user event directly (handle that in the event handler, not an effect).

---

## Key Takeaways

- `useEffect` is where you synchronize your component with systems outside React — network, DOM, timers, subscriptions.
- It runs after the browser paints, not during rendering. This keeps UI fast.
- The dependency array controls when the effect re-runs. Empty array = once. No array = every render.
- Every effect that subscribes or allocates a resource should return a cleanup function.
- A missing dependency causes stale data. An extra dependency causes unnecessary re-runs. Both are bugs.
- Each `useEffect` call should own one concern. Multiple effects per component is normal and encouraged.
- In Strict Mode (development), React runs effects twice on purpose to surface missing cleanups.

---

## Vocabulary

### Nouns (concepts)

**Side effect**: Any operation that reaches outside the pure render function — network requests, DOM writes, timers, subscriptions. `useEffect` is the designated place for these.

**Dependency array**: The second argument to `useEffect`. An array of values React watches between renders; the effect re-runs when any value changes.

**Cleanup function**: A function returned from the effect. Called by React before the effect re-runs and before the component unmounts. Used to cancel subscriptions, clear timers, or abort requests.

**Stale closure**: A bug where a function captures a variable from an earlier render and reads an outdated value, because the variable was not listed in the dependency array.

**Mount**: The first time React renders a component and adds it to the DOM.

**Unmount**: When React removes a component from the DOM. Cleanup functions run at this point.

**Strict Mode**: A React development mode that intentionally runs effects twice to surface missing cleanups.

**useLayoutEffect**: A variant of `useEffect` that runs synchronously after DOM updates but before the browser paints. Used for DOM measurements.

### Verbs (actions)

**Subscribe**: Register a callback with an external system (event listener, WebSocket, store). Requires a corresponding unsubscribe in the cleanup.

**Re-run**: What React does with an effect when a dependency value changes between renders.

**Clean up**: The act of reversing or cancelling a previously started side effect. Triggered by the cleanup function.

**Capture**: When a function (closure) closes over a variable at a specific point in time. Stale closures capture the wrong version of the variable.

### Adjectives (properties)

**Asynchronous** (relative to render): `useEffect` does not block the browser from painting. The effect runs after the frame is shown.

**Exhaustive** (dependency array): All values read inside an effect are listed in the dependency array. The `exhaustive-deps` lint rule enforces this.

**Stale**: A value that was current at capture time but has since been updated and is no longer accurate.
