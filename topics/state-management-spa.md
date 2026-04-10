# State Management in Browser SPA Apps

**Abstraction level**: concept / pattern
**Category**: frontend architecture

---

## Related Topics

- **Implementations of this**: Redux, Zustand, MobX, Pinia, XState, Signals
- **Depends on this**: optimistic UI, undo/redo, offline-first apps, real-time sync
- **Works alongside**: component architecture, routing, data fetching / caching patterns
- **Contrast with**: server-side rendering (state managed per request, not persisted in browser), local component state
- **Temporal neighbors**: learn component architecture first; then state management; then data fetching and caching patterns

---

## What is it

State management is a set of patterns for controlling where shared application data lives, who can change it, and how those changes propagate across the UI. In a Single Page Application (SPA), the browser runs the entire app for the duration of a session — there are no page reloads to reset state — so data must be explicitly tracked, updated, and kept consistent across many independent parts of the UI.

- **Data**: user identity, fetched lists, UI flags (loading, selected tab), form inputs
- **Where it lives**: JavaScript memory in the browser — objects, variables, component trees
- **Who reads/writes it**: components read it to render; user actions and server responses write to it
- **How it changes**: through explicit events (clicks, fetches, timers) that trigger state transitions, which trigger re-renders

---

## What problem does it solve

**Simple scenario**: A user logs in. Their name should appear in three places — the navbar, a dashboard widget, and a settings form.

Without a plan, you store `user` in whichever component fetched it first. Now other components need it too.

**Complexity grows**:
- You pass the user down as props through 5 layers of components
- Two sibling components each fetch the same data independently
- A table and a form both display the same list — one updates it locally, the other doesn't know

**Failure modes**:

| Problem | What happens |
|---|---|
| Duplication | Two copies of the same data diverge — different parts of the UI show different values |
| Inconsistency | User changes their name in settings; the navbar still shows the old name |
| Invalid data | One component mutates a list item without touching the shared list |
| Hard-to-track changes | Any component can write to any variable; there is no record of what changed or why |
| Unclear ownership | Nobody knows which component holds the authoritative version of the data |

State management solves this by establishing a **single source of truth** and enforcing **controlled update paths**.

---

## How does it solve it

### Single source of truth
All shared data lives in one place. Components read from it; they do not hold their own copies.

- **Data flow**: store → components (read-only view)
- **Control**: only explicit operations can change the store
- **Predictability**: given the same state, any component always renders the same output

### Unidirectional data flow
Changes follow one direction: event → action → state update → re-render. Nothing skips a step.

```
user event → action → state transition → new state → re-render
```

No component reaches into another to modify its data directly.

### Explicit state transitions
Instead of mutating data freely, each possible change is named and defined. This makes the full set of possible changes visible and auditable.

- **Control**: you can enumerate every way state can change
- **Predictability**: the same action on the same state always produces the same result

### Separation of concerns
Logic that changes state is separated from logic that displays state. Update logic is independently testable without rendering anything.

### Derived state
Values that can be computed from existing state are not stored — they are derived at read time.

```
// Don't store:
totalPrice = items.reduce((s, i) => s + i.price, 0)

// Derive it on read:
const totalPrice = select(state => state.items.reduce(...))
```

One source of truth, no synchronization needed.

### Scoped vs. shared state
Not all state should be shared. A dropdown's open/closed status belongs in local component state. A logged-in user belongs in a shared store. Mixing these up leads to either over-engineering or under-engineering.

---

## What if we didn't have it (Alternatives)

### Approach 1 — Local state only, passed as props
```
App holds user → passes to Navbar → passes to Avatar
```
Works for shallow trees. Breaks when unrelated components need the same data — every intermediary must forward props it doesn't use ("prop drilling").

### Approach 2 — Global mutable variable
```js
window.appState = { user: null, items: [] }
```
Any file can read and write it freely. Nothing notifies components when it changes. UI becomes stale immediately and stays stale until the next unrelated re-render.

### Approach 3 — Each component fetches its own data
```
Navbar fetches /me
Dashboard fetches /me
Settings fetches /me
```
Three network requests for the same data. Results may differ if data changes between requests. No coordination, no cache invalidation, no consistency.

### Approach 4 — Unstructured event bus
```js
emitter.emit('userUpdated', user)
// any listener anywhere can react — or not
```
Works at small scale. At larger scale: no record of what happened, listener order is unpredictable, impossible to trace a bug back to its cause.

All of these break for the same reason: **no controlled, observable path for how data changes**.

---

## Examples

### Example 1 — Lifting state (minimal)
Two components need the same counter. Move it to their shared parent — one source of truth.

```
// Bad: each owns a copy, they diverge
ComponentA { count = 0 }
ComponentB { count = 0 }

// Good: parent owns it, both read the same value
Parent { count = 0 } → A(count), B(count)
```

### Example 2 — Explicit state transition (reducer pattern)
Every possible change is a named operation. Same input always produces same output.

```js
function transition(state, action) {
  if (action === 'INCREMENT') return { count: state.count + 1 }
  if (action === 'RESET')     return { count: 0 }
  return state
}
```

No mutation, no surprise. Fully testable in isolation.

### Example 3 — Stale data bug (incorrect vs. correct)
```js
// Incorrect: captures the value at the time the function was created
update(count + 1) // count may already be outdated

// Correct: always reads the latest value
update(prev => prev + 1)
```

### Example 4 — Normalized vs. nested state
```js
// Nested: updating a user means navigating deep structure
state.posts[0].comments[2].author.name = 'Alice' // fragile

// Normalized: each entity stored once by ID
state.users['u1'] = { name: 'Alice' }
state.posts['p1'] = { authorId: 'u1' }
// Update the user once — consistent everywhere
```

