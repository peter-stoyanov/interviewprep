# Redux fundamentals

**Abstraction level**: library  
**Category**: state management implementation

---

## Related Topics

- **Implementations of this**: Redux Toolkit, React-Redux
- **Depends on this**: reducer composition, store subscriptions
- **Works alongside**: immutability, selectors, async request handling
- **Contrast with**: MobX, Context API, local component state
- **Temporal neighbors**: unidirectional data flow, state management in the browser

---

## What is it

Redux is a library for keeping application state in one central store and changing it through explicit actions. Its core rule is simple: code does not directly change shared state; it dispatches an action, and reducers calculate the next state. This makes updates visible, ordered, and easier to reason about. Redux is mainly a way to control how shared data changes over time.

In concrete terms, the data is plain JavaScript data such as `user`, `cartItems`, `filters`, `loading`, and `error`. That data lives in memory inside the Redux store. Different parts of the app read from the store, and code writes to it only by dispatching actions. Over time, the store moves through state transitions such as `idle -> loading -> success` or `loggedOut -> loggedIn`.

---

## What problem does it solve

Start with a simple page: a user chooses a product category, a list shows matching products, and a badge shows how many products match. The shared data is small: one selected category and one list of products.

At first, it seems easy to let each part keep its own copy:

- the dropdown stores the selected category
- the list stores the selected category again
- the badge stores the count separately

That works until the data changes from more than one place. Now add:

- a reset button
- a server response
- browser navigation
- a saved filter preset

Without a clear system, common failures appear:

- **Duplication**: the list has `category = "books"` but the dropdown still has `"all"`
- **Inconsistency**: the badge says `12`, but the list shows `10`
- **Invalid data**: the UI says `loading = false`, `error = null`, and `products = null`, which does not describe a clear state
- **Hard-to-track changes**: several files can change the same data, so you cannot answer "what changed this?"
- **Unclear ownership**: there is no single place responsible for the real value

Redux solves this by making data flow explicit:

- one store holds the shared state
- actions describe what happened
- reducers decide how state changes
- subscribers react after the state changes

The value is not magic storage. The value is control.

---

## How does it solve it

### 1. Single store

Redux keeps shared application state in one store. That gives the app one current snapshot of shared data instead of many independent copies.

- **Data flow**: many readers, one shared source
- **Control**: shared data has one home
- **Predictability**: one state snapshot means one answer to "what is true right now?"

### 2. Actions describe change

An action is a plain object that says what happened, such as `{ type: 'cart/itemAdded', payload: item }`. It does not change state by itself; it names the transition request.

- **Data flow**: intent enters the system as data
- **Control**: writes become explicit and inspectable
- **Predictability**: changes are named, not hidden inside random code

### 3. Reducers calculate next state

A reducer is a function that receives the current state and an action, then returns the next state. It is the rulebook for allowed state transitions.

- **Data flow**: current state + action -> next state
- **Control**: transition logic is centralized
- **Predictability**: the same input gives the same output

### 4. Dispatch is the write path

In Redux, code does not directly update shared state. It dispatches an action. This separates "something happened" from "here is how state changes."

- **Data flow**: writers send actions, not direct mutations
- **Control**: state changes go through one entry point
- **Predictability**: update order is easier to follow

### 5. Subscriptions update readers

After Redux produces the next state, subscribers can read the new snapshot and update the UI or other consumers. Readers do not need to guess when data changed.

- **Data flow**: state changes fan out to interested readers
- **Control**: readers respond after the change, not during it
- **Predictability**: consumers see a completed new state

### 6. Immutable updates preserve correctness

Reducers should return new state objects instead of mutating existing ones in place. That makes state transitions explicit and makes it easier to compare old and new snapshots.

- **Data flow**: old snapshot stays untouched, new snapshot is produced
- **Control**: accidental hidden writes become less likely
- **Predictability**: change detection and debugging become simpler

### 7. Derived data stays derived

Redux works best when the store contains primary data, and computed values are derived when needed. If `totalPrice` can be calculated from `items`, storing both creates opportunities for disagreement.

- **Data flow**: base state in, derived value out
- **Control**: fewer values need manual updates
- **Predictability**: the store is less likely to contradict itself

---

## What if we didn't have it (Alternatives)

### 1. Shared mutable object

```js
const appState = { count: 0 }
appState.count++
```

This is the fastest way to start. It breaks when many parts of the app can change the same object, because there is no action log, no reducer rules, and no clear ownership.

### 2. Manual callback chains

```js
function onAddItem(item) {
  updateCart(item)
  updateBadge()
  updateSummary()
}
```

This works for small flows. At scale, every new consumer requires another manual call, which creates hidden coupling and makes it easy to forget one update.

### 3. Event bus everywhere

```js
bus.emit('itemAdded', item)
bus.on('itemAdded', updateCart)
bus.on('itemAdded', updateBadge)
```

This removes direct coupling between modules, but it also hides control flow. Many listeners can react in different places, and current state is harder to inspect than in a single Redux store.

### 4. Duplicate local copies

```js
headerCount = 2
sidebarCount = 2
cartPageCount = 2
```

This looks harmless until one copy changes and the others do not. Redux exists mainly to avoid this kind of drift in shared state.

---

## Examples

### 1. Minimal conceptual example

A counter has one value: `count`.

- Action: `"increment"`
- Reducer rule: add `1`
- New state: `count` moves from `0` to `1`

Redux here is just a controlled state transition.

### 2. Small code example

