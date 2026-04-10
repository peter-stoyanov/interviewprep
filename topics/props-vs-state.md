# Props vs State

**Abstraction level**: concept / pattern
**Category**: component architecture, frontend UI

---

## Related Topics

- **Depends on this**: component lifecycle, derived state, lifting state up
- **Works alongside**: data flow (unidirectional), event handling, controlled vs uncontrolled components
- **Contrast with**: global state (Context, Redux), server state (fetched data)
- **Temporal neighbors**: learn components first → then props vs state → then state management patterns

---

## What is it

Props and state are the two ways data lives inside a component tree.

**Props** are data passed into a component from outside — the parent controls them. The component receiving props cannot change them directly.

**State** is data a component owns and manages itself. It lives inside the component, changes over time in response to events, and triggers a re-render when it does.

- Props: external, read-only, controlled by the parent
- State: internal, mutable, controlled by the component itself

---

## What Problem Does It Solve

In a component-based UI, every piece of data needs a clear owner — something that decides when and how it changes.

Without this distinction:

**Scenario:** A `Button` component needs to know what label to display. It also needs to track whether it has been clicked.

- The label comes from outside — the parent decides it. That is a prop.
- Whether it has been clicked is internal behavior. That is state.

If a component tries to mutate data passed in from outside, the parent no longer knows what its own data looks like. You lose predictability: the same input no longer guarantees the same output.

**Failure modes without clear separation:**

- **Duplication**: two components both try to "own" the same value, and they drift out of sync
- **Hidden mutation**: a child silently modifies data the parent still thinks it controls
- **Unclear ownership**: nobody knows who is responsible for resetting a value
- **Stale data**: a component holds a local copy that diverges from the source of truth

---

## How Does It Solve It

### Props enforce a single direction of data flow

Data flows from parent to child. A component cannot push props back up. This makes it easy to trace where a value comes from — always look up the tree.

```
Parent owns: username = "alice"
  → passes username as a prop to ProfileCard
  → ProfileCard renders it, cannot change it
```

### State localizes ownership

When a component needs to track something that changes over time (an input value, a toggle, a counter), it owns that data as state. Nobody else needs to know about it unless the component chooses to expose it.

```
Dropdown owns: isOpen = false
  → user clicks → isOpen = true
  → Dropdown re-renders with menu visible
  → parent is never involved
```

### Re-rendering is tied to change

When state changes, the component re-renders. When props change (because the parent re-rendered with new data), the child re-renders. Both triggers are explicit and traceable.

### Principle: data flows down, events flow up

A child cannot change its own props. If the child needs to affect the parent's data, it does so through a callback function — the parent passes a function as a prop, the child calls it. Control stays with the owner.

```
Parent owns: count = 0, onIncrement = () => setCount(count + 1)
  → passes both as props to Counter
  → Counter calls onIncrement on click
  → Parent updates count → Counter gets new prop → re-renders
```

---

## What If We Didn't Have It (Alternatives)

### Global mutable variables

```js
// Bad: shared mutable global
let username = "alice";

function ProfileCard() {
  username = "bob"; // anything can change this at any time
  return username;
}
```

Any component can read or write `username`. Changes are invisible — no re-render, no traceability, no ownership.

### Passing objects and mutating them

```js
// Bad: child mutates the object it was given
function ProfileCard(user) {
  user.name = "bob"; // silently changes the parent's data
}
```

The parent still holds a reference to the same object, now unexpectedly changed. The UI may not reflect the actual data.

### Duplicating data into local copies

```js
// Bad: child copies and manages its own version
function ProfileCard(props) {
  let localName = props.name; // copy on mount
  // props.name updates → localName does not → stale
}
```

The copy falls out of sync with the prop. Two sources of truth for the same value.

---

## Examples

### Example 1 — Minimal distinction

```
// Prop: passed in, read-only
<Greeting name="Alice" />

// State: owned internally
component Greeting:
  state: hasWaved = false
  render: "Hello, Alice" + button that sets hasWaved = true
```

`name` is a prop — the parent decides it. `hasWaved` is state — only this component cares about it.

---

### Example 2 — Props change when the parent changes

```
Parent state: selectedUser = "Alice"
  → renders <ProfileCard name="Alice" />

User picks "Bob" → parent state changes to selectedUser = "Bob"
  → renders <ProfileCard name="Bob" />
  → ProfileCard gets a new prop, re-renders with "Bob"
```

The child did not change anything. The parent changed, and the child reflected it.

---

### Example 3 — State changes on user interaction

```
component SearchBox:
  state: query = ""

  on input change:
    query = event.target.value  // state update → re-render

  render: <input value={query} />
```

