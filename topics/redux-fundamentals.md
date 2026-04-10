# Redux fundamentals

**Abstraction level**: library  
**Category**: frontend state management

---

## Related Topics

- **Implementations of this**: Redux Toolkit, React-Redux
- **Depends on this**: unidirectional data flow
- **Works alongside**: selectors, async request handling, normalized state
- **Contrast with**: Context API, local component state, MobX
- **Temporal neighbors**: state management in the browser, Redux Toolkit

---

## What is it

Redux is a library for managing shared application state through a strict data flow. It keeps state in one store, changes that state through dispatched actions, and uses reducers to calculate the next state. The main idea is simple: shared data should not change from random places in random ways. Redux is a way to control how data changes over time.

The data is usually plain JavaScript data like `user`, `cartItems`, `filters`, `status`, and `error`. It lives in memory in the browser while the app is running. Different parts of the app read from the store, and code writes to it by dispatching actions. Over time, the store moves through explicit transitions like `idle -> loading -> success` or `loggedOut -> loggedIn`.

---

## What problem does it solve

Start with a simple page:

- a search input stores a query
- a list shows filtered results
- a badge shows the count

At first, it is tempting to let each part manage its own copy of the same data.

- the input stores `query`
- the list stores `query`
- the badge stores `count`

This works until the data starts changing from multiple places.

- the URL changes the query
- a reset button clears filters
- the server returns new results
- another screen updates the same data

Without a clear system, common failures appear:

- **Duplication**: the same fact exists in several places
- **Inconsistency**: one part says `count = 8`, another still shows `6`
- **Invalid data**: `status = "success"` but `items = null`
- **Hard-to-track changes**: you cannot answer "what changed this value?"
- **Unclear ownership**: no single place is responsible for the real state

Redux solves this by forcing shared state into one controlled flow:

- state lives in one store
- actions describe what happened
- reducers decide how the state changes
- readers observe the latest state

The value of Redux is not storage by itself. The value is explicit control over shared data.

---

## How does it solve it

### 1. One store for shared state

Redux keeps shared state in one store instead of many disconnected copies.

- **Data flow**: many readers, one source
- **Control**: shared data has a clear home
- **Predictability**: there is one answer to "what is true right now?"

### 2. Actions make change explicit

An action is a plain object that describes an event, such as `{ type: 'cart/itemAdded', payload: item }`. It is not the change itself. It is a message that says what happened.

- **Data flow**: writers send messages into the system
- **Control**: updates are named and visible
- **Predictability**: state changes are easier to trace

### 3. Reducers define valid transitions

A reducer receives the current state and an action, then returns the next state. It is the rulebook for how data may change.

- **Data flow**: current state + action -> next state
- **Control**: transition logic lives in one place
- **Predictability**: the same inputs produce the same output

### 4. Dispatch creates one write path

In Redux, shared state is not updated directly. Code dispatches an action, and Redux sends that action through the reducers.

- **Data flow**: writes go through one entry point
- **Control**: direct mutation from random places is avoided
- **Predictability**: update order is easier to follow

### 5. Immutable updates keep snapshots reliable

Reducers should return a new state value instead of changing the old one in place. That means the previous state stays untouched and the next state is a new snapshot.

- **Data flow**: old snapshot remains, new snapshot is produced
- **Control**: hidden changes become less likely
- **Predictability**: comparing before and after becomes simple

### 6. Derived data should stay derived

Redux works best when the store keeps source data, not every computed result. If `totalPrice` can be calculated from `items`, storing both creates two values that can disagree.

- **Data flow**: base data in, derived value out
- **Control**: fewer values need manual updates
- **Predictability**: the store is less likely to contradict itself

---

## What if we didn't have it (Alternatives)

### 1. Shared mutable object

```js
const appState = { count: 0 }
appState.count += 1
```

This is easy to start with, but any code can change `count` at any time. There is no action history, no central rules, and no clear ownership.

### 2. Manual callback chain

```js
function addItem(item) {
  cart.push(item)
  updateBadge()
  updateSummary()
}
```

This works for small cases. It breaks when more consumers appear, because every new dependency must be updated manually and in the right order.

### 3. Duplicate state copies

```js
headerCount = 2
sidebarCount = 2
cartPageCount = 2
```

This looks simple, but one missed update creates inconsistent UI. The same fact now has multiple owners.

### 4. Event-based quick hack

```js
bus.emit('itemAdded', item)
bus.on('itemAdded', updateCart)
bus.on('itemAdded', updateBadge)
```

This removes direct coupling, but it also hides the flow. Many listeners can react in different places, and current state is harder to inspect than in a single store.

---

## Examples

### 1. Minimal conceptual example

State:

```txt
{ count: 0 }
```

Action:

```txt
{ type: 'increment' }
```

Next state:

```txt
{ count: 1 }
```

This is Redux in its simplest form: a message causes a controlled state transition.

### 2. Small reducer example

