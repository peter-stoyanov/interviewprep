# Component Composition

**Abstraction level**: pattern
**Category**: frontend architecture / UI design

---

## Related Topics

- **Implementations of this**: React `children` prop, render props, compound components, slots (Vue/Web Components)
- **Depends on this**: design systems, reusable UI libraries, layout components
- **Works alongside**: props/state, context API, container vs presentational components
- **Contrast with**: inheritance-based UI design, prop drilling, monolithic components
- **Temporal neighbors**: learn props/state first; leads into context and custom hooks

---

## What is it

Component composition is a pattern where complex UI is built by combining small, focused components rather than building one large component that handles everything. Each component does one thing well, and you assemble them like building blocks.

- **Data**: props flowing down, children passed as UI trees
- **Where it lives**: entirely in the component tree (browser memory, virtual DOM)
- **Who reads/writes**: parent components decide structure; child components render their own output
- **How it changes**: you swap, nest, or wrap components to change the UI without modifying existing components

---

## What problem does it solve

Start with a button that needs a label and an icon. You could build one `<Button>` that accepts an `icon` prop, an `iconPosition` prop, a `label` prop, a `size` prop, a `variant` prop... and it keeps growing.

**Without composition**, a single component accumulates every variation:

```jsx
<Button icon="star" iconPosition="left" label="Save" size="lg" variant="primary" disabled />
```

Problems:
- The component grows unbounded — every new use case adds props
- Internal branching logic becomes hard to follow
- Reusing just the icon part is impossible without copy-paste
- Testing requires covering every prop combination
- One change can break unrelated use cases

The component becomes a "god component" — it owns too much logic and too many responsibilities.

---

## How does it solve it

### 1. Children as composition slots

Instead of accepting configuration props, a component accepts other components as `children`. The parent decides what goes inside; the child just provides structure or behavior.

```jsx
<Button>
  <Icon name="star" />
  Save
</Button>
```

`Button` renders its children without knowing or caring what they are. The caller controls the content.

### 2. Single responsibility per component

Each component does exactly one thing. A `Card` provides a bordered container. A `CardHeader` provides a title area. A `CardBody` provides padded content. You compose them.

```jsx
<Card>
  <CardHeader>Settings</CardHeader>
  <CardBody>...</CardBody>
</Card>
```

### 3. Flexibility without prop explosion

Composition replaces configuration. Instead of `showHeader={true}` and `headerTitle="x"`, you just pass a `<CardHeader>` or you don't. The parent makes that decision.

### 4. Open/closed principle