The parent passes nothing. The component tracks its own input value. When the user types, state updates, and the input re-renders with the new value.

---

### Example 4 — Lifting state up (when children need to share data)

Two sibling components both need the same value. Neither should own it independently — they would fall out of sync.

```
// Wrong: both own their own copy
ComponentA: state temperature = 20
ComponentB: state temperature = 20
// → they drift

// Right: lift state to parent
Parent: state temperature = 20
  → passes temperature as prop to both A and B
  → passes setTemperature callback as prop
  → both see the same value
```

---

### Example 5 — Derived data is not state

If a value can be computed from existing props or state, it should not be stored as additional state.

```
// Bad: redundant state
state: firstName = "Alice"
state: lastName = "Smith"
state: fullName = "Alice Smith"   // duplicated, can go stale

// Good: derive it
fullName = firstName + " " + lastName  // computed at render time
```

Storing derived data as state creates two sources of truth for the same value.

---

### Example 6 — Props as configuration, state as behavior

```
<Button label="Submit" disabled={false} onClick={handleClick} />
```

- `label`, `disabled`, `onClick` are props — the parent configures the button
- If the button tracks an internal "loading" state after being clicked, that belongs to state — the parent does not need to manage it

---

## Quickfire (Interview Q&A)

**Q: What is the difference between props and state?**
Props are data passed into a component from outside; state is data a component owns and manages internally.

**Q: Can a component change its own props?**
No. Props are read-only from the component's perspective. Only the parent that passes them can change them.

**Q: What happens when state changes?**
The component re-renders with the new state value.

**Q: What happens when a parent passes new props to a child?**
The child re-renders with the updated props.

**Q: When should something be state vs a prop?**
If the component itself needs to track a value that changes over time, it is state. If the value is determined by the outside world (the parent), it is a prop.

**Q: What is "lifting state up"?**
Moving state to a common ancestor component so multiple children can share the same data via props.

**Q: Can props be functions?**
Yes. Passing a function as a prop is how children communicate back to parents — the child calls the function, the parent handles the change.

**Q: What is derived state?**
A value computed from existing props or state. It should not be stored as additional state, because it creates duplication and can become inconsistent.

**Q: What does "unidirectional data flow" mean?**
Data only flows in one direction — from parent to child via props. Events travel back up via callbacks.

**Q: Why not just use global variables instead of props and state?**
Global variables have no ownership, no change tracking, and do not trigger re-renders. You lose predictability and traceability.

**Q: What is a controlled component?**
A component whose value is driven entirely by props (or state passed from above), not by its own internal state. The parent is the single source of truth.

---

## Key Takeaways

- Props are data you receive; state is data you own.
- A component cannot change its own props — it can only read them.
- State change triggers a re-render; prop change (from a parent re-render) also triggers a re-render.
- Data flows down the tree; events (callbacks) flow up.
- When two components need to share data, lift the state to their closest common ancestor.
- Never store derived data as state — compute it from the source of truth at render time.
- Clear ownership of data is the core benefit: you always know what controls a value.

---

## Vocabulary

### Nouns (concepts)

**Props (properties)**: Data passed into a component from its parent. Read-only from the component's perspective. Define what a component should render or how it should behave.

**State**: Data owned and managed by a component. Can change over time, typically in response to user interaction or async results. Each change triggers a re-render.

**Re-render**: The process of a component recalculating its output in response to a state or prop change.

**Source of truth**: The single authoritative location where a piece of data lives. There should be exactly one for each value.

**Derived state**: A value computed from other state or props. Should not be stored separately — compute it at render time to avoid duplication.

**Controlled component**: A component whose displayed value is driven by external data (props), not internal state. The parent is fully in control.

**Unidirectional data flow**: The pattern where data travels in one direction — parent to child via props. Children communicate back via callbacks.

**Lifting state up**: Moving state from a child component to a common ancestor, so multiple siblings can access the same data via props.

### Verbs (actions)

**Pass (props)**: The parent provides a value to a child component at render time.

**Mutate**: To change data in place. Avoided with props — props should never be mutated by the receiving component.

**Lift (state)**: To move state ownership to a higher-level component in the tree.

**Derive**: To compute a value from existing data rather than storing it separately.

**Trigger a re-render**: What happens when state or props change — the component recalculates and updates the UI.

### Adjectives (properties)

**Read-only**: Cannot be changed by the component that receives it. Props are read-only to the child.

**Mutable**: Can change over time. State is mutable (controlled mutation through the component's own update mechanism).

**Stateful**: A component that owns and manages its own state.

**Stateless (or "dumb")**: A component that only renders based on props, with no internal state.

**Stale**: Out of sync with the current source of truth. Happens when a copy of data is not updated after the original changes.
