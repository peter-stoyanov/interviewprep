# Custom Hooks

**Abstraction level**: pattern
**Category**: React logic reuse and component behavior composition

---

## Related Topics

- **Implementations of this**: `useOnlineStatus`, `useFetch`, `useLocalStorage`
- **Depends on this**: hooks, component render cycle, local state, effects
- **Works alongside**: component composition, context, reducers
- **Contrast with**: utility functions, render props, higher-order components
- **Temporal neighbors**: learn basic hooks first; learn context and shared state patterns after

---

## What is it

A custom hook is a React pattern for reusing stateful behavior across components. It is a function that uses hooks internally and returns data, actions, or both. It does not render UI. Its job is to control how some piece of data is read, updated, synchronized, or derived over time.

- **Data**: local state, derived values, async status, browser signals, external inputs
- **Where it lives**: in browser memory, inside each component instance that calls the hook
- **Who reads/writes it**: the component passes inputs in; the hook reads those inputs, updates internal state, and returns outputs
- **How it changes over time**: inputs change, external events happen, the hook updates state, and the component re-renders with new values

---

## What problem does it solve

Start with a simple case: two components both need to know whether the user is online. Each component can keep its own `online` value, subscribe to browser events, and clean up when it is removed.

That is manageable once. It gets messy when the same behavior appears in many places: profile page, header, checkout flow, notification banner. Now the same data rules exist in multiple files.

Without custom hooks, the failure modes are predictable:

- **Duplication**: the same state and event logic is copied repeatedly
- **Inconsistency**: one copy handles cleanup correctly, another forgets
- **Invalid data**: one copy returns stale results or impossible state combinations
- **Hard-to-track changes**: a bug fix must be applied in many places
- **Unclear ownership**: components mix UI concerns with reusable behavior concerns

The real problem is control. When data changes over time, you need one clear place that defines how that change is handled.

---

## How does it solve it

### 1. Encapsulate one behavior

A custom hook keeps one behavior in one unit, such as "track online status" or "load a user." The state, transitions, and synchronization logic stay together instead of being scattered across components.

### 2. Make inputs explicit

The component passes inputs into the hook through parameters. That makes data flow visible: the caller owns the input, and the hook decides how behavior should react to it.

### 3. Return a small contract

The hook returns only what the component needs: current data, derived data, and maybe actions. This keeps the boundary clear and reduces hidden coupling.

### 4. Keep change predictable

The component calls the hook during render, gets current outputs, and renders UI from them. When the hook updates its state, React re-renders the component, so the flow stays consistent and one-way.

### 5. Reuse logic without accidental shared state

This matters in interviews: custom hooks reuse logic by default, not state. If two components call the same custom hook, each call has its own state unless the hook explicitly reads from shared storage such as context, the browser, or a server.

### 6. Separate behavior from presentation

The hook controls how data changes. The component controls how that data is shown. That makes both pieces easier to read, test, and change.

---

## What if we didn't have it (Alternatives)

### 1. Copy the same logic into every component

```jsx
function Header() {
  const [online, setOnline] = useState(navigator.onLine);
}

function Sidebar() {
  const [online, setOnline] = useState(navigator.onLine);
}
```

This works until one copy changes and the others do not. Control is duplicated, so correctness drifts.

### 2. Put the behavior in a plain helper function

```jsx
function loadUser(id, setUser, setLoading) {
  setLoading(true);
  fetch(`/users/${id}`).then(r => r.json()).then(setUser);
}
```

This pushes state control into a helper that depends on setters owned elsewhere. The flow becomes indirect and tightly coupled.

### 3. Keep everything inside one large component

```jsx
function ProfilePage() {
  // fetch state
  // retry state
  // online status
  // resize logic
}
```

The component now owns UI and multiple behaviors. That makes it harder to follow which data changes for which reason.

### 4. Use shared mutable module data as a shortcut

```jsx
let cachedUser = null;
```

This creates hidden coupling between component instances. One part of the UI can affect another without any explicit input or output.

---

## Examples

### 1. Minimal conceptual example

```jsx
function useCounter() {
  const [count, setCount] = useState(0);
  return { count, increment: () => setCount(c => c + 1) };
}
```

The hook owns one piece of data, `count`, and one allowed transition, `increment`.

### 2. Component using that hook

```jsx
function CounterPanel() {
  const { count, increment } = useCounter();
  return <button onClick={increment}>{count}</button>;
}
```

The component reads data and renders UI. The hook controls how the data changes.

### 3. Same hook, two separate callers

```jsx
function A() {
  const { count } = useCounter();
}

function B() {
  const { count } = useCounter();
}
```

`A` and `B` reuse the same logic but do not share the same `count`. Each call creates its own local state flow.

### 4. Browser event example

```jsx
function useOnlineStatus() {
  const [online, setOnline] = useState(navigator.onLine);
  return online;
}
```

Conceptually, the browser sends `online` and `offline` events, the hook updates state, and the component re-renders from the latest value.

