# State management in the browser

**Abstraction level**: concept / pattern  
**Category**: frontend architecture

---

## Related Topics

- **Implementations of this**: Redux, Zustand, MobX, XState
- **Depends on this**: props vs state, immutability, event handling
- **Works alongside**: routing, form handling, data fetching, caching
- **Contrast with**: server-side state, event-driven messaging, persistence
- **Temporal neighbors**: local vs global state, derived state, unidirectional data flow

---

## What is it

State management in the browser is the practice of controlling how application data is stored, changed, and shared while a page is running. It matters in apps where the UI changes many times without a full page reload. The main goal is not just to hold data, but to make change predictable.

The data is things like selected filters, current user input, loading status, errors, cart items, and which screen is open. This data usually lives in browser memory while the app runs, though some parts may also be reflected in the URL, browser storage, or responses from the server. UI code reads the current state to render, and events such as clicks, typing, timers, and network responses write the next state. Over time, the app moves through transitions like `idle -> loading -> success` or `closed -> open`.

---

## What problem does it solve

Start with a small page: a search box, a results list, and a loading spinner.

- The user types a query
- The app stores that query
- A request is sent
- Results come back
- The UI updates

This is still manageable when one part of the page owns the data. Complexity grows when the same data is needed in more places:

- the query appears in the URL
- the results count appears in a badge
- a filter panel changes the same request
- a history panel shows recent searches

Without a state management approach, common failures appear:

- **Duplication**: the same fact is stored in multiple places
- **Inconsistency**: one part says the filter is `"active"`, another still uses `"all"`
- **Invalid data**: `loading = false`, `error = null`, and `results = null` may leave the UI with no clear meaning
- **Hard-to-track changes**: many places can update the same value, so bugs become hard to trace
- **Unclear ownership**: no one knows which copy is the real one

In simple terms, state management solves one question: when data changes, who is allowed to change it, where is the real value, and how does the rest of the UI find out?

---

## How does it solve it

### 1. Single source of truth

Shared data should have one authoritative home. Other parts of the UI should read that value instead of keeping separate copies.

- **Data flow**: one source, many readers
- **Control**: writes happen at the owner
- **Predictability**: one question has one answer

### 2. Explicit ownership

Each piece of state should have a clear owner. If a page owns `selectedTab`, child parts should not silently create their own versions of it.

- **Data flow**: readers know where the value comes from
- **Control**: not every part of the UI can write freely
- **Predictability**: bugs have a traceable origin

### 3. State transitions

A state change should be treated as a transition from one valid snapshot to another. Instead of "anything can change anytime," the app follows clear before and after states.

- **Data flow**: event in, next state out
- **Control**: allowed changes are explicit
- **Predictability**: the same event should lead to the same kind of transition

### 4. Unidirectional flow

A useful model is: event happens, state updates, UI re-renders. The UI should be an output of state, not an independent source of truth.

- **Data flow**: input -> update -> render
- **Control**: avoids circular updates between UI parts
- **Predictability**: easier to reason about than many parts mutating each other

### 5. Derived data over duplicated data

If a value can be computed from existing state, compute it instead of storing another copy. For example, `completedCount` can be derived from a list of tasks.

- **Data flow**: base data in, derived value out
- **Control**: fewer values require manual updates
- **Predictability**: fewer contradictions

### 6. Valid state shapes

Good state management makes invalid combinations harder to represent. A clear state model improves correctness.

- `status = "success"` and `error = "failed"` at the same time is contradictory
- `selectedItemId = 7` is invalid if item `7` is not in the data

- **Data flow**: only meaningful states move through the app
- **Control**: impossible states are restricted early
- **Predictability**: the UI can trust the data it reads

---

## What if we didn't have it (Alternatives)

### 1. Manual copies everywhere

```js
headerFilter = "active"
tableFilter = "active"
exportFilter = "active"
```

This works briefly. It breaks when one copy changes and the others do not.

### 2. Global mutable object

```js
window.appState = { cart: [], total: 0 }
window.appState.total = 99
```

This is easy to start with, but any code can change anything at any time. There is no controlled write path and no reliable way to explain why the current data looks the way it does.

### 3. Treating the DOM as the source of truth

```js
const query = document.querySelector("#search").value
```

This makes rendered output act like application state. It becomes fragile because the DOM is where state is shown, not the best place to manage the app's real data.

### 4. Event-only communication

```js
bus.emit("cart-updated", item)
```

This can connect distant parts quickly, but it hides control flow. Many listeners may update their own data in unclear order, and there is no single current snapshot to inspect.

---

## Examples

### 1. Minimal conceptual example

One panel can be open or closed.

- Data: `isOpen`
- Writer: button click
- Reader: panel UI
- Transition: `false -> true` or `true -> false`

