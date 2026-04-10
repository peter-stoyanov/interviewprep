# State management in the browser

**Abstraction level**: concept / pattern  
**Category**: frontend architecture

---

## Related Topics

- **Implementations of this**: Redux, Zustand, MobX, XState
- **Depends on this**: optimistic UI, undo/redo, offline-first behavior
- **Works alongside**: routing, form handling, data fetching, caching
- **Contrast with**: local component state, server-side state, event-driven messaging
- **Temporal neighbors**: component composition, props vs state, immutability

---

## What is it

State management in the browser is the practice of controlling how application data is stored, read, updated, and shared while a web app is running. It matters when the page stays alive and the UI changes many times without a full reload. The goal is not just to hold data, but to make data changes predictable.

In simple terms, the data is things like the current user, selected filters, form values, loading flags, notifications, and fetched records. It usually lives in browser memory, and sometimes parts of it are mirrored in places like the URL, storage, or the server. UI code reads this data to render, and user actions or network responses write new values. Over time, the app moves through state transitions such as "logged out" to "logged in" or "idle" to "loading" to "loaded".

---

## What problem does it solve

Start with a small case: a page has a search box and a results list. The user types text, the app stores the query, sends a request, and then renders the results.

That is simple while one part of the page owns the data. Complexity starts when more parts need the same data:

- the query also appears in the URL
- a badge shows the result count
- a filter panel changes the same request
- a history panel needs past searches

Without a state management approach, the same data gets copied into multiple places. Once data is duplicated, it can drift apart.

Common failure modes:

- **Duplication**: one part stores `query = "book"` while another still has `query = "books"`
- **Inconsistency**: the filter panel shows "price: low to high" but the list was fetched using a different filter
- **Invalid data**: the UI says `loading = false` but `results = null`, so the screen has no clear meaning
- **Hard-to-track changes**: many parts of the code can update the same value, so you cannot easily answer "who changed this?"
- **Unclear ownership**: no one knows which copy of the data is the real one

State management solves this by defining where data lives, who is allowed to change it, and how updates flow through the app.

---

## How does it solve it

### 1. Single source of truth

Shared data should have one authoritative location. Other parts of the UI should read that data, not keep their own independent copies.

- **Data flow**: one source feeds many readers
- **Control**: updates happen at the owner, not everywhere
- **Predictability**: one value means one answer

### 2. Explicit ownership

Every piece of state should have a clear owner. If `selectedProductId` belongs to the page-level state, random child code should not silently create another version of it.

- **Data flow**: readers know where to get the value
- **Control**: writers are limited
- **Predictability**: bugs become easier to trace

### 3. Controlled state transitions

State should change through explicit operations, not accidental mutation. A transition is just "given old data and an event, produce new data."

- **Data flow**: event in, new state out
- **Control**: allowed changes are named and visible
- **Predictability**: the same input should produce the same result

### 4. Unidirectional flow

A useful mental model is: input happens, state updates, UI re-renders. The UI should reflect state, not secretly become state.

- **Data flow**: action -> state change -> render
- **Control**: avoids circular updates
- **Predictability**: easier to reason about than many parts mutating each other

### 5. Derived data instead of duplicated data

If a value can be computed from existing state, usually compute it instead of storing it separately. For example, `itemCount` can be derived from `items.length`.

- **Data flow**: base data in, derived value out
- **Control**: fewer places to update
- **Predictability**: less chance of contradiction

### 6. Valid state shapes

Not every combination of values makes sense. Good state management makes invalid states harder to represent.

- `loading = true` and `error = "failed"` at the same time may be contradictory
- `selectedUserId = 42` is invalid if user `42` does not exist

Correctness improves when the data model matches real app states.

---

## What if we didn't have it (Alternatives)

### 1. Manual copies everywhere

```js
headerUser = user
sidebarUser = user
profileUser = user
```

This looks easy at first. It breaks when one copy changes and the others do not.

### 2. Global mutable object

```js
window.appState = { cart: [], total: 0 }
window.appState.total = 99
```

Any code can change anything at any time. There is no clear update path, no ownership, and no guarantee the UI will react correctly.

### 3. UI reads directly from the DOM

```js
const query = document.querySelector('#search').value
```

This treats the rendered page as the source of truth. It becomes fragile because the DOM is an output of state, not a good place to manage application data.

### 4. Event-only communication

```js
bus.emit('cart-updated', item)
```

This can connect distant parts of an app quickly. At scale, it creates hidden coupling because many listeners may react in unclear order, with no central view of current state.

---

## Examples

### 1. Minimal conceptual example

One checkbox controls whether details are visible.

- Data: `isOpen`
- Writer: user click
- Reader: details panel
- Transition: `false -> true` or `true -> false`

