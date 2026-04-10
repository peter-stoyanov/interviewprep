# Container vs Presentational Components

**Abstraction level**: pattern
**Category**: frontend architecture / component design

---

## Related Topics

- **Implementations of this**: React component structure, smart vs dumb components
- **Depends on this**: props vs state, event handling, data fetching
- **Works alongside**: component composition, separation of concerns, state management
- **Contrast with**: monolithic components, feature-based components, MVVM-style UI layers
- **Temporal neighbors**: learn component basics first; next study lifting state up and shared state

---

## What is it

Container vs presentational components is a UI design pattern that splits components by responsibility. A container component deals with data, state, side effects, and decisions. A presentational component deals with rendering data and sending user events upward. The goal is to separate how data is managed from how data is shown.

In simple terms:

- **Data**: domain data such as users, products, loading flags, error messages, selected items
- **Where it lives**: usually in browser memory, often near the part of the UI that owns it
- **Who reads/writes it**: containers read and update the data; presentational components mostly read it and emit events
- **How it changes over time**: data is fetched, validated, filtered, selected, or updated in the container, then passed down again for rendering

---

## What problem does it solve

Start with a simple screen that shows a list of users. At first, one component can do everything: fetch users, track loading, filter the list, and render buttons. That works while the screen is small.

Then the screen grows. Now it must handle errors, retries, sorting, empty states, and a selected user. If one component owns all of this, data and UI rules get mixed together:

- the fetch logic sits next to markup
- the filtering logic is buried inside rendering code
- button clicks directly mutate local values
- loading and error rules are spread across many branches

This creates common failure modes:

- **Duplication**: multiple screens repeat the same fetch or transformation logic
- **Inconsistency**: two components render the same data differently because each applies its own rules
- **Invalid data**: the UI may render incomplete or mismatched values because no single place validates them
- **Hard-to-track changes**: it becomes unclear which event changed the data
- **Unclear ownership**: no one component clearly owns the state, so updates happen from too many places

The pattern solves a control problem: who owns the data, who transforms it, and who only displays it.

---

## How does it solve it

### 1. Separate data control from rendering

A container owns the changing data and the rules around it. A presentational component receives already-prepared data and focuses on output. This makes the data flow explicit: state and actions move down as inputs, user events move up as signals.

### 2. Give one place ownership of state

The container becomes the source of truth for the part of the UI it manages. If the selected tab, loading flag, or filtered list changes, there is one obvious place to inspect. That improves predictability because state transitions are centralized.

### 3. Keep presentational components pure about intent

A presentational component does not decide where data comes from or how it is stored. It gets values and event handlers, then renders the valid UI for those values. This reduces hidden coupling because the view does not depend on fetch timing, storage details, or business rules.

### 4. Make transformations explicit

Containers can convert raw data into display-ready data before passing it down. For example, a container can map a user record into `fullName`, `isDisabled`, and `statusLabel`. That keeps transformation logic in one place instead of scattering it across templates.

### 5. Improve reuse through narrower responsibilities

A presentational component can be reused with different data sources because it only needs a defined shape of input. A container can also be replaced without rewriting the view, as long as it still provides the same props and handles the same events.

### 6. Make testing simpler

You can test containers for control logic: data fetching, state transitions, validation, derived values. You can test presentational components for output logic: given valid input, do they render the right UI and emit the right events. Each part has a smaller correctness surface.

---

## What if we didn't have it (Alternatives)

### 1. One component does everything

```jsx
function UserList() {
  // fetch users
  // store loading/error/filter
  // filter users
  // render table and buttons
}
```

This is the common beginner approach. It works at first, then breaks when UI rules and data rules grow together. The component becomes hard to read because flow, transformation, and rendering are mixed in one place.

### 2. Each child fetches its own data

```jsx
<UserCard id="1" />
<UserCard id="2" />
<UserCard id="3" />
```

If each `UserCard` loads and shapes its own data, ownership is fragmented. You get duplicated requests, inconsistent loading states, and no clear control over when the screen is considered ready.

### 3. Presentational component mutates data directly

```jsx
function UserTable({ users }) {
  users.sort(byName)
  users.push(tempRow)
  return ...
}
```

This quick hack hides transformations inside rendering. The caller can no longer trust its own data, and correctness becomes fragile because display code changes shared values.

### 4. Shared global values with no local boundary

```jsx
function ProductGrid() {
  const products = globalStore.products
  globalStore.filter = "sale"
  return ...
}
```

This can remove duplication, but it often replaces local clarity with hidden coupling. The component depends on external mutable state, so it becomes harder to understand who changed what and why.

---

## Examples

### 1. Minimal concept: owner and viewer

The container is the owner of changing data. The presentational component is the viewer of that data.

```text
Container: holds count = 3
Presentational: shows "3" and a "+" button
```

When the user clicks `+`, the presentational component emits an event. The container updates `count` to `4` and sends the new value back down.

### 2. Small code snippet: list rendering

```jsx
function UserListView({ users, onSelectUser }) {
  return users.map(user =>
    <button onClick={() => onSelectUser(user.id)}>
      {user.name}
    </button>
  )
}
```

`UserListView` does not know where `users` came from. It only receives data and sends back the selected `id`.

### 3. Container preparing display data

```jsx
function UserListContainer() {
  const users = loadUsers()
  const visibleUsers = users.filter(u => u.active)
  return <UserListView users={visibleUsers} />
}
```

The container performs the transformation from raw data to display-ready data. The view stays simple because it only renders active users.

### 4. Incorrect vs correct responsibility split

**Incorrect**