Composed components are open to extension (add new children) but closed to modification (you don't need to change `Card` to support new use cases).

### 5. Inversion of control (partial)

The component that provides structure delegates content decisions to whoever uses it. This is lightweight inversion of control — the parent controls the what, the child controls the how.

---

## What if we didn't have it

### Approach 1: Monolithic component with many props

```jsx
<DataTable
  showHeader={true}
  showFooter={false}
  sortable={true}
  paginated={true}
  rowsPerPage={10}
  onRowClick={...}
  emptyStateMessage="No results"
  columns={[...]}
  data={[...]}
/>
```

Every feature becomes a prop. The component has dozens of branches. Adding a new feature requires modifying the component directly. Testing it requires covering all combinations.

**Breaks at**: scale, new feature requests, and when two teams need different behavior.

### Approach 2: Inheritance (class-based)

```js
class SpecialButton extends Button {
  render() { ... }
}
```

This creates tight coupling. `SpecialButton` depends on `Button`'s internal structure. If `Button` changes, `SpecialButton` can break silently.

**Breaks at**: refactoring, because subclasses depend on internals.

### Approach 3: Copy-paste components

Duplicate `Button` as `IconButton`, `LoadingButton`, `DangerButton`. Each starts identical but drifts over time.

**Breaks at**: maintenance — fixing a bug in one does not fix it in the others.

---

## Examples

### Example 1: Minimal — children as content

```jsx
function Box({ children }) {
  return <div className="box">{children}</div>;
}

// Usage
<Box>
  <p>Hello</p>
</Box>
```

`Box` provides layout. The caller provides content. Neither knows about the other's internals.

---

### Example 2: Composing multiple child components

```jsx
function Modal({ children }) {
  return <div className="modal">{children}</div>;
}

function ModalHeader({ children }) {
  return <div className="modal-header">{children}</div>;
}

function ModalBody({ children }) {
  return <div className="modal-body">{children}</div>;
}

// Usage
<Modal>
  <ModalHeader>Confirm Delete</ModalHeader>
  <ModalBody>Are you sure?</ModalBody>
</Modal>
```

Each sub-component is individually testable and replaceable. You can render `ModalBody` in isolation.

---

### Example 3: Avoiding a prop explosion

**Before composition:**
```jsx
<Button loading={true} loadingText="Saving..." icon="check" iconPosition="left" />
```

**After composition:**
```jsx
<Button>
  <Spinner size="sm" />
  Saving...
</Button>
```

The button renders its children. You compose the loading state from outside.

---

### Example 4: Flexible layout with named slots (via props)

When you need more than one content area, pass components as named props:

```jsx
function Layout({ header, sidebar, children }) {
  return (
    <div>
      <header>{header}</header>
      <aside>{sidebar}</aside>
      <main>{children}</main>
    </div>
  );
}

// Usage
<Layout
  header={<NavBar />}
  sidebar={<SideMenu />}
>
  <PageContent />
</Layout>
```

`Layout` does not know what `NavBar`, `SideMenu`, or `PageContent` are. It only knows where to place them.

---

### Example 5: Compound component pattern

Related components share implicit context through a parent component, providing a clean API:

```jsx
<Tabs>
  <Tab label="Overview">...</Tab>
  <Tab label="Details">...</Tab>
</Tabs>
```

Internally, `Tabs` manages which tab is active. Each `Tab` renders based on that state. The caller composes the tabs without managing the active state themselves.

---

### Example 6: Correct vs incorrect usage

**Incorrect** — accepting too many config props:
```jsx
<UserCard showAvatar={true} avatarSize="lg" showBio={false} showFollowButton={true} />
```

**Correct** — composing from the outside:
```jsx
<UserCard>
  <Avatar size="lg" src={user.avatar} />
  <FollowButton userId={user.id} />
</UserCard>
```

The second form is easier to extend, test, and understand.

---

## Quickfire (Interview Q&A)

**Q: What is component composition?**
Building complex UIs by combining small, focused components rather than building a single large component that handles everything.

**Q: Why prefer composition over inheritance in UI?**
Inheritance creates tight coupling to internal implementation details; composition lets components collaborate without depending on each other's internals.

**Q: What is the `children` prop?**
A special prop in React that holds whatever JSX is passed between opening and closing component tags, allowing the parent to inject content.

**Q: What problem does composition solve?**
It prevents "god components" — components that accumulate too many props and responsibilities as requirements grow.

**Q: What is a compound component?**
A group of related components that work together and share state implicitly through a parent, exposing a clean and composable API.

**Q: How is composition different from prop drilling?**
Composition passes UI structure (components) as children/props; prop drilling passes data through intermediate components that don't use it.

**Q: When would you use named prop slots instead of `children`?**
When a component has multiple distinct content areas (e.g., header, sidebar, footer) that need separate placement.

**Q: What is the open/closed principle in the context of composition?**
A composed component is open to extension (callers can pass new children) without needing to modify the component itself.

**Q: Can composition replace all use of props?**
No — props are still used for behavior, data, and configuration. Composition is specifically about delegating content and structure to the caller.

**Q: What goes wrong with monolithic components?**
They accumulate props, branches, and responsibilities until they are too complex to understand, test, or safely change.

---

## Key Takeaways

- Composition means combining small components rather than configuring one large one.
- The `children` prop is the simplest form of composition — it lets callers control content.
- Named prop slots extend composition to components with multiple content regions.
- Composition replaces prop explosion by moving decisions from props to structure.
- Composed components are independently testable and reusable.
- React favors composition over inheritance for building UI.
- The pattern enforces single responsibility: each component does one thing well.

---

## Vocabulary

### Nouns (concepts)

**Component**: A reusable, self-contained unit of UI that accepts inputs (props) and returns markup.

**Composition**: Combining components by nesting or passing them to each other, rather than building one monolithic unit.

**`children` prop**: The built-in React prop that holds JSX elements passed between a component's opening and closing tags.

**Named slot**: A prop that accepts a component or JSX as its value, used when a layout has multiple distinct content areas.

**Compound component**: A pattern where a parent component and its child components share implicit state to form a cohesive API.

**God component**: An anti-pattern where one component accumulates too many responsibilities, props, and conditional branches.

**Prop explosion**: When a component's API grows uncontrollably because every variation is expressed as a new prop.

**Inversion of control**: Delegating decisions about content or behavior to the caller rather than encoding them inside the component.

### Verbs (actions)

**Compose**: Combine components by nesting or passing them as props/children.

**Delegate**: Hand off a decision (e.g., what content to render) to the component's consumer rather than deciding internally.

**Nest**: Place one component inside another in JSX to establish a parent-child relationship.

**Render**: Execute a component to produce its output UI.

### Adjectives (properties)

**Reusable**: A component that can be used in multiple contexts without modification.

**Decoupled**: Components that do not depend on each other's internal implementation.

**Composable**: Designed to be combined easily with other components.

**Monolithic**: A single component that handles too many concerns — the opposite of composable.