### 5. Input-driven async behavior

```jsx
function useUser(userId) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  return { user, loading };
}
```

Input is `userId`. Output is data shaped for UI. The hook turns network change over time into predictable component state.

### 6. Derived data in a hook

```jsx
function useCartSummary(items) {
  return {
    itemCount: items.length,
    total: items.reduce((sum, item) => sum + item.price, 0),
  };
}
```

Not every custom hook needs internal state. A hook can also package a reusable data transformation.

### 7. Incorrect vs correct mental model

```jsx
const online = useOnlineStatus();
```

Incorrect: "The hook stores one global online value for the whole app."

Correct: "Each caller runs the same behavior. They may read the same browser signal, but the hook call itself is still local to that component."

### 8. Real-world analogy

A custom hook is like a reusable operating procedure. Input goes in, the procedure watches for changes, applies rules, and returns the latest status. Different teams can use the same procedure without sharing the same worksheet.

---

## Quickfire (Interview Q&A)

**Q: What is a custom hook?**  
A custom hook is a function that packages reusable React behavior. It returns data, actions, or both, but not UI.

**Q: Why use a custom hook instead of copy-paste?**  
It gives one place to control how a behavior works. That reduces duplication and inconsistent fixes.

**Q: Does a custom hook share state between components?**  
No. It shares logic by default, not state.

**Q: What does a custom hook usually return?**  
It usually returns current data, derived data, and functions that trigger valid updates.

**Q: How is a custom hook different from a utility function?**  
A utility function is usually a plain transformation. A custom hook participates in React's stateful render flow.

**Q: Can a custom hook render JSX?**  
No. Rendering belongs to components.

**Q: Why does the name start with `use`?**  
The name signals that it follows hook rules and should be called as a hook.

**Q: When should you extract a custom hook?**  
When the same behavior appears in multiple components or one component is mixing too much behavior with UI.

**Q: Can a custom hook call other hooks?**  
Yes. That is how it composes smaller pieces of behavior into one reusable unit.

**Q: What is the main trade-off of custom hooks?**  
They reduce duplication, but a badly designed hook can hide data flow and make behavior harder to see.

---

## Key Takeaways

- A custom hook is a way to control reusable behavior, not a way to render UI.
- It makes data flow explicit: inputs in, controlled changes, outputs out.
- It is most useful when the same stateful logic appears in multiple places.
- It improves correctness by centralizing one set of data rules.
- It reuses logic without automatically creating shared state.
- Good custom hooks have a small, clear contract.
- If a hook becomes too broad, it turns into hidden complexity instead of reuse.

---

## Vocabulary

### Nouns (concepts)

**Hook**  
A hook is a React function that participates in stateful component behavior. Custom hooks are built from the same mechanism.

**Custom hook**  
A custom hook is a user-defined hook that packages reusable behavior. It returns values and actions instead of UI.

**Component**  
A component renders UI from current data. It calls custom hooks to get behavior and state.

**State**  
State is data that changes over time and affects what the user sees. Custom hooks often own or shape this data.

**Input**  
Input is the data passed into a hook through parameters. It controls how the hook behaves.

**Output**  
Output is what the hook returns to the component. This is usually current data, derived data, or update functions.

**Derived data**  
Derived data is computed from existing data instead of stored separately. Hooks often return derived values to keep components simpler.

**Effect**  
An effect is logic that synchronizes with something outside pure rendering, such as the browser or network. Many custom hooks use effects internally.

**Subscription**  
A subscription is an ongoing connection to external changes, such as events or messages. A custom hook can manage starting and stopping that connection.

**Contract**  
A contract is the public shape of a hook: what it accepts and what it returns. A good contract makes behavior predictable for callers.

### Verbs (actions)

**Encapsulate**  
To encapsulate means to keep related logic together behind a small interface. A custom hook encapsulates one behavior.

**Reuse**  
To reuse means to apply the same logic in multiple places without duplicating code. That is the main purpose of a custom hook.

**Derive**  
To derive means to compute one value from another. Hooks often derive UI-ready data from raw inputs.

**Synchronize**  
To synchronize means to keep local state aligned with an external source over time. Hooks often do this with browser or network data.

**Subscribe**  
To subscribe means to start listening for external changes. A hook may subscribe to events and update state when those events arrive.

### Adjectives (properties)

**Reusable**  
Reusable logic can be applied in many components without copy-paste. Custom hooks exist to make that practical.

**Explicit**  
Explicit means the data flow is visible in the hook's inputs and outputs. Good hooks make control obvious.

**Isolated**  
Isolated state belongs to one hook call in one component instance. This is why two callers do not automatically share state.

**Derived**  
Derived data is calculated from other data rather than stored independently. This reduces duplication and inconsistency.

**Invalid**  
Invalid data is data in a wrong or impossible state, such as stale or contradictory values. Centralizing logic in a hook helps prevent that.
