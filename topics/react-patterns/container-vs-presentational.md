# Container vs Presentational Components

**Abstraction level**: pattern  
**Category**: frontend architecture

## Related Topics

- **Implementations of this**: smart vs dumb components
- **Depends on this**: props vs state
- **Works alongside**: component composition
- **Works alongside**: separation of concerns
- **Contrast with**: monolithic components
- **Contrast with**: MVC and MVVM UI layering
- **Temporal neighbors**: lifting state up
- **Temporal neighbors**: local vs global state

## What is it

Container vs presentational components is a pattern for splitting UI components by responsibility. A container component controls data that changes over time: loading it, storing it, transforming it, and deciding what happens when the user interacts. A presentational component focuses on displaying data and reporting user actions. The pattern is mainly about making data flow and ownership obvious.

In simple terms:

- **Data**: lists, selected items, loading flags, error messages, filtered results, form values
- **Where it lives**: usually in browser memory inside the UI layer
- **Who reads/writes it**: containers read and update important state; presentational components mostly read input and send events upward
- **How it changes over time**: user input, network responses, validation, filtering, and selection change the state; the new state is then rendered again

## What problem does it solve

Start with a simple screen: show a list of users and let the user select one. At first, one component can do everything. It can load the users, remember the selected user, filter the list, and render the buttons.

That is still manageable while the screen is small. Then more rules appear:

- show loading and error states
- disable some users
- sort active users first
- retry failed requests
- show different empty states

Now one component is doing four different jobs at once:

- storing changing data
- transforming raw data into display-ready data
- deciding what happens after user actions
- rendering markup

Without a clear split, common failures appear:

- **Duplication**: the same filtering or mapping logic gets repeated in multiple views
- **Inconsistency**: one part of the UI sorts or labels data differently from another
- **Invalid data**: the UI starts rendering half-prepared data because no single place finishes the transformation
- **Hard-to-track changes**: it is unclear which click or network response changed the state
- **Unclear ownership**: too many components update the same data, so no single source of truth exists

The pattern solves a control problem: who owns the data, who changes it, and who only shows it.

## How does it solve it

### 1. Separate control from display

The container handles the part of the system that changes over time. The presentational component handles the part that turns current data into visible output. This makes the split between "change the data" and "show the data" explicit.

### 2. Put state ownership in one place

If selected user, loading status, or current filter changes, there should be one obvious owner. The container becomes that owner. This improves predictability because state transitions happen in one place instead of being scattered across the tree.

### 3. Push prepared data downward

The presentational component should receive data that is already in a useful shape. Instead of giving it raw records and asking it to figure everything out, the container can pass final labels, sorted lists, booleans for enabled or disabled state, and display-ready values.

### 4. Pull user intent upward

The presentational component should not decide business behavior. It reports intent such as "user clicked retry" or "user selected item 42". The container receives that signal and decides how state should change.

### 5. Keep transformations explicit

Filtering, sorting, validation, and derivation are easier to reason about when they happen in the container. That keeps transformation logic out of rendering code and makes correctness easier to check.

### 6. Narrow component responsibilities

A presentational component can often be reused with different data sources because it only needs a known input shape. A container can change how data is fetched or derived without changing the view, as long as it still provides the same inputs and handles the same events.

## What if we didn't have it (Alternatives)

### 1. One component does everything

```text
UserList:
- load users
- store loading and error
- filter users
- render table
- handle selection
```

This is the common beginner approach. It works until changes in data rules and changes in UI layout start interfering with each other. The file becomes harder to read because storage, transformation, control, and rendering are mixed together.

### 2. Let the view decide data rules

```jsx
function UserListView({ users }) {
  const visibleUsers = users.filter(isActive)
  return renderList(visibleUsers)
}
```

This looks convenient, but now the display layer owns an important rule. If another view needs the same rule, duplication starts. If the rule changes, it can drift across components.

### 3. Let every child fetch or shape its own data

```text
UserCard(1) loads user 1
UserCard(2) loads user 2
UserCard(3) loads user 3
```

This creates fragmented ownership. Loading state becomes scattered, requests can duplicate, and the screen no longer has one clear place that says "this is the current state of the page".

### 4. Mutate shared data during rendering

```jsx
function ProductTable({ products }) {
  products.sort(byPrice)
  return renderRows(products)
}
```

This is a quick hack that hides transformation inside display code. Other parts of the system can no longer trust the original data, and debugging becomes harder because rendering changes state implicitly.

## Examples

### 1. Minimal concept

```text
Container owns: count = 3
View shows: "3" and an Increment button
```

When the button is clicked, the view sends "increment". The container changes `count` to `4` and sends the new value back down.

### 2. Small code example

```jsx
function UserListView({ users, onSelect }) {
  return users.map(user =>
    <button onClick={() => onSelect(user.id)}>
      {user.name}
    </button>
  )
}
```

This component does not know where `users` came from. It only renders data and emits user intent.

### 3. Container preparing data

```jsx
function UserListContainer({ users }) {
  const visibleUsers = users.filter(user => user.active)
  return <UserListView users={visibleUsers} onSelect={selectUser} />
}
```

The container takes raw data, applies a rule, and passes the result down. The view stays focused on output.

