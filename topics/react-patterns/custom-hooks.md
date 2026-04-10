# Custom Hooks

**Abstraction level**: pattern
**Category**: React logic reuse / frontend state management

---

## Related Topics

- **Implements this idea**: `useOnlineStatus`, `useFetch`, `useLocalStorage`
- **Depends on this**: hooks, component render cycle, state, effects
- **Works alongside**: component composition, context, reducer-based state
- **Contrast with**: utility functions, higher-order components, render props
- **Temporal neighbors**: learn basic hooks first; learn context and shared state patterns after

---

## What is it

A custom hook is a React pattern for packaging reusable stateful logic into a function. It lets multiple components use the same behavior without copying the same state, effect, and event-handling code into each component. A custom hook does not render UI. Its job is to manage data, react to changes, and return useful values or actions to the component that called it.

- **Data**: local state, derived values, browser signals, server results
- **Where it lives**: browser memory, inside each component instance that calls the hook
- **Who reads/writes it**: the component passes inputs in; the hook reads them, updates internal state, and returns outputs
- **How it changes over time**: inputs change, external events happen, state updates, and the returned values change on the next render

---

## What problem does it solve

Start with a simple case: two components both need to know whether the browser is online. Each component can add event listeners, store online/offline state, and clean up on unmount.

That looks manageable once. It becomes messy when the same logic appears in three, five, or ten components.

Without custom hooks, common failure modes appear:

- **Duplication**: the same state and effect logic is copied into many components
- **Inconsistency**: one component updates correctly, another forgets cleanup, another handles errors differently
- **Invalid data**: one version keeps `loading` true forever, another returns stale data after the input changed
- **Hard-to-track changes**: fixing a bug means finding every copy of the logic
- **Unclear ownership**: the component is doing both UI work and reusable behavior work

The real problem is not "writing less code." The real problem is controlling how shared behavior changes over time while keeping data flow explicit.

---

## How does it solve it

### 1. Encapsulate one behavior

A custom hook groups one behavior into one place: for example, "track online status" or "load a user by id." The state, transitions, and cleanup logic live together instead of being scattered across components.

### 2. Make inputs explicit

The component passes data into the hook through parameters. That makes ownership clear: the component provides the input, and the hook decides how behavior should react to that input.

### 3. Return controlled outputs

The hook returns the current data and, when useful, functions that change that data. This creates a clean contract: input goes in, stateful behavior happens, useful values come out.

### 4. Keep flow predictable

The component calls the hook during render, receives values, and renders UI from those values. When the hook's internal state changes, React re-renders the component. The flow stays one-way and observable.

### 5. Reuse logic without sharing state by accident

This is a key interview point: custom hooks reuse logic, not state. If two components call the same custom hook, each call gets its own independent state unless the hook is explicitly connected to shared storage like context, the browser, or a server.

### 6. Separate behavior from presentation

The component decides how things look. The custom hook decides how data is read, updated, synchronized, or derived. That separation makes components smaller and easier to reason about.

---

## What if we didn't have it

### 1. Copy-paste the logic into each component

```jsx
function Header() {
  const [online, setOnline] = useState(navigator.onLine);
  // same listener logic here
}

function Sidebar() {
  const [online, setOnline] = useState(navigator.onLine);
  // same listener logic again
}
```

This works at first, then drifts. One copy gets fixed, another does not.

### 2. Push stateful behavior into a plain helper

```jsx
function loadUser(id, setUser, setLoading) {
  setLoading(true);
  fetch(`/users/${id}`).then(r => r.json()).then(setUser);
}
```

This hides control in the wrong place. The helper depends on setters owned by the component, so data flow becomes indirect and tightly coupled.

### 3. Keep everything inline in one large component

```jsx
function ProfilePage({ userId }) {
  // fetch logic
  // retry logic
  // loading state
  // error state
  // online status
  // window resize logic
}
```

The component now owns UI and multiple behaviors at once. It becomes hard to test, hard to read, and hard to change safely.

### 4. Share mutable module state as a quick hack

```jsx
let cachedValue = null;
```

This creates hidden coupling between component instances. One component can affect another without that connection being visible in props or returned values.

---

## Examples

### Example 1: Minimal conceptual example

```jsx
function useCounter() {
  const [count, setCount] = useState(0);
  return { count, increment: () => setCount(c => c + 1) };
}
```

Data is `count`. The hook controls how it changes and returns both the current value and the allowed update action.

### Example 2: Component using the hook

```jsx
function CounterPanel() {
  const { count, increment } = useCounter();
  return <button onClick={increment}>{count}</button>;
}
```

The component does not manage the counting logic itself. It reads returned data and renders UI from it.

### Example 3: Browser event flow

```jsx
function useOnlineStatus() {
  const [online, setOnline] = useState(navigator.onLine);
  // subscribe to online/offline events, update state, clean up later
  return online;
}
```

Flow: browser sends events, the hook receives them, state changes, the component re-renders with new data.

### Example 4: Server interaction

```jsx
function useUser(userId) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  // when userId changes, fetch new user and update state
  return { user, loading };
}
```

