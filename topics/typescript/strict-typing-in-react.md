# Strict Typing in React

**Abstraction level**: pattern / language feature application
**Category**: frontend type safety, React development

---

## Related Topics

- **Depends on this**: component API design, prop validation, form handling with types
- **Implementations of this**: TypeScript with React (`@types/react`), Flow (less common now)
- **Works alongside**: generics, utility types, type narrowing, React hooks
- **Contrast with**: PropTypes (runtime validation vs compile-time), plain JavaScript React
- **Temporal neighbors**: learn TypeScript basics first, then generics and utility types

---

## What is it

Strict typing in React means annotating components, props, state, events, and hooks with TypeScript types so the compiler can verify correctness before the code runs.

- **Data**: props and state are the data. Types describe what shape that data must have.
- **Where it lives**: entirely in the development toolchain — TypeScript is erased at runtime.
- **Who reads/writes it**: the developer reads and writes types; the compiler enforces them.
- **How it changes**: types do not change at runtime, but they constrain what values are allowed to flow through components.

---

## What problem does it solve

React components communicate through props. Without types, a component can be called with wrong data, missing required values, or unexpected shapes — and nothing catches this until the app crashes at runtime.

**The problem grows as complexity grows:**

1. A button accepts `onClick` and `label`. Fine with two props.
2. A form has 12 fields, validation state, and 4 callbacks. Hard to remember what each prop expects.
3. A refactor renames `onSubmit` to `handleSubmit` — callers silently break.
4. A prop accepts either a string or number — code in the component assumes one but gets the other.

**Failure modes without strict typing:**

- Passing `undefined` where a value is expected → runtime crash
- Passing wrong prop shape → silent wrong behavior
- Missing required props → broken UI with no error
- Refactoring breaks callers → only discovered in QA or production
- Event handlers typed as `any` → bugs from accessing wrong properties

---

## How does it solve it

### 1. Props as a typed contract

Props are the interface between a parent and a child component. Typing them makes that contract explicit and machine-checked.

If a prop is required, the compiler will catch any caller that forgets it. If a prop is a specific union type, no invalid value can be passed.

### 2. State shape is known

When you type `useState<T>()`, TypeScript knows the shape of state for the entire lifetime of that variable. You cannot accidentally assign the wrong type to it.

### 3. Events are typed, not guessed

React event handlers have specific types (`React.ChangeEvent<HTMLInputElement>`, `React.FormEvent<HTMLFormElement>`). Typing them gives you access to the correct properties (`event.target.value`) without guessing.

### 4. Return types of components are enforced

Typing a component's return as `JSX.Element` or `React.ReactNode` ensures the component always returns valid renderable output.

### 5. Generic components can work across types

A `List<T>` component can be written once and work with any item type, while still enforcing that the `renderItem` prop matches the item type. No duplication, no `any`.

---

## What if we didn't have it (Alternatives)

### PropTypes (runtime validation)

```js
Button.propTypes = {
  label: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
};
```

Only validates at runtime, only in development mode. No editor autocomplete. No protection during refactors. Removed in React 19 from the core library.

### Untyped props (plain JS)

```js
function Button({ label, onClick }) {
  return <button onClick={onClick}>{label}</button>;
}
```

No enforcement. A caller can pass `label={42}` or omit `onClick`. The component renders wrong or crashes. No IDE help when writing callers.

### JSDoc comments

```js
/** @param {{ label: string, onClick: () => void }} props */
function Button(props) { ... }
```

Provides some editor hints but is fragile, verbose, and not enforced by the compiler in most setups. Does not scale to complex types.

---

## Examples

### Example 1 — Basic typed props

```tsx
type ButtonProps = {
  label: string;
  onClick: () => void;
  disabled?: boolean;
};

function Button({ label, onClick, disabled = false }: ButtonProps) {
  return <button onClick={onClick} disabled={disabled}>{label}</button>;
}

// Compiler error: missing required prop `onClick`
<Button label="Submit" />

// Compiler error: wrong type for `disabled`
<Button label="Submit" onClick={() => {}} disabled="yes" />
```

The type makes the contract clear. Callers get autocomplete and error messages immediately.

---

### Example 2 — Typed state

```tsx
type User = { id: number; name: string };

const [user, setUser] = useState<User | null>(null);

// Compiler error: cannot assign a string to User | null
setUser("hello");

// Correct
setUser({ id: 1, name: "Alice" });
```

TypeScript knows the shape of `user` throughout the component. Narrowing (`if (user !== null)`) unlocks the `User` properties safely.

---

### Example 3 — Typed event handlers

```tsx
function SearchInput() {
  const [query, setQuery] = useState("");

  // event is typed: React.ChangeEvent<HTMLInputElement>
  function handleChange(event: React.ChangeEvent<HTMLInputElement>) {
    setQuery(event.target.value); // .value is known to exist
  }

  return <input value={query} onChange={handleChange} />;
}
```

Without the type, `event.target.value` requires you to know the element type. With the type, the compiler confirms the property exists.

---

### Example 4 — Union types for controlled variants

```tsx
type AlertProps = {
  message: string;
  variant: "info" | "warning" | "error";
};

function Alert({ message, variant }: AlertProps) {
  return <div className={`alert alert--${variant}`}>{message}</div>;
}

// Compiler error: "danger" is not assignable to "info" | "warning" | "error"
<Alert message="Watch out" variant="danger" />
```

Union types turn free-text props into a closed set of valid values. No need for runtime checks.

---

### Example 5 — Generic component