```js
const initialState = { count: 0 }

function reducer(state = initialState, action) {
  if (action.type === 'increment') {
    return { count: state.count + 1 }
  }
  return state
}
```

The key point is not the syntax. The key point is that the next state is calculated from old state plus an explicit action.

### 3. Incorrect vs correct reducer

```js
// Incorrect: mutates existing state
function reducer(state, action) {
  state.count++
  return state
}
```

```js
// Correct: returns a new state value
function reducer(state, action) {
  return { ...state, count: state.count + 1 }
}
```

The incorrect version hides change inside an existing object. The correct version makes the transition explicit by producing a new snapshot.

### 4. One action, many readers

State:

```js
{ cartItems: [{ id: 1, price: 20 }] }
```

After `dispatch({ type: 'cart/itemAdded', payload: { id: 2, price: 15 } })`:

- the cart list reads the new item list
- the badge reads the new item count
- the summary reads the new total

One write path updates many readers without each reader owning its own copy.

### 5. Browser and server interaction

The user clicks "Load products".

1. Dispatch `{ type: 'products/requested' }`
2. Store becomes `{ status: 'loading', items: [], error: null }`
3. Server responds
4. Dispatch either `{ type: 'products/received', payload: [...] }` or `{ type: 'products/failed', payload: 'timeout' }`

Redux makes each transition explicit, so the UI can correctly show spinner, data, or error.

### 6. Derived data example

```js
state = {
  items: [
    { price: 10, qty: 2 },
    { price: 5, qty: 1 }
  ]
}
```

Instead of storing `total: 25`, derive it from `items`. If quantity changes later, the total stays correct because it is computed from the current source data.

### 7. Real-world analogy

Think of Redux like a front desk in an office. People do not walk into the records room and edit files directly. They submit a request, the clerk updates the record according to rules, and everyone else reads the updated record from the same place.

---

## Quickfire (Interview Q&A)

**Q: What is Redux?**  
A library for storing shared application state in one store and changing it through dispatched actions and reducers.

**Q: What is the Redux store?**  
It is the object that holds the current state tree and lets code dispatch actions and subscribe to changes.

**Q: What is an action?**  
An action is a plain object that describes what happened, usually with a `type` and sometimes a `payload`.

**Q: What is a reducer?**  
A reducer is a function that takes current state and an action and returns the next state.

**Q: Why is dispatch important?**  
Dispatch gives Redux one explicit write path, which makes state changes easier to trace and control.

**Q: Why should reducers avoid mutation?**  
Because mutation hides changes inside existing objects, while immutable updates create clear old and new state snapshots.

**Q: What problem does Redux solve best?**  
It is most useful when many parts of an app need the same changing data and updates must stay predictable.

**Q: Is Redux only for UI state?**  
No. Redux stores shared application state; the UI is just one reader of that state.

**Q: What is derived state in Redux?**  
It is data computed from store state, such as totals or filtered lists, instead of stored as another source of truth.

**Q: How is Redux different from a global mutable object?**  
Redux adds rules around how changes happen, so writes are explicit and state transitions are easier to inspect.

**Q: What are the main Redux primitives?**  
Store, state, action, reducer, dispatch, and subscription.

**Q: When is Redux a bad fit?**  
If state is small, local, and not shared much, Redux can add structure that the app does not need yet.

---

## Key Takeaways

- Redux is a library for controlling how shared state changes.
- Shared data lives in one store instead of many drifting copies.
- Actions describe what happened; reducers decide the next state.
- Dispatch is the single write path for shared Redux state.
- Immutable updates make changes easier to reason about.
- Subscribers read the new state after a transition completes.
- Derived values are safer than storing redundant copies.
- Redux is most valuable when shared data changes often and many parts depend on it.

---

## Vocabulary

### Nouns

- **Redux**: A state management library built around explicit actions, reducers, and a central store.
- **Store**: The Redux object that holds the current state and coordinates dispatch and subscriptions.
- **State**: The current application data stored in Redux, such as items, status flags, or selected values.
- **State tree**: The full structured state object inside the store. It is called a tree because it usually contains nested objects and arrays.
- **Action**: A plain object that describes an event or intent to change state.
- **Type**: The action name, usually a string, that tells reducers what kind of transition is being requested.
- **Payload**: The action data that carries the values needed for the state change.
- **Reducer**: A function that receives current state and an action and returns the next state.
- **Subscription**: A connection that lets code react after the store state changes.
- **Selector**: A function that reads state and returns the specific value a consumer needs, often as derived data.
- **Snapshot**: One complete state value at one moment in time. Redux moves from one snapshot to the next.

### Verbs

- **Dispatch**: To send an action into Redux so the store can run reducers and calculate the next state.
- **Reduce**: To calculate a next state from a current state and an action.
- **Subscribe**: To register interest in store updates and react after state changes.
- **Derive**: To compute a value from existing state instead of storing another copy.
- **Mutate**: To change existing data directly in place. Reducers should avoid this.
- **Update**: To produce a new state value that reflects some action or event.

### Adjectives

- **Immutable**: Describes data that is not changed in place; instead, a new version is created.
- **Predictable**: Describes a system where the path from action to new state is explicit and understandable.
- **Shared**: Describes data needed by multiple parts of the application.
- **Derived**: Describes data computed from primary state rather than stored as its own source of truth.
- **Pure**: Describes a reducer that depends only on its inputs and returns the same output for the same inputs.
- **Centralized**: Describes state stored in one main place rather than spread across many unrelated copies.