State management here is simply controlling one boolean correctly.

### 2. Small code example: single owner

```js
const state = { count: 0 }

function increment() {
  state.count = state.count + 1
}
```

The important idea is not the syntax. It is that `count` has one owner and one clear update path.

### 3. Incorrect vs correct derived data

```js
// Incorrect
state = { items: ['a', 'b'], itemCount: 3 }

// Correct
state = { items: ['a', 'b'] }
itemCount = state.items.length
```

The first version can become invalid. The second cannot disagree with itself.

### 4. Shared filter across multiple widgets

A page has a dropdown for `status = "active"`.

- The table reads it to fetch rows
- The badge reads it to show count
- The export button reads it to export the same subset

If each widget stores its own filter, they drift. If one shared value exists, all three stay aligned.

### 5. Browser and server interaction

The user clicks "Save profile."

1. Browser state changes to `saving`
2. Request is sent to the server
3. Server responds with success or failure
4. Browser state becomes `saved` or `error`

State management makes this flow explicit so the UI can show the right feedback at each step.

### 6. Invalid state example

```js
state = {
  status: 'success',
  data: null,
  error: 'Network failed'
}
```

This mixes meanings. A better shape would force one clear mode at a time, such as `idle`, `loading`, `success`, or `error`.

### 7. Real-world analogy

Think of a train station board. One central system stores arrival data. Many screens display it. Staff do not manually edit each screen one by one. Browser state management works the same way: one data source, many views.

---

## Quickfire (Interview Q&A)

**Q: What is state in the browser?**  
Data in the running app that can change over time and affect what the user sees.

**Q: What is state management?**  
It is the set of rules for where state lives, who can change it, and how updates reach the UI.

**Q: Why is state management needed?**  
Because modern browser apps keep running across many interactions, so data can easily become duplicated or inconsistent.

**Q: What is a single source of truth?**  
A piece of shared data has one authoritative owner instead of many copies.

**Q: What is a state transition?**  
A state transition is the move from one valid state to another after some event.

**Q: Why is duplicated state risky?**  
Because two copies can disagree, and then the UI shows conflicting information.

**Q: What is derived state?**  
A value computed from existing state instead of stored separately.

**Q: Why is unidirectional flow useful?**  
It makes updates easier to trace because data moves through a known path.

**Q: Is all browser state global?**  
No. Some state is local to one UI part, while some must be shared across the app.

**Q: What makes state "correct"?**  
The values match a real, valid situation in the app and do not contradict each other.

---

## Key Takeaways

- State management is mainly about controlling how data changes.
- Shared data should usually have one owner.
- Duplicated state creates inconsistency.
- Explicit transitions are easier to reason about than ad hoc mutation.
- Derived data is safer than storing redundant copies.
- Good data flow makes bugs easier to trace.
- Correct state models prevent impossible UI situations.

---

## Vocabulary

### Nouns

- **State**: Data that exists now and may change later. In the browser, it drives what the UI renders.
- **Source of truth**: The authoritative place where a piece of data is stored. Other views should read from it rather than copy it.
- **State transition**: A change from one valid state to another. It is usually triggered by a user action, timer, or network response.
- **Derived data**: Data computed from other state, such as a total count or filtered list. It should usually not be stored separately.
- **Ownership**: The rule that a specific part of the app is responsible for a piece of state. Clear ownership reduces confusion.
- **UI**: The visible interface shown to the user. It should reflect state rather than secretly hold application truth.
- **Event**: Something that happens and may trigger a state change, such as a click, input, or server response.
- **Invalid state**: A combination of values that does not represent a real or meaningful situation in the app.
- **Flow**: The path data takes from input to storage to rendering. Good flow is explicit and easy to trace.

### Verbs

- **Read**: To access current state in order to render or make a decision. Readers should not silently become writers.
- **Write**: To change state. Good state management limits where and how writes happen.
- **Update**: To produce a new current value from an old one. Updates should follow clear rules.
- **Derive**: To compute a value from existing state instead of storing another copy. This reduces inconsistency.
- **Synchronize**: To keep multiple values in agreement. Good designs reduce the need for synchronization by avoiding duplication.
- **Mutate**: To change data directly. Uncontrolled mutation makes change harder to track.

### Adjectives

- **Shared**: Used by multiple parts of the app. Shared state usually needs stronger control.
- **Local**: Used by one small part of the UI. Local state does not need app-wide coordination.
- **Predictable**: Changes happen in known ways and produce understandable results. This is a core goal of state management.
- **Derived**: Computed from other values rather than stored as primary data. Derived values should stay close to the read path.
- **Consistent**: Different parts of the app agree on the same data. Consistency is one of the main reasons state management exists.
- **Valid**: The data represents a real allowed situation. Valid state supports correct UI behavior.