Input is `userId`. Output is `{ user, loading }`. The hook turns network activity into UI-friendly state.

### Example 5: Incorrect vs correct mental model

```jsx
function StatusA() {
  const online = useOnlineStatus();
}

function StatusB() {
  const online = useOnlineStatus();
}
```

This is **not** one shared `online` state inside React. It is two separate hook calls reusing the same logic. They may show the same value because both read the same browser source.

### Example 6: Derived data

```jsx
function useCartSummary(items) {
  const total = items.reduce((sum, item) => sum + item.price, 0);
  return { total, itemCount: items.length };
}
```

Not every custom hook needs internal state. A hook can also package a reusable transformation from input data to derived output data.

### Example 7: Real-world analogy

Think of a custom hook as a reusable control procedure.

- Input: which machine or user you care about
- Flow: signals arrive from the browser or server
- Control: the procedure decides how to update current status
- Output: the latest status and allowed actions

Each caller runs the same procedure, but each caller still has its own local working state.

---

## Quickfire (Interview Q&A)

**Q: What is a custom hook?**  
A custom hook is a function that packages reusable React behavior. It manages data and change over time, then returns values or actions to a component.

**Q: Why use a custom hook instead of copying code?**  
It keeps one source of truth for a behavior. That reduces duplication and makes fixes consistent.

**Q: Does a custom hook share state between components?**  
No. It shares logic by default, not state.

**Q: What does a custom hook usually return?**  
It returns the current data and sometimes functions that change that data.

**Q: Can a custom hook render JSX?**  
No. Rendering is the component's job.

**Q: How is a custom hook different from a utility function?**  
A utility function is usually a plain transformation. A custom hook participates in React's stateful render flow.

**Q: Why do custom hooks start with `use`?**  
The name signals that the function follows hook rules and is meant to be called like a hook.

**Q: When should you extract a custom hook?**  
When the same stateful behavior appears in multiple places or when one component mixes too much UI and behavior logic.

**Q: Can one component use many custom hooks?**  
Yes. That is often a good way to keep behaviors separated and readable.

**Q: Can a custom hook call other hooks?**  
Yes. That is how it composes smaller behaviors into a reusable unit.

**Q: What is the main trade-off?**  
Abstraction can hide flow if the hook becomes too generic or tries to do too much.

**Q: When is a custom hook unnecessary?**  
If the logic is used once and is still simple, extracting it may add indirection without real benefit.

---

## Key Takeaways

- A custom hook is a way to control reusable stateful logic.
- It manages behavior, not presentation.
- Inputs go in, state changes over time, outputs come out.
- It improves reuse by centralizing one behavior in one place.
- It reuses logic without automatically sharing state.
- It makes ownership and data flow more explicit.
- It is most useful when components repeat the same change-handling logic.

---

## Vocabulary

### Nouns (concepts)

**Hook**  
A hook is a React function that participates in component state and lifecycle behavior. Custom hooks are built from that same model.

**Custom hook**  
A custom hook is a user-defined hook that packages reusable behavior. It returns data or actions instead of UI.

**Component**  
A component renders UI from data. It can call custom hooks to get that data and behavior.

**State**  
State is data that changes over time and affects rendering. Custom hooks often own and update local state.

**Effect**  
An effect is work triggered by rendering that synchronizes with something outside pure rendering, such as the browser or network. Many custom hooks use effects internally.

**Input**  
Input is the data passed into a hook, usually through parameters. It controls how the hook behaves.

**Output**  
Output is what a hook returns to the component. This is usually current data, derived data, and update functions.

**Derived value**  
A derived value is data computed from other data instead of stored separately. A custom hook can return derived values to keep components simpler.

**Subscription**  
A subscription is an ongoing connection to external changes, such as browser events or a socket. A custom hook can manage the setup and cleanup of that flow.

### Verbs (actions)

**Encapsulate**  
To encapsulate means to keep related logic together behind a small interface. A custom hook encapsulates one behavior.

**Reuse**  
To reuse means to apply the same logic in multiple places without duplicating it. Custom hooks make that reuse explicit.

**Derive**  
To derive means to compute one value from another. Hooks often derive UI-ready data from raw input data.

**Subscribe**  
To subscribe means to start listening for external changes. A hook may subscribe to browser or server events and update state when messages arrive.

**Synchronize**  
To synchronize means to keep one piece of data aligned with another source over time. Custom hooks often synchronize component state with the browser or network.

### Adjectives (properties)

**Reusable**  
Reusable logic can be applied in more than one component without copy-paste. That is the main value of a custom hook.

**Isolated**  
Isolated state belongs to one hook call inside one component instance. This is why custom hooks do not automatically create shared state.

**Explicit**  
Explicit means the flow is visible in the function signature and return value. Good custom hooks make inputs and outputs obvious.

**Derived**  
Derived data is calculated from existing data rather than stored separately. This reduces duplication and inconsistency.

**Invalid**  
Invalid data is data in a wrong or impossible state, such as stale results for the wrong input. Good custom hooks reduce these mistakes by centralizing behavior.
