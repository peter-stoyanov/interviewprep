# React Functional Components and JSX

**Abstraction level**: language feature / library pattern
**Category**: frontend UI, component architecture

---

## Related Topics

- **Depends on this**: hooks (useState, useEffect), component composition, props and data flow
- **Works alongside**: React rendering model, virtual DOM, event handling
- **Implementations of this**: class components (older React pattern)
- **Contrast with**: class components, template-based UI (Vue, Angular)
- **Temporal neighbors**: learn JavaScript functions and closures first; leads to hooks and lifecycle next

---

## What is it

A functional component is a plain JavaScript function that accepts an object of inputs (called `props`) and returns a description of UI (called JSX). JSX is a syntax extension that looks like HTML but compiles to regular JavaScript function calls.

The data is: the props passed in, plus any local state inside the function. It lives in memory in the browser's JavaScript runtime. React calls (renders) the function to figure out what the UI should look like. It re-calls the function whenever data changes.

---

## What problem does it solve

UI is fundamentally: data rendered visually, updated when that data changes.

Without a system like this:

1. You write HTML manually in the DOM. You mutate it directly with `document.getElementById(...).textContent = ...`.
2. When data changes, you find the right DOM nodes and update them by hand.
3. When the app grows — dozens of interactive elements — you lose track of which DOM node reflects which piece of data.

**Failure modes without components:**

- **Duplication**: the same "card" structure written five times in HTML, five times in JS update code
- **Inconsistency**: you update the DOM in one place but forget another; UI and data are out of sync
- **Hard-to-track changes**: a global event listener mutates DOM from anywhere; no clear ownership
- **No reuse**: logic and markup are tangled; pulling one piece out breaks the other

Functional components solve this by making UI a **pure function of data**: given the same input, always produce the same output. Change the data → re-run the function → new UI. No manual DOM mutation.

---

## How does it solve it

### 1. UI as a function of data

A component is just: `(props) => description of UI`. React owns when to call it. You never manually say "go update this div." You say "here is what the UI should look like given this data."