### Example 5 — Derived state in practice
```js
// Two values that must always agree — duplication risk
state.items = [...]
state.itemCount = 3  // what if items changes and this doesn't?

// Derive it instead — always correct, no sync needed
const itemCount = state.items.length
```

### Example 6 — Optimistic update (real-world flow)
User clicks "Like". You want instant feedback, not a spinner.

```
1. Apply change to local state immediately (optimistic)
2. Send request to server
3a. Server succeeds → do nothing (state already correct)
3b. Server fails   → rollback to previous state
```

State change is controlled, intentional, and reversible.

---

## Quickfire (Interview Q&A)

**Q: What is state in a SPA?**
Any data tracked in browser memory that affects what gets rendered — user info, loading flags, fetched lists, form inputs.

**Q: What is the difference between local and shared state?**
Local state is owned by one component and not needed elsewhere. Shared state is read or written by multiple independent parts of the app.

**Q: What is unidirectional data flow?**
Data moves in one direction — action → state update → view — so changes are always traceable and never circular.

**Q: What is a state transition?**
A defined operation that takes current state and an event, and returns new state. It makes every possible change explicit and predictable.

**Q: What is prop drilling, and why is it a problem?**
Passing data down through many layers of components just to reach a deeply nested child. It couples unrelated components and makes refactoring painful.

**Q: What is derived state, and why should you not store it?**
A value computed from other state (e.g. total price from a list). Storing it creates two sources of truth that can diverge.

**Q: What is a single source of truth?**
One authoritative location for a piece of data. All reads come from it; all writes go through it. Prevents duplication and inconsistency.

**Q: Why is immutability important in state management?**
Returning a new object instead of modifying the existing one makes change detection cheap (reference comparison) and enables features like history and undo.

**Q: When should state be local vs. shared?**
State should be as local as possible — only promoted to shared when multiple unrelated components need to read or write it.

**Q: What is an optimistic update?**
Updating the UI immediately before the server confirms the action, then rolling back if the request fails. Improves perceived performance.

**Q: What does "normalized state" mean?**
Entities stored by ID in flat maps, referenced by ID elsewhere — rather than duplicated in nested structures. One update stays consistent everywhere.

**Q: What is the difference between state and derived state?**
State is the raw data you store. Derived state is computed from it on demand. If a value can be computed, it should not be stored.

---

## Key Takeaways

- State is data that lives in browser memory and controls what the UI shows.
- The core problem is keeping shared data consistent across many components that read and write it.
- A single source of truth eliminates duplication; controlled update paths eliminate hidden changes.
- Unidirectional flow — action → state → view — makes changes visible, predictable, and debuggable.
- Not all state is shared; scope it to the smallest part of the app that needs it.
- Derive values from state rather than storing computed duplicates.
- Immutability makes change detection cheap and enables undo and history.

---

## Vocabulary

### Nouns

**State**
Data held in browser memory that determines what the UI currently shows. Changes to state trigger re-renders.

**Store**
A centralized container that holds shared application state. Components read from it and dispatch actions to change it.

**Action**
A named description of an intent to change state (e.g. "add item", "log out"). It carries what happened, not how to handle it.

**Reducer**
A pure function that takes the current state and an action, and returns the next state. It defines all valid state transitions.

**Selector**
A function that reads a specific piece of state from the store, often computing a derived value from it.

**Derived state**
A value computed from existing state rather than stored independently. Eliminates the need to synchronize two values that always depend on each other.

**Local state**
State owned by a single component, not shared with others. Appropriate for UI concerns like dropdown open/closed.

**Global / shared state**
State that multiple unrelated components read or write. Needs a centralized home to stay consistent.

**Side effect**
An operation triggered by a state change that reaches outside the pure state transition — e.g. an API call, a timer, or writing to localStorage.

**Subscription**
A mechanism by which a component or function is notified when a piece of state changes, so it can re-render or react.

**Atom**
In some state management approaches, the smallest independent unit of state — a single piece of data other parts of the app can subscribe to individually.

**Slice**
A named section of a larger store, grouping related state and its transitions together. Keeps the store modular.

### Verbs

**Dispatch**
To send an action to the store, signaling that a state change should happen.

**Mutate**
To change a value directly in place. Generally avoided in state management — returning new objects is preferred.

**Derive**
To compute a value from existing state rather than storing it separately.

**Subscribe**
To register interest in a piece of state so that updates trigger a reaction (e.g. a re-render).

**Hydrate**
To populate state from a serialized source — e.g. loading persisted state from localStorage on app startup.

**Lift (state)**
To move state from a child component up to a parent, so multiple children can share it.

**Normalize**
To restructure nested or duplicated data into flat maps keyed by ID, so each entity is stored exactly once.

### Adjectives

**Immutable**
Describes state that is never modified in place — changes always produce a new object. Enables cheap change detection.

**Reactive**
Describes a system where changes to state automatically propagate to anything that depends on it.

**Normalized**
Describes state organized so that each entity appears exactly once, referenced by ID from other parts of the state tree.

**Stale**
Describes data that has been superseded by a newer version but has not yet been updated in the current view.

**Optimistic**
Describes an update applied to the UI immediately, before server confirmation, on the assumption it will succeed.

**Ephemeral**
Describes state that is short-lived and not worth persisting — e.g. a tooltip's visibility or a hover state.

**Shared**
Describes state that more than one independent component reads or writes and therefore needs a centralized home.
