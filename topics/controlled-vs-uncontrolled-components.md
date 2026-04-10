# Controlled vs Uncontrolled Components

- **Abstraction level**: concept / pattern
- **Category**: frontend architecture, UI component design

---

## Related Topics

- **Implementations of this**: React `useState` + form inputs, React Hook Form (uncontrolled), HTML native form submission
- **Depends on this**: form validation, derived state, two-way data binding
- **Works alongside**: state management patterns, input validation, form libraries
- **Contrast with**: two-way binding (Angular), derived state, lifting state up
- **Temporal neighbors**: learn after state basics; learn before complex form handling

---

## What is it

A controlled component is one where the UI element's value is driven by data in your program — you read it from state, and you write it back via an event handler. An uncontrolled component lets the DOM (or the native element itself) hold its own value, and you read it only when needed.

The core distinction: **who owns the data?**

- **Controlled**: your code owns the value. The input renders what you tell it to.
- **Uncontrolled**: the DOM owns the value. You reach in and read it when needed.

Where does the data live?

- Controlled → application memory (state variable)
- Uncontrolled → the DOM node itself

Who reads/writes it?

- Controlled → every keystroke updates state; state re-renders the input
- Uncontrolled → user types freely; you read the value on submit or on demand

---

## What problem does it solve

### The problem: form inputs have their own internal state

HTML inputs are stateful by default. A `<input type="text">` keeps its own value inside the DOM. If your app also tracks that value somewhere, you now have **two sources of truth** — and they can diverge.

**Simple case**: user types "hello". DOM says "hello". Your variable says... whatever you last set it to.

**Complexity grows when**:
- You need to validate on every keystroke
- You need to clear a field programmatically
- You need to derive something from the current value (character count, real-time search)
- You need to sync the field with external data (edit form pre-filled from an API)

**Failure modes without a clear strategy**:
- You read the DOM directly in some places and state in others → inconsistency
- You try to set an input's value programmatically but the DOM ignores it → buggy behavior
- Validation runs against stale data → invalid submissions get through
- Two components both try to control the same field → conflicts

---

## How does it solve it

### Controlled: make state the single source of truth

**Principle 1 — one owner**: the input value is stored in state. The DOM just reflects it. The user cannot change the DOM without going through your event handler.

**Principle 2 — explicit flow**: every change is visible. Value flows down (state → input), changes flow up (event → state update → re-render).

**Principle 3 — full control**: because you intercept every keystroke, you can validate, transform, or reject input before it is committed to state.

### Uncontrolled: let the DOM own it, read on demand

**Principle 1 — minimal overhead**: you do not track the value on every keystroke. The input manages itself.

**Principle 2 — read when needed**: use a ref to access the DOM node and read its current value — typically on form submit.

**Principle 3 — lower coupling**: the component does not need to re-render on every character typed. Useful for performance-sensitive cases or when you do not need live access to the value.

---

## What if we didn't have it (Alternatives)

### Naive: read from the DOM directly

```js
function handleSubmit() {
  const val = document.getElementById('username').value;
}
```

Breaks at scale because:
- No connection to component lifecycle
- Brittle to DOM structure changes
- Cannot validate or transform while typing
- Impossible to reset or pre-fill declaratively

### Naive: duplicate state and DOM value separately

```js
let localVar = '';
input.addEventListener('input', e => { localVar = e.target.value; });
```

Breaks because:
- `localVar` and the DOM can silently diverge
- No re-render mechanism
- No guarantee of consistency across components

### Common beginner mistake: control the value but forget the handler

```jsx
<input value={name} />  // no onChange
```

This creates a read-only input — the user types but the DOM snaps back. This is a bug, not a feature. You must pair `value` with `onChange` in a controlled component.

---

## Examples

### Example 1 — uncontrolled (simplest case)

```jsx
function Form() {
  const inputRef = useRef();

  function handleSubmit() {
    console.log(inputRef.current.value); // read once, on submit
  }

  return <input ref={inputRef} defaultValue="initial" />;
}
```

The DOM owns the value. `defaultValue` sets it once at mount. You never track it between keystrokes.

---

### Example 2 — controlled (single source of truth)

```jsx
function Form() {
  const [name, setName] = useState('');

  return (
    <input
      value={name}
      onChange={e => setName(e.target.value)}
    />
  );
}
```

State owns the value. Every keystroke → `onChange` → `setName` → re-render → input reflects new state. The loop is explicit.

---

### Example 3 — why controlled enables live validation

```jsx
const [email, setEmail] = useState('');
const isValid = email.includes('@');

<input value={email} onChange={e => setEmail(e.target.value)} />
<span>{isValid ? 'Valid' : 'Enter a valid email'}</span>
```

Because you have the value in state at every moment, you can derive `isValid` on every render. This is impossible with an uncontrolled input without polling the DOM.

---

### Example 4 — controlled enables programmatic reset

```jsx
function Form() {
  const [value, setValue] = useState('');

  function reset() {
    setValue('');  // input instantly clears
  }

  return (
    <>
      <input value={value} onChange={e => setValue(e.target.value)} />
      <button onClick={reset}>Clear</button>
    </>
  );
}
```