```jsx
function UserListView({ users }) {
  const visibleUsers = users.filter(u => u.active)
  const sortedUsers = visibleUsers.sort(byName)
  return ...
}
```

This mixes rendering with important data rules. The same component may be forced to know filtering and sorting policy.

**Correct**

```jsx
function UserListContainer() {
  const sortedUsers = users.filter(u => u.active).sort(byName)
  return <UserListView users={sortedUsers} />
}
```

Now the data transformation is controlled in one place, and the view receives valid final input.

### 5. Real-world analogy: kitchen and waiter

- The kitchen decides how ingredients become a finished dish.
- The waiter delivers the dish and sends customer requests back.

The waiter should not decide recipe rules, and the kitchen should not be concerned with table layout. That is the same split: control and transformation in one place, presentation and event delivery in another.

### 6. Browser interaction: search box

```text
User types "ann"
SearchContainer stores query = "ann"
SearchContainer derives matching users
SearchView renders input value and result list
SearchView sends "input changed" events upward
```

The flow is explicit: input event up, state update in the container, derived data down.

### 7. Reuse with different data sources

```jsx
<ProductTableView products={featuredProducts} />
<ProductTableView products={searchResults} />
```

The same presentational component can render two different datasets because it only depends on the input shape, not on how the data was fetched or derived.

---

## Quickfire (Interview Q&A)

### 1. What is a container component?

A container component manages data, state, and behavior for part of the UI. It usually prepares data and passes it down to other components.

### 2. What is a presentational component?

A presentational component focuses on rendering UI from input data. It usually emits user events but does not own the main business logic.

### 3. Why separate them?

The separation makes data flow clearer and reduces coupling. One part controls change; the other part controls display.

### 4. Is this pattern about specific frameworks?

No. It is a design pattern for UI responsibility, not a specific library feature.

### 5. What data usually belongs in the container?

State that changes over time, derived values, loading and error flags, and side-effect coordination usually belong there.

### 6. What data usually belongs in the presentational component?

Input values needed to render the UI and callbacks for user actions. It should not need storage or fetching details.

### 7. Is a presentational component always stateless?

No. It can have small local UI state, such as whether a dropdown is open, if that state is purely about display and not shared control logic.

### 8. What is the main trade-off of this pattern?

It can add more files and indirection. For small screens, the split may feel heavier than necessary.

### 9. How does this pattern help testing?

It lets you test control logic separately from rendering logic. That usually produces smaller and more focused tests.

### 10. How is this different from a monolithic component?

A monolithic component mixes fetching, transformation, state updates, and rendering in one place. The pattern separates those concerns.

### 11. Is this pattern still useful if modern tools can do more?

Yes. Even if tools change, the underlying idea of clear ownership and explicit data flow remains useful.

### 12. When should you avoid overusing it?

If a component is tiny and its data rules are trivial, splitting it may create ceremony without much benefit.

---

## Key Takeaways

- Container vs presentational components is a way to control how UI data changes.
- Containers own changing data and important state transitions.
- Presentational components render data and emit user intent.
- The pattern makes data flow easier to trace.
- Transform raw data before it reaches the view.
- Clear ownership reduces duplication and inconsistency.
- The split improves reuse, testing, and maintainability.
- Use the pattern when complexity justifies the extra structure.

---

## Vocabulary

### Nouns (concepts)

**Container component**  
A component responsible for state, data loading, coordination, and transformation. In this pattern, it is the control layer for a part of the UI.

**Presentational component**  
A component responsible for displaying data and exposing user actions. It is the view layer in this pattern.

**State**  
Data that can change over time, such as loading flags, selected items, or form values. The container often owns the important state.

**Props**  
Inputs passed from one component to another. Presentational components typically depend on props for the data they render.

**Source of truth**  
The authoritative place where a value is owned and updated. This pattern tries to make that ownership explicit.

**Derived data**  
Data computed from other data, such as filtered lists or formatted labels. Containers often create derived data before rendering.

**Event**  
A signal that something happened, such as a click or input change. Presentational components emit events so containers can decide what to do next.

**Side effect**  
Work that affects the outside world or depends on it, such as fetching data or writing to storage. These usually belong in the container side of the split.

**Responsibility**  
The specific job a component owns. This pattern works by narrowing responsibilities instead of mixing them.

**Coupling**  
How strongly one part depends on another part's internal details. Lower coupling makes components easier to reuse and change.

### Verbs (actions)

**Render**  
To turn input data into UI output. Presentational components mainly do this.

**Fetch**  
To request data from an external source. This is typically container work because it changes state over time.

**Transform**  
To map raw data into a shape better suited for display. This keeps the view simpler and more predictable.

**Pass down**  
To send data or callbacks from a parent component to a child component. This is the main downward flow in the pattern.

**Emit**  
To send an event upward when the user interacts with the UI. Presentational components emit intent rather than mutate shared data directly.

**Own**  
To be the place that controls and updates a value. Containers usually own the important screen state.

### Adjectives (properties)

**Presentational**  
Focused on display rather than control logic. A presentational component should be easy to understand from its inputs alone.

**Stateful**  
Holding data that can change over time. Container components are often stateful because they manage transitions.

**Reusable**  
Easy to use in different contexts without rewriting internal logic. Presentational components become more reusable when they only depend on input shape.

**Predictable**  
Easy to reason about because data flow and ownership are explicit. This is one of the main benefits of the pattern.

**Coupled**  
Dependent on external details or hidden assumptions. The pattern tries to reduce this by separating control from rendering.

**Implicit**  
Not clearly stated in the code. Hidden ownership and hidden mutations are implicit and therefore harder to reason about.

**Explicit**  
Clearly visible in the code structure. Containers make state ownership and data transformations more explicit.