```tsx
type ListProps<T> = {
  items: T[];
  renderItem: (item: T) => React.ReactNode;
};

function List<T>({ items, renderItem }: ListProps<T>) {
  return <ul>{items.map((item, i) => <li key={i}>{renderItem(item)}</li>)}</ul>;
}

// TypeScript infers T = string
<List items={["a", "b"]} renderItem={(item) => <span>{item}</span>} />

// TypeScript infers T = { id: number; name: string }
<List items={users} renderItem={(u) => <span>{u.name}</span>} />
```

One component, fully type-safe for any item type.

---

### Example 6 — Incorrect vs correct: forwardRef

```tsx
// Without type — ref is any, no safety
const Input = forwardRef((props, ref) => <input ref={ref} {...props} />);

// With type — ref is constrained to HTMLInputElement
const Input = forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(
  (props, ref) => <input ref={ref} {...props} />
);

// Now callers cannot pass a ref intended for a div
const ref = useRef<HTMLInputElement>(null);
<Input ref={ref} />
```

Typing `forwardRef` catches mismatched ref usage that is otherwise invisible.

---

### Example 7 — Children typed explicitly

```tsx
type CardProps = {
  title: string;
  children: React.ReactNode; // anything renderable
};

function Card({ title, children }: CardProps) {
  return (
    <div>
      <h2>{title}</h2>
      {children}
    </div>
  );
}
```

`React.ReactNode` is the broadest renderable type: strings, elements, arrays, null. Use `React.ReactElement` when only JSX is acceptable.

---

## Quickfire (Interview Q&A)

**Q: What is the difference between `React.FC` and a plain function component?**
`React.FC` used to implicitly include `children` in props (removed in newer versions). Plain function components typed manually are now preferred — they are more explicit and flexible.

**Q: What type should you use for a ref to an input element?**
`useRef<HTMLInputElement>(null)` — the generic specifies the DOM element type, giving access to element-specific properties.

**Q: What is `React.ReactNode` vs `React.ReactElement`?**
`ReactNode` is everything renderable: strings, numbers, elements, fragments, null. `ReactElement` is only JSX/`React.createElement` output — a narrower type.

**Q: How do you type a component that accepts any HTML div attributes plus custom props?**
Extend the native props: `type Props = React.HTMLAttributes<HTMLDivElement> & { label: string }`.

**Q: Why is `event: any` in an event handler a bad practice?**
It bypasses type checking — you lose autocomplete, you can access properties that do not exist, and bugs are only caught at runtime.

**Q: What is `as const` and when is it useful in React?**
It makes an object or array deeply `readonly` with literal types. Useful when defining a set of allowed values: `const VARIANTS = ["info", "error"] as const`.

**Q: How do you type a component that conditionally renders different content?**
Use union return types or conditional rendering with proper type narrowing. Each branch should return `JSX.Element | null`.

**Q: What is the difference between `type` and `interface` for props?**
Both work. `interface` supports declaration merging; `type` supports union and intersection types more flexibly. For props, the choice is mostly stylistic.

**Q: What is `Partial<T>` and when is it useful for props?**
`Partial<T>` makes all properties of `T` optional. Useful for update/patch props where only some fields are provided.

**Q: Why avoid `any` in React components?**
`any` disables all type checking for that value and anything downstream. It defeats the purpose of typing and hides bugs.

---

## Key Takeaways

- Props are the main data interface between components — typing them makes that contract explicit and compiler-enforced.
- TypeScript in React is erased at runtime; all enforcement happens at compile time and in the editor.
- Typed events give you safe access to `event.target`, form data, and keyboard/mouse properties without guessing.
- Generic components let you write a single component that is type-safe across any data shape.
- Avoid `any` — it silently disables safety for the entire downstream flow.
- `React.ReactNode` is the correct type for the `children` prop in most cases.
- Strict typing makes refactoring safe: rename a prop and the compiler finds every broken caller.

---

## Vocabulary

### Nouns (concepts)

**Props**: The data passed from a parent component to a child. Props are read-only from the child's perspective.

**Type annotation**: An explicit declaration of what type a variable, parameter, or return value must be.

**Union type**: A type that allows one of several specified values — e.g., `"info" | "warning" | "error"`.

**Generic**: A type parameter that lets a function or component work with multiple data types while remaining type-safe.

**`React.ReactNode`**: The broadest renderable type in React — includes strings, numbers, JSX elements, arrays, `null`, and `undefined`.

**`React.ReactElement`**: A specific JSX element produced by `React.createElement`. Narrower than `ReactNode`.

**`forwardRef`**: A React API that allows a parent to pass a `ref` into a child component. Must be typed with both the ref element type and the props type.

**`useRef<T>`**: A hook that holds a mutable ref. The generic `T` specifies the type of the referenced value, commonly a DOM element.

**PropTypes**: React's runtime prop validation system (JavaScript only). Validates at runtime in development mode only — not a replacement for TypeScript.

**`as const`**: A TypeScript assertion that makes a value deeply `readonly` with narrowed literal types.

### Verbs (actions)

**Infer**: When TypeScript automatically determines a type from context without an explicit annotation.

**Narrow**: To reduce a type to a more specific subtype using a conditional check (e.g., `if (user !== null)`).

**Extend**: To build a new type on top of an existing one, adding or overriding properties.

**Enforce**: TypeScript enforces types by rejecting code that does not match the declared types at compile time.

### Adjectives (properties)

**Optional**: A prop or field marked with `?` — it may be `undefined`. Callers are not required to provide it.

**Required**: A prop or field without `?` — the compiler will error if a caller omits it.

**Readonly**: A property that cannot be reassigned after initialization. Expressed as `readonly` in TypeScript or via `as const`.

**Generic**: Describes a component or function parameterized over a type variable rather than a fixed type.

**Strict**: In TypeScript config, `"strict": true` enables a set of conservative checks including `noImplicitAny`, `strictNullChecks`, and others. In React context, "strict typing" means fully annotating components rather than relying on inference or `any`.