This separates: **what the UI should be** (your function) from **how to make the DOM match** (React's job).

### 2. Encapsulation via function scope

Each component is a function. Its local variables are local. Logic, markup, and handlers live together in one place. This is the same encapsulation you get from any function — nothing special.

### 3. Composition over inheritance

Small components return JSX that includes other components. You build complex UI by nesting simple functions. Data flows down through props. No shared mutable state outside the function.

### 4. JSX compiles to plain JavaScript

JSX is not a separate language. `<div className="card">Hello</div>` compiles to:

```js
React.createElement("div", { className: "card" }, "Hello")
```

`React.createElement` returns a plain JavaScript object — a description of a UI node, not an actual DOM element. React uses these descriptions to figure out what to create or update in the real DOM.

### 5. Declarative, not imperative

You declare what should exist. React decides how to make it exist. This is the opposite of `document.createElement` + `appendChild` sequences.

---

## What if we didn't have it (Alternatives)

### Manual DOM manipulation

```js
const el = document.getElementById("username");
el.textContent = user.name;
el.className = user.isAdmin ? "admin" : "user";
```

Works for one element. With 50 elements and async data, it becomes unmaintainable. Changes anywhere can corrupt state elsewhere.

### Class components (older React)

```js
class MyComponent extends React.Component {
  render() {
    return <div>{this.props.name}</div>;
  }
}
```

Same declarative benefit, but more boilerplate. `this` binding is a common source of bugs. Logic is split across lifecycle methods (`componentDidMount`, `componentDidUpdate`) rather than co-located. Functional components with hooks replaced this pattern.

### Template strings + innerHTML

```js
container.innerHTML = `<div class="card">${user.name}</div>`;
```

Simple, but re-renders the entire subtree. Wipes event listeners. XSS risk if data is unsanitized. No diffing, no efficiency.

---

## Examples

### Example 1: Minimal functional component

```jsx
function Greeting(props) {
  return <h1>Hello, {props.name}</h1>;
}
```

A function takes data in (`props.name`), returns a UI description. Nothing else. This is the entire pattern.

---

### Example 2: JSX compiles to createElement

```jsx
// What you write:
<button className="btn" onClick={handleClick}>
  Submit
</button>

// What it compiles to:
React.createElement(
  "button",
  { className: "btn", onClick: handleClick },
  "Submit"
)
```

JSX is syntactic sugar. The output is a JavaScript object, not DOM. React reads the object and updates the DOM.

---

### Example 3: Props as inputs, JSX as output

```jsx
function Badge({ label, count }) {
  return (
    <span className="badge">
      {label}: {count}
    </span>
  );
}

// Usage:
<Badge label="Errors" count={4} />
<Badge label="Warnings" count={12} />
```

Same function, different data, different output. Reusable without duplication.

---

### Example 4: Conditional rendering

```jsx
function Status({ isOnline }) {
  return (
    <div>
      {isOnline ? <span>Online</span> : <span>Offline</span>}
    </div>
  );
}
```

The condition is just a JavaScript expression inside JSX. No special directive syntax. Data controls output.

---

### Example 5: Rendering a list

```jsx
function UserList({ users }) {
  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

`Array.map` transforms data (an array of objects) into a description of UI (an array of `<li>` elements). The `key` prop helps React track which items changed.

---

### Example 6: Incorrect vs correct — mutating instead of describing

```jsx
// Wrong: imperative DOM mutation inside a component
function BadCounter() {
  document.getElementById("count").textContent = 5; // side effect, bypasses React
  return <div id="count"></div>;
}

// Correct: describe what the UI should look like given the data
function Counter({ count }) {
  return <div>{count}</div>;
}
```

The wrong version bypasses React's control. The correct version lets React own the DOM update.

---

### Example 7: Composition

```jsx
function Avatar({ src, alt }) {
  return <img src={src} alt={alt} className="avatar" />;
}

function UserCard({ user }) {
  return (
    <div className="card">
      <Avatar src={user.photo} alt={user.name} />
      <p>{user.name}</p>
    </div>
  );
}
```

`UserCard` composes `Avatar`. Each function is small and does one thing. Complex UI emerges from nesting simple components.

---

## Quickfire (Interview Q&A)

**Q: What is a functional component?**
A: A JavaScript function that takes props and returns JSX — a description of what the UI should look like.

**Q: What is JSX?**
A: A syntax extension for JavaScript that lets you write HTML-like markup inside JS. It compiles to `React.createElement()` calls.

**Q: What does JSX compile to?**
A: Plain JavaScript objects via `React.createElement(type, props, ...children)`.

**Q: What are props?**
A: An object of inputs passed from a parent component to a child component. They are read-only inside the child.

**Q: Why can't you modify props directly?**
A: Props are owned by the parent. Modifying them inside the child would be a side effect that breaks unidirectional data flow.

**Q: What is the difference between functional and class components?**
A: Functional components are plain functions; class components extend `React.Component` and use `this`. Both are valid, but functional components with hooks are the current standard.

**Q: Why does React need a `key` prop when rendering lists?**
A: `key` lets React identify which list items changed, were added, or removed — so it can update only the necessary DOM nodes instead of re-rendering the whole list.

**Q: What does "declarative UI" mean?**
A: You describe what the UI should look like for a given state. React figures out how to update the DOM to match. You don't write step-by-step DOM manipulation.

**Q: Can a functional component return multiple root elements?**
A: Not directly. You must wrap them in a single parent element or a Fragment (`<>...</>`), which renders no extra DOM node.

**Q: What is a React Fragment?**
A: A wrapper (`<React.Fragment>` or `<>`) that lets you return multiple elements without adding an extra DOM node.

---

## Key Takeaways

- A functional component is just a function: takes data (props) in, returns a UI description (JSX) out.
- JSX is not HTML — it compiles to `React.createElement()` calls that produce plain JavaScript objects.
- React owns DOM updates. Your job is to describe what the UI should look like; React's job is to make the DOM match.
- Props flow down from parent to child. They are read-only inside the child.
- Composition is how you build complex UI — nest simple components, each doing one thing.
- The `key` prop in lists is a performance and correctness hint to React's reconciler.
- Declarative UI means you express desired state, not imperative steps to get there.

---

## Vocabulary

### Nouns (concepts)

**Functional component** — A JavaScript function that accepts props and returns JSX. The primary building block of React UI.

**JSX** — JavaScript XML. A syntax extension that lets you write markup inside JavaScript. Compiled by Babel/transpilers into `React.createElement` calls before the browser runs it.

**Props** — Short for "properties." An object passed from parent to child component containing input data. Read-only inside the receiving component.

**React element** — The plain JavaScript object returned by `React.createElement` (or JSX). Describes a node in the UI tree. Not a real DOM element.

**Virtual DOM** — React's in-memory representation of the UI tree, made up of React elements. React diffs this against the previous version to determine the minimal DOM changes needed.

**Fragment** — A React wrapper (`<>` or `<React.Fragment>`) that groups multiple elements without rendering an extra DOM node.

**Key** — A special prop on list items that helps React identify which items changed between renders. Must be stable and unique within a list.

**Component tree** — The nested hierarchy of components that make up an application's UI.

### Verbs (actions)

**Render** — When React calls your component function to get a description of the UI. Happens on first mount and whenever data changes.

**Mount** — When a component is first added to the DOM.

**Unmount** — When a component is removed from the DOM.

**Compose** — Nesting smaller components inside larger ones to build up complex UI from simple pieces.

**Compile** — What Babel/transpilers do to JSX: transform it into plain JavaScript (`React.createElement` calls) before the browser runs it.

**Reconcile** — React's process of comparing the new virtual DOM tree to the previous one and applying only the necessary changes to the real DOM.

### Adjectives (properties)

**Declarative** — Expressing *what* the UI should look like, not *how* to build it step by step.

**Imperative** — Expressing *how* to produce a result step by step (e.g., manual DOM manipulation). The opposite of declarative.

**Pure** — A function is pure if, given the same inputs, it always returns the same output with no side effects. React components are expected to be pure with respect to rendering.

**Unidirectional** — Data flows in one direction: from parent to child via props. Changes propagate downward, not upward.

**Reusable** — A component that can be used in multiple places with different props without modification.
