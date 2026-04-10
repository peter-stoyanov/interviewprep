# Context API vs Redux

**Abstraction level**: framework feature vs library  
**Category**: frontend state management comparison

---

## Related Topics

- **Depends on this**: React component tree, state, props
- **Works alongside**: reducers, selectors, middleware, local vs global state
- **Contrast with**: prop drilling, MobX, Zustand
- **Temporal neighbors**: learn local vs global state before this; learn Redux Toolkit after this

---

## What is it

Context API and Redux are two ways to let multiple parts of a React application read shared data without manually passing that data through every component. They both deal with state that lives in browser memory while the app is running, but they control that state differently.

Context API is a React feature that lets a parent provide a value to any descendant in the component tree. Redux is a separate library that keeps application state in a central store outside the component tree and changes it through explicit actions.

In simple terms, the data might be `theme`, `currentUser`, `cartItems`, `filters`, or `requestStatus`. Components read that data to render UI, and events like clicks, form input, or network responses cause the data to change over time. The main difference is how visible and controlled those changes are.

---

## What problem does it solve

Start with a simple app: a user logs in, the header needs the user name, the sidebar needs permissions, and the profile page needs account details. If that data only lives in one component, every intermediate component must pass it down as props.

That works for a small tree. As the app grows, more screens need the same data, more events update it, and more parts of the UI depend on it. Now the main problems appear:

- **Duplication**: the same data is copied into multiple local states
- **Inconsistency**: one part of the UI shows old data while another shows new data
- **Invalid data**: loading, success, and error flags stop matching the actual request result
- **Hard-to-track changes**: it becomes unclear which event changed shared state
- **Unclear ownership**: developers stop knowing where the source of truth lives

Context API solves the "shared access" problem: many components can read one provided value. Redux solves both "shared access" and "controlled updates": many components can read shared state, and every change goes through a known state transition.

---

## How does it solve it

### 1. Shared read access

Context API gives a subtree access to one provided value. Redux gives the whole app access to a central store.

- **Data flow**: one writer publishes shared data, many readers consume it
- **Control**: shared data has a known source instead of being copied everywhere
- **Predictability**: readers look up the same value instead of keeping separate versions

### 2. Explicit ownership

With Context API, ownership usually sits near the provider component. With Redux, ownership sits in the store and reducer logic for each state slice.

- **Data flow**: updates come from a smaller number of known places
- **Control**: the app has a clearer source of truth
- **Predictability**: developers can answer "where does this data live?"

### 3. Update model

Context API does not define one strict way to change data. You can provide plain values, functions, or reducer-based state. Redux does define one strict path: dispatch an action, reducer calculates the next state, subscribers receive the new snapshot.

- **Data flow**: Context can be flexible; Redux is intentionally narrow
- **Control**: Redux makes updates more explicit
- **Predictability**: stricter update paths are easier to trace

### 4. Subscription granularity

Context API is value broadcasting through a tree. When the provided value changes, consumers of that context react to the new value. Redux uses store subscriptions and commonly lets components select only the state they need.

- **Data flow**: Context pushes a changed value through consumers; Redux lets readers subscribe to specific store data
- **Control**: Redux usually gives finer control over what each component depends on
- **Predictability**: targeted subscriptions help large apps stay easier to reason about

### 5. Change visibility

Context API is good when the shared value changes rarely or the update path is simple. Redux is designed for cases where many events change shared state and you need a visible history of why state changed.

- **Data flow**: Redux makes change events first-class through actions
- **Control**: actions create an audit trail of intent
- **Predictability**: debugging is easier when every state change has a named cause

### 6. Scale

Context API is lightweight when you need to avoid prop drilling for a small set of global values. Redux becomes useful when state is large, frequently changing, shared across distant parts of the app, or must stay consistent across many updates.

- **Data flow**: simple global values fit Context well; complex shared workflows fit Redux better
- **Control**: Redux adds structure as complexity grows
- **Predictability**: more structure reduces accidental coupling

---

## What if we didn't have it (Alternatives)

### 1. Manual prop drilling

```jsx
<App user={user}>
  <Layout user={user}>
    <Header user={user} />
  </Layout>
</App>
```

This works at first, but components in the middle pass data they do not use. Over time, the tree becomes tightly coupled to data plumbing instead of UI structure.

### 2. Duplicated local state

```js
Header:   currentUser = { name: 'Ana' }
Sidebar:  currentUser = { name: 'Ana' }
Profile:  currentUser = { name: 'Ana' }
```

Each component now owns its own copy. One update can succeed in one place and be missed in another, so the UI becomes inconsistent.

### 3. Shared mutable object

```js
window.appState.cartItems.push(item)
```

This is a quick hack. Any code can change the data at any time, so ownership disappears and debugging becomes guesswork.

### 4. Context used for everything

```jsx
<AppContext value={{ user, cart, filters, orders, notifications, updateEverything }}>
```

This centralizes access, but it also creates a large, broad dependency surface. Many components now depend on one big value, so unrelated changes become harder to isolate.

---

## Examples

### 1. Minimal conceptual example

Shared data:

```txt
theme = "dark"
```

Need:

```txt
Navbar reads theme
Footer reads theme
Settings page updates theme
```

Context API is often enough here because the value is small and easy to reason about.

### 2. Small Context example

```jsx
<ThemeContext.Provider value="dark">
  <Navbar />
</ThemeContext.Provider>
```

The provider puts one value into the component tree. Descendants can read it without receiving `theme` through every intermediate component.

### 3. Small Redux example