With an uncontrolled input, you would need to manually reach into the DOM ref and set `.value = ''` — which works but feels like a side effect, not a state transition.

---

### Example 5 — pre-filling from API (controlled shines)

```jsx
const [form, setForm] = useState({ name: '', email: '' });

useEffect(() => {
  fetchUser(id).then(user => setForm(user));
}, [id]);

<input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
```

The form is pre-filled by updating state. The input reflects it automatically. With an uncontrolled approach, you would need to imperatively set the ref's `.value` after the fetch — possible but error-prone.

---

### Example 6 — incorrect vs correct: the missing onChange trap

```jsx
// Incorrect — read-only, user cannot type
<input value={query} />

// Correct — controlled
<input value={query} onChange={e => setQuery(e.target.value)} />

// Also correct — uncontrolled with default
<input defaultValue={query} ref={inputRef} />
```

`value` without `onChange` is not controlled — it is frozen. `defaultValue` sets initial value for uncontrolled inputs without taking over ownership.

---

## Quickfire (Interview Q&A)

**Q: What makes a component "controlled"?**
A: Its value is driven by state, and every change goes through an event handler that updates that state.

**Q: What is `defaultValue` vs `value`?**
A: `value` gives full control to your code (controlled). `defaultValue` sets an initial value once and then lets the DOM manage it (uncontrolled).

**Q: Why can't you just use `value` without `onChange`?**
A: The input becomes read-only — React prevents the DOM from changing a value it controls, so user input is ignored.

**Q: When should you prefer uncontrolled components?**
A: When you only need the value at submit time, when performance matters (avoiding re-renders per keystroke), or when integrating with non-React libraries.

**Q: What is a ref used for in uncontrolled inputs?**
A: It gives you direct access to the DOM node so you can read its current value when needed.

**Q: What is the main trade-off between controlled and uncontrolled?**
A: Controlled gives you full visibility and control at the cost of more wiring. Uncontrolled is simpler but you have less insight into the value between submit events.

**Q: Can you mix controlled and uncontrolled in one form?**
A: Technically yes, but it is bad practice. Inconsistent ownership makes validation and data collection harder to reason about.

**Q: How does a controlled input enable real-time features?**
A: Because the value is in state at every render, you can derive anything from it — validation, character count, search suggestions — without reading the DOM.

**Q: What is "lifting state up" in the context of controlled components?**
A: Moving the value and handler to a parent component so that multiple children can share and react to the same data.

**Q: How do form libraries like React Hook Form handle this?**
A: They typically use uncontrolled inputs with refs by default to avoid per-keystroke re-renders, then collect values on submit.

---

## Key Takeaways

- A controlled component stores its value in state; every user change updates that state through an explicit event handler.
- An uncontrolled component lets the DOM own its value; you read it on demand via a ref.
- `value` = controlled. `defaultValue` = uncontrolled. Never mix them on the same input.
- `value` without `onChange` is a bug — it creates a frozen, read-only input.
- Controlled components enable live validation, programmatic resets, and pre-filling because the value is always in state.
- Uncontrolled components are simpler and avoid per-keystroke re-renders — useful for simple forms or performance-sensitive scenarios.
- The core question is always: who owns the data — your code or the DOM?

---

## Vocabulary

### Nouns (concepts)

**Controlled component** — a UI element whose current value is stored in application state and rendered from it. The component cannot change its own value without going through the state update mechanism.

**Uncontrolled component** — a UI element that manages its own value internally in the DOM. The application reads the value only when needed, typically via a ref.

**Single source of truth** — the principle that a piece of data should be stored in exactly one place. In controlled components, state is the single source of truth for the input value.

**Ref** — a reference to a DOM node or component instance. Used in uncontrolled components to access the current value without tracking it in state.

**`defaultValue`** — the HTML/JSX attribute used to set the initial value of an uncontrolled input. Unlike `value`, it does not maintain ongoing control over the input.

**`value`** — the attribute that makes an input controlled. React enforces that the DOM reflects this value exactly; changes require an `onChange` handler.

**Two-way data binding** — a pattern where UI and data model stay automatically in sync. Controlled components implement this explicitly: state → input, event → state.

**Derived state** — data computed from existing state rather than stored separately. Controlled inputs make derivation easy because the value is always available in state.

### Verbs (actions)

**Lift state up** — move a state variable to a common ancestor so multiple components can share it. Common when a controlled input's value is needed by a sibling.

**Intercept** — to catch an event (like a keystroke) before it changes the DOM, allowing you to validate or transform the value first.

**Hydrate / pre-fill** — populate an input with initial data, typically from an API response. Straightforward with controlled components (set state), possible but awkward with uncontrolled ones.

### Adjectives (properties)

**Controlled** — describes an input whose value is owned and managed by application state.

**Uncontrolled** — describes an input whose value is owned by the DOM; the application observes rather than manages it.

**Read-only** — an input with `value` but no `onChange` — a common bug where the user cannot type because React reverts every change.

**Stateful** — having internal state that persists and changes over time. All HTML inputs are natively stateful; the controlled/uncontrolled distinction is about who manages that state.