State management here is just controlling one boolean clearly.

### 2. Small code example: one owner

```js
const state = { count: 0 }

function increment() {
  state.count = state.count + 1
}
```

The key idea is ownership. `count` lives in one place and changes through one known path.

### 3. Incorrect vs correct derived data

```js
// Incorrect
state = { items: ["a", "b"], itemCount: 3 }
```

```js
// Better
state = { items: ["a", "b"] }
itemCount = state.items.length
```

The first version can disagree with itself. The second cannot.

### 4. Shared filter across multiple parts

A page has one `status` filter.

- the table reads it to show rows
- the badge reads it to show count
- the export action reads it to export matching rows

If each part stores its own filter, they drift. If one shared value exists, they stay aligned.

### 5. Browser and server interaction

The user clicks "Save profile."

1. Browser state becomes `saving`
2. A request is sent
3. The server responds
4. Browser state becomes `saved` or `error`

The main value is not the request itself. It is that the UI always knows which state it is in right now.

### 6. Incorrect vs correct state shape

```js
// Weak shape
state = {
  loading: false,
  data: null,
  error: null
}
```

This shape allows unclear combinations.

```js
// Clearer shape
state = { status: "idle", data: null }
```

Then transitions like `idle -> loading -> success` are easier to reason about.

### 7. Real-world analogy

Think of an airport departure board. One central system holds the current flight data. Many screens display it. Staff do not manually update each screen one by one. Browser state management works the same way: one real value, many readers.

---

## Quickfire (Interview Q&A)

**Q: What is state in the browser?**  
Data in a running web app that can change over time and affect what the user sees.

**Q: What is state management?**  
It is the set of rules for where state lives, who can change it, and how updates reach the UI.

**Q: Why is state management needed in modern browser apps?**  
Because many UI parts depend on the same changing data, and without control that data becomes duplicated or inconsistent.

**Q: What is a single source of truth?**  
One authoritative place for a piece of shared data instead of multiple competing copies.

**Q: What is a state transition?**  
A move from one valid state to another after an event such as a click or server response.

**Q: Why is duplicated state dangerous?**  
Because two copies of the same fact can drift apart and make the UI contradict itself.

**Q: What is derived state?**  
A value computed from existing state instead of stored separately.

**Q: Why is unidirectional flow useful?**  
It makes updates easier to trace because data moves through a known path.

**Q: Is all browser state shared?**  
No. Some state is local to one UI area, while some must be shared across multiple parts of the app.

**Q: What makes state valid?**  
Its values describe a real allowed situation and do not contradict each other.

---

## Key Takeaways

- State management is a way to control how browser data changes.
- Shared data should usually have one owner and one real source.
- Duplicated state creates inconsistency.
- Good state transitions are explicit and traceable.
- The UI should reflect state, not secretly become the state.
- Derived data is usually safer than storing redundant copies.
- Correct state shapes prevent impossible or unclear UI situations.

---

## Vocabulary

### Nouns

- **State**: Data that exists now and may change later. In the browser, it drives what the UI renders.
- **Source of truth**: The authoritative place where a piece of data is stored. Other parts should read from it rather than copy it.
- **State transition**: A change from one valid state to another. It describes how data moves over time.
- **Derived data**: Data computed from other state, such as a count or filtered list. It reduces duplication.
- **Ownership**: The rule that one part of the app is responsible for a piece of state. Clear ownership reduces confusion.
- **Snapshot**: The full current set of state values at one moment in time. Rendering usually reads a snapshot.
- **Event**: Something that happens and may trigger a state change, such as input, a timer, or a server response.
- **Invalid state**: A combination of values that does not describe a real or allowed situation in the app.
- **Flow**: The path data takes from input to storage to rendering. Good flow is explicit.

### Verbs

- **Read**: Access current state to render UI or make a decision. Readers should not silently become writers.
- **Write**: Change state. Good state management limits where and how writes happen.
- **Update**: Produce the next state from the current state after some event.
- **Derive**: Compute a value from existing state instead of storing another copy.
- **Synchronize**: Keep multiple values in agreement. Strong state management reduces how often this is needed.
- **Mutate**: Change data directly. Uncontrolled mutation makes changes harder to track.
- **Render**: Turn current state into visible UI. Rendering should follow state, not invent it.

### Adjectives

- **Shared**: Used by multiple parts of the app. Shared state usually needs stronger coordination.
- **Local**: Used by one small part of the UI. Local state has simpler ownership.
- **Predictable**: Changes happen through known paths and produce understandable results.
- **Derived**: Computed from primary data rather than stored independently.
- **Consistent**: Different parts of the app agree on the same facts.
- **Valid**: The data describes a real allowed situation.
- **Explicit**: Visible and named rather than hidden inside unrelated code.