```js
function reducer(state = { count: 0 }, action) {
  if (action.type === 'increment') {
    return { count: state.count + 1 }
  }
  return state
}
```

The important part is the shape of the transformation: old state plus action becomes new state.

### 3. Incorrect vs correct update

Incorrect:

```js
state.count++
return state
```

Correct:

```js
return { ...state, count: state.count + 1 }
```

The incorrect version changes existing data in place. The correct version produces a new snapshot.

### 4. One action, many readers

State:

```txt
{
  cartItems: [{ id: 1, price: 20 }]
}
```

After:

```js
dispatch({ type: 'cart/itemAdded', payload: { id: 2, price: 15 } })
```

Now several readers can update from the same source:

- the cart list reads the new items
- the badge reads the new item count
- the summary reads the new total

One write updates many readers without giving each reader its own copy.

### 5. Request state over time

Before request:

```txt
{ status: 'idle', items: [], error: null }
```

User loads products:

```js
dispatch({ type: 'products/requested' })
```

State becomes:

```txt
{ status: 'loading', items: [], error: null }
```

Server succeeds:

```js
dispatch({ type: 'products/received', payload: [...] })
```

State becomes:

```txt
{ status: 'success', items: [...], error: null }
```

Redux helps model change over time as valid states instead of scattered flags.

### 6. Source data vs derived data

Stored source data:

```txt
items = [
  { price: 10, qty: 2 },
  { price: 5, qty: 1 }
]
```

Derived data:

```txt
total = 25
```

A better design stores `items` and derives `total` from them. If quantity changes, the derived value stays correct because it comes from current source data.

### 7. Real-world analogy

Think of Redux like a shared ledger with strict rules.

- workers do not edit the ledger directly
- they submit a request that says what happened
- the ledger keeper applies the rule
- everyone reads the latest ledger

That is store, action, reducer, and shared state in plain terms.

---

## Quickfire (Interview Q&A)

### 1. What is Redux?

Redux is a library for managing shared state through a central store, explicit actions, and reducers that compute the next state.

### 2. What problem does Redux mainly solve?

It solves the problem of shared data changing in too many places without clear ownership or traceability.

### 3. What is a store in Redux?

The store is the object that holds the current shared state of the application.

### 4. What is an action?

An action is a plain object that describes what happened, usually with a `type` and sometimes a `payload`.

### 5. What is a reducer?

A reducer is a function that takes current state and an action, then returns the next state.

### 6. Why is dispatch important?

Dispatch creates one controlled write path into shared state, which makes updates easier to follow and debug.

### 7. Why should Redux state be updated immutably?

Immutable updates preserve old snapshots and make change detection and reasoning about state transitions simpler.

### 8. Why not store every computed value in Redux?

Because computed values can drift from source data; it is safer to derive them from the real inputs when needed.

### 9. How is Redux different from local state?

Local state belongs to one small part of the UI, while Redux is meant for state that many parts of the app need to read or update.

### 10. Is Redux only about storing data?

No. Its main benefit is controlling how data changes, not just where data is kept.

---

## Key Takeaways

- Redux is a library for controlling shared state changes.
- Shared state lives in one store, not in many disconnected copies.
- Actions describe events; reducers define valid transitions.
- Dispatch is the single write path into shared state.
- Immutable updates make before-and-after state easier to trust.
- Derived data should usually be calculated, not stored twice.
- Redux is most useful when many parts of the app depend on the same changing data.

---

## Vocabulary

### Nouns

**Redux**  
A library for managing shared application state with explicit update rules and a predictable data flow.

**State**  
The current data the application is using right now, such as user info, filters, or request status.

**Store**  
The central object that holds Redux state and coordinates updates.

**Action**  
A plain object that describes an event or requested change in the system.

**Payload**  
The data carried inside an action, such as a new item, an ID, or a server response.

**Reducer**  
A function that receives the current state and an action, then returns the next state.

**Snapshot**  
A particular version of state at one moment in time. Redux moves from one snapshot to the next.

**Shared state**  
Data used by multiple parts of the application, not just one isolated part.

**Derived data**  
A value calculated from source state, such as a total computed from cart items.

**Transition**  
A change from one valid state to another, such as `loading -> success`.

### Verbs

**Dispatch**  
To send an action into the Redux flow so reducers can calculate the next state.

**Read**  
To access current state from the store in order to render UI or make decisions.

**Write**  
To cause a state change. In Redux, writing happens indirectly through dispatch, not by direct mutation.

**Derive**  
To calculate a new value from existing state instead of storing an extra copy.

**Mutate**  
To change existing data in place. In Redux fundamentals, direct mutation of state is avoided.

### Adjectives

**Immutable**  
Describes data that is not changed in place. Redux prefers immutable updates so each state change produces a new snapshot.

**Predictable**  
Describes a system where the path from event to state change is explicit and easy to follow.

**Shared**  
Describes data needed by more than one part of the app, which is where Redux is most useful.

**Derived**  
Describes a value computed from other state rather than stored as an independent source of truth.