### 4. Incorrect vs correct split

Incorrect:

```jsx
function OrderTableView({ orders }) {
  const validOrders = orders.filter(order => order.status !== "cancelled")
  return renderTable(validOrders)
}
```

Correct:

```jsx
function OrderTableContainer({ orders }) {
  const validOrders = orders.filter(order => order.status !== "cancelled")
  return <OrderTableView orders={validOrders} />
}
```

The difference is ownership. In the correct version, the business rule lives in the control layer, not the display layer.

### 5. Browser interaction flow

```text
User types "ann"
Search container stores query = "ann"
Search container derives matching users
Search view renders input value and result list
```

Flow is explicit:

- input event goes up
- state changes in one place
- derived data comes back down

### 6. Same view, different containers

```jsx
<ProductGridView products={featuredProducts} onSelect={openProduct} />
<ProductGridView products={searchResults} onSelect={openProduct} />
```

The same presentational component can show different datasets because it depends on input shape, not on where the data came from.

### 7. Real-world analogy

```text
Kitchen: decides ingredients, recipe, timing
Waiter: carries finished dish and carries requests back
```

The kitchen is like the container: it owns transformation and control. The waiter is like the presentational component: it displays the result and passes intent back.

## Quickfire (Interview Q&A)

### 1. What is a container component?

A container component owns changing data and control logic for part of the UI. It decides how state changes and what data the view receives.

### 2. What is a presentational component?

A presentational component renders UI from input data and reports user actions. Its main job is display, not business control.

### 3. Why use this pattern?

It makes ownership, data flow, and state transitions easier to see. That usually reduces coupling and makes the UI easier to change.

### 4. Is this tied to one framework?

No. It is a design pattern for UI structure, not a framework feature.

### 5. What usually belongs in the container?

State, derived data, validation rules, loading and error handling, and action handling usually belong there.

### 6. What usually belongs in the presentational component?

Markup, visual structure, and event emission belong there. It should mostly work from the inputs it receives.

### 7. Does a presentational component have to be completely stateless?

No. It can hold small UI-only state, such as whether a dropdown is open, if that state does not become shared business state.

### 8. What is the biggest benefit in interviews to mention?

Clear ownership of changing data. Once ownership is clear, correctness and debugging both improve.

### 9. What is the trade-off?

It can introduce more files or more indirection. For very small components, the split may be more ceremony than value.

### 10. How is it different from a monolithic component?

A monolithic component mixes control and display in one place. This pattern separates them so each part has a narrower job.

## Key Takeaways

- This pattern is a way to control how UI data changes.
- Containers own important changing state.
- Presentational components focus on rendering and user intent.
- Data should usually flow down; events should usually flow up.
- Transformation logic is easier to reason about when it is explicit.
- Clear ownership reduces duplication and inconsistent behavior.
- Reuse becomes easier when display code depends on input shape, not data source.
- Use the pattern when screen logic is complex enough to justify the split.

## Vocabulary

### Nouns (concepts)

**Container component**  
A component that owns state, transformations, and action handling for a part of the UI. It is the control layer in this pattern.

**Presentational component**  
A component that displays data and emits user actions. It is the view layer in this pattern.

**State**  
Data that can change over time, such as selected item, loading flag, or current filter. Containers usually own the important state.

**Props**  
Inputs passed from one component to another. Presentational components typically receive most of what they need through props.

**Source of truth**  
The single place that is allowed to own and update a value. This pattern tries to make that place obvious.

**Derived data**  
Data computed from other data, such as a filtered list or formatted label. Containers often derive data before passing it to the view.

**Event**  
A signal that something happened, such as a click or text input. Presentational components emit events so containers can decide the next state.

**Responsibility**  
The specific job a component owns. The pattern works by making each component responsible for fewer things.

**Coupling**  
How much one part depends on another part's internal details. Lower coupling makes components easier to reuse and change.

### Verbs (actions)

**Render**  
To turn current data into visible UI. This is the main job of a presentational component.

**Own**  
To be the place that controls and updates a value. Containers usually own important screen state.

**Transform**  
To change data into a more useful shape, such as sorting, filtering, or formatting it. This is easier to reason about when done before rendering.

**Derive**  
To calculate new data from existing data. Derived data should usually be created explicitly, not hidden inside markup.

**Pass down**  
To send data or callbacks from a parent to a child component. This is the main direction of data flow here.

**Emit**  
To send a signal upward that the user did something. A presentational component emits intent instead of directly changing shared state.

### Adjectives (properties)

**Presentational**  
Focused on showing data rather than controlling it. A presentational component should be understandable from its inputs.

**Stateful**  
Holding data that changes over time. Containers are often stateful because they manage transitions.

**Reusable**  
Easy to use in multiple places without changing internal logic. Presentational components become more reusable when they depend only on input shape.

**Predictable**  
Easy to reason about because ownership and flow are explicit. This is one of the main goals of the pattern.

**Implicit**  
Hidden rather than directly stated in the structure. Implicit ownership and implicit mutation usually make bugs harder to find.

**Explicit**  
Clearly visible in the code structure. Explicit ownership and explicit flow make UI behavior easier to explain in an interview.