```js
dispatch({ type: 'cart/itemAdded', payload: item })
```

This makes the change explicit. Instead of "some code changed the cart," the app records that a specific event requested a specific state transition.

### 4. Incorrect vs correct ownership

Incorrect:

```txt
ProductList owns cart count
CartPage owns cart count
Header owns cart count
```

Correct:

```txt
One shared source of truth owns cart count
Many components read it
```

Both Context and Redux can provide one source of truth. Redux is stronger when cart updates come from many unrelated parts of the app.

### 5. Real-world analogy

Context API is like a building intercom: one office announces a message to rooms in its building section. Redux is like a control room logbook: every change request is recorded, processed, and the latest official state is available centrally.

The first is good for broadcasting a shared value. The second is better when many actors keep sending updates and you need controlled coordination.

### 6. Browser and server interaction

Suppose a page loads orders:

```txt
idle -> loading -> success
```

If only one screen cares, Context can carry that state. If filters, badges, retry buttons, cache status, and multiple screens all depend on those orders, Redux gives a clearer model for tracking request state and updates.

### 7. Simple decision example

Use Context API for:

```txt
theme, locale, current auth session, feature flags
```

Use Redux for:

```txt
cart, notifications, server request state, multi-step workflows, cross-page shared business state
```

The difference is not "small app vs big app." The real difference is how complex the shared data flow and update rules are.

---

## Quickfire (Interview Q&A)

### 1. What is the core difference between Context API and Redux?

Context API shares values through a React tree. Redux manages shared state in a central store with explicit actions and reducers.

### 2. Is Context API a state management library?

Not by itself in the same sense as Redux. It mainly solves value distribution; state management rules must still be designed around it.

### 3. What problem does Context solve best?

It solves prop drilling for values many descendants need, especially when the update logic is simple.

### 4. What problem does Redux solve best?

It solves complex shared state with predictable updates, clearer ownership, and easier debugging.

### 5. Can Context replace Redux?

Sometimes for simple cases, yes. For complex workflows, frequent updates, and large shared state, Redux usually gives stronger control.

### 6. Why is Redux often easier to debug?

Because updates happen through named actions and reducers, so state changes are more explicit and traceable.

### 7. Why can large Context values become hard to manage?

Because many components end up depending on one broad shared value, which increases coupling and makes change impact harder to see.

### 8. When would you choose Context over Redux?

When the data is global but simple, such as theme, locale, or current user information with straightforward updates.

### 9. When would you choose Redux over Context?

When many parts of the app update the same state, request state is important, or consistency across screens matters.

### 10. Do both help create a single source of truth?

Yes, both can. Redux enforces that source of truth more explicitly through store structure and update rules.

---

## Key Takeaways

- Context API is mainly about sharing values through a React tree.
- Redux is mainly about controlling how shared state changes.
- Context is flexible, but that also means fewer built-in rules.
- Redux is more structured, which helps as state flow becomes complex.
- Both can reduce duplication and inconsistency when used as a single source of truth.
- Context fits simple global data well; Redux fits complex shared workflows well.
- The real trade-off is convenience versus control.

---

## Vocabulary

### Nouns

- **Context API**: A React feature for passing a value through a component subtree without manually forwarding props at every level. It is mainly about shared access to data.
- **Redux**: A state management library that stores shared application state in a central store. It emphasizes explicit updates and predictable state transitions.
- **state**: Data that can change over time while the application runs. Examples include user info, cart items, loading status, and filters.
- **store**: The central container that holds Redux state. Components read from it and request changes through actions.
- **provider**: A component that makes a context value available to descendants. It defines where that shared value enters the tree.
- **consumer**: A component that reads a context value. It depends on the provider above it in the tree.
- **action**: A named event that describes an intended state change in Redux. It answers "what happened?"
- **reducer**: A function that receives current state and an action, then returns the next state. It defines valid state transitions.
- **source of truth**: The authoritative place where a piece of data lives. Using one source reduces duplication and inconsistency.
- **subscription**: The relationship where a component listens for relevant state changes. Redux relies heavily on this idea.
- **prop drilling**: Passing data through components that do not use it, only so deeper components can receive it. This is a common reason to introduce Context.
- **middleware**: Logic in Redux that can intercept actions before they reach reducers. It is often used for logging, async work, or side effects.

### Verbs

- **provide**: To place a context value into part of the component tree so descendants can read it. This is the main operation of Context API.
- **consume**: To read a value from context. A consumer depends on whatever the provider currently exposes.
- **dispatch**: To send an action to the Redux store. Dispatching starts a controlled update flow.
- **reduce**: To compute the next state from the current state and an action. In Redux, reducers perform this transformation.
- **subscribe**: To listen for updates to shared state. Components subscribe so they can re-read relevant data when it changes.
- **derive**: To compute one value from other state instead of storing it separately. This helps avoid duplicated or inconsistent data.

### Adjectives

- **shared**: Used by more than one component or feature. Shared data often needs clearer ownership.
- **global**: Available across large parts of the application. Not all global data is complex, but it should still have a single source of truth.
- **local**: Owned by one component or a small UI area. Local state usually does not need Context or Redux.
- **predictable**: Easy to trace and reason about because updates follow clear rules. Redux is designed to make state changes predictable.
- **explicit**: Visible and intentionally defined rather than hidden. Named actions are an explicit way to represent state changes.
- **coupled**: Tightly connected so that changes in one place affect many others. Prop drilling and oversized context values can increase coupling.
- **centralized**: Kept in one main location instead of spread across the app. Centralization helps reduce duplicated state.
