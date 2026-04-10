# Reusable Component Design

**Abstraction level**: pattern
**Category**: frontend architecture / UI design

---

## Related Topics

- **Implementations of this**: React components, Vue components, Web Components, design systems
- **Depends on this**: component composition, props and state, separation of concerns
- **Works alongside**: accessibility, state management, design tokens
- **Contrast with**: page-specific components, copy-paste UI, monolithic components
- **Temporal neighbors**: learn component basics first; next study composition and controlled vs uncontrolled patterns

---

## What is it

Reusable component design is a pattern for building UI pieces that can be used in many places without rewriting them. A reusable component has a clear job, a small public API, and rules about what data it accepts and what output it produces. The main goal is control: the component should be flexible enough for different screens, but strict enough to stay predictable.

- **Data**: input values, UI state, events, and visual variants
- **Where it lives**: browser memory as part of the UI tree
- **Who reads/writes it**: parent code passes data in; the component reads it and may emit events back out
- **How it changes over time**: inputs change, internal state may change, rendered output updates in response

At a basic level, reusable component design is just a way to control how UI data is shaped, displayed, and changed so the same building block works in more than one context.

---

## What problem does it solve

Start with a simple button on one page. It has text, maybe a disabled state, and maybe a click action. Writing it directly in the page is easy.

Then the app grows. Now you need the same button in five places. One version has an icon. Another shows a loading state. Another must follow accessibility rules. Another must match a new visual style. If each page builds its own version, the same idea exists in multiple places.

That creates common failure modes:

- **Duplication**: the same markup and styling are copied into many files
- **Inconsistency**: one button handles disabled state correctly, another does not
- **Invalid data**: one page passes impossible combinations like `loading=true` and `disabled=false` without clear rules
- **Hard-to-track changes**: a design update requires editing many places by hand
- **Unclear ownership**: business logic, styling, layout, and validation all get mixed together

Reusable component design solves this by defining one stable unit with explicit inputs, explicit outputs, and clear boundaries. Instead of rebuilding UI each time, you reuse a controlled transformation: given valid input data, produce predictable UI.

---

## How does it solve it

### 1. Single responsibility

A reusable component should do one job well. A `Button` should represent an action trigger, not also manage page layout, data fetching, and navigation rules.

This keeps data flow simple:
- parent decides when to show the component
- parent sends the input data
- component transforms that data into UI

When one component owns one concern, change is easier to reason about.

### 2. Clear public API

A reusable component needs a small, explicit interface. That usually means a defined set of inputs, outputs, and allowed states.

Good API design improves predictability:
- valid inputs are obvious
- invalid combinations are limited
- callers know what they control and what they do not

If the API is vague or too large, reuse becomes fragile because every consumer uses the component differently.

### 3. Controlled variation

Reuse does not mean "make one component handle everything." It means support a small number of meaningful variations without losing structure.

Examples of controlled variation:
- size: small, medium, large
- status: default, error, success
- content: label only, label with icon

The key idea is that variation should be intentional. If every new need adds another unrelated option, the component becomes unpredictable.

### 4. Separation of structure from content

A reusable component often provides structure while the caller provides content. The component defines where data goes; the caller decides which specific data to send.

This makes flow clearer:
- component owns layout rules
- caller owns page-specific values

That boundary reduces hidden coupling between one screen and the component's internals.

### 5. Explicit ownership of state

Some UI data changes over time: open/closed, selected/unselected, loading/idle. Reusable design requires deciding who owns that changing data.

Two common options:
- the parent owns the state and sends it in
- the component owns only small local state tied to its own behavior

Correctness depends on this choice. If ownership is unclear, different parts of the UI try to control the same data and drift out of sync.

### 6. Stable internal rules

A reusable component should protect correctness inside its boundary. For example, if a field shows an error message, it should render that message consistently and connect it to the right input.

This means the component is not just visual reuse. It also reuses behavior, constraints, and valid state transitions.

### 7. Composition over special cases

Instead of adding a prop for every possible use case, prefer combining small components. One component can provide a shell; others can provide content or behavior around it.

This keeps control local:
- each piece has simpler data
- each piece has fewer invalid states
- changes affect smaller surfaces

---

## What if we didn't have it

### 1. Manual page-by-page markup

```html
<button class="blue-btn">Save</button>
```

This works once. It breaks when ten pages each define their own button rules, styles, and disabled behavior.

### 2. Copy-paste reuse

```html
<button class="blue-btn">Save</button>
<button class="blue-btn">Delete</button>
```

This looks reusable, but the logic is duplicated, not shared. When behavior changes, you must remember every copy.

### 3. One giant configurable component

```txt
Button(
  primary,
  secondary,
  danger,
  ghost,
  compact,
  wide,
  iconLeft,
  iconRight,
  loading,
  fullWidth,
  rounded
)
```

This centralizes code but loses control. Too many options create hidden coupling and invalid combinations.

### 4. Page-specific hacks

```txt
if screen == "checkout" then buttonPadding = 18
if screen == "profile" then buttonPadding = 14
```

This ties the component to specific pages. Reuse disappears because the component now knows too much about where it is used.

---

## Examples

### 1. Minimal conceptual example

A badge component takes one piece of data, `status`, and turns it into UI.

```txt
input: status = "success"
output: green badge with text "Success"
```

The transformation is simple and predictable: same valid input, same output.

### 2. Small code example: clear inputs

```js
Badge({ label: "New", tone: "info" })
```

The component reads `label` and `tone`. It should not also decide when a product is new. That decision belongs to the caller.

### 3. Incorrect vs correct ownership

Incorrect:

```js
Modal()
// internally decides on its own when to open
```

Correct:

```js
Modal({ isOpen: true, onClose })
```

Open/closed is changing state. If the parent owns it, the flow is visible and easier to coordinate with the rest of the page.

### 4. Real-world analogy

Think of a reusable component like a form template at a bank. The template defines the structure: which fields exist, which values are valid, and where signatures go. Each customer provides different data, but the structure stays stable.

That is reuse: same transformation rules, different input values.

### 5. Composition instead of branching

Less reusable:

```js
Card({ showHeader: true, showFooter: true, footerText: "Save" })
```

More reusable:

```js
Card({
  header: Title("Settings"),
  body: Form(),
  footer: Button({ label: "Save" })
})
```

In the second version, the card owns layout. The caller owns what content fills each part.

### 6. Browser interaction example

A search input component receives text and emits changes:

```txt
parent sends value = "rea"
user types "c"
component emits change = "reac"
parent stores new value
component re-renders with value = "reac"
```

The important part is the loop: input data comes in, user action sends new data out, parent updates the source of truth, UI refreshes.

### 7. Invalid vs valid data combinations

Problematic:

```js
Button({ loading: true, disabled: false })
```

Safer:

```js
Button({ state: "loading" })
```

The second API reduces impossible combinations by encoding state more explicitly.

### 8. Scaling example

A product card appears on the home page, search page, and favorites page. If each page builds its own version, product name, price, and image rules drift apart. If one reusable `ProductCard` owns those display rules, the same product data is mapped consistently everywhere.

---

## Quickfire (Interview Q&A)

**Q: What is reusable component design?**  
A: It is a pattern for building UI pieces with clear inputs, outputs, and responsibilities so they can be used in multiple places predictably.

**Q: Why is reuse valuable?**  
A: It reduces duplication and keeps behavior, styling, and validation consistent across the app.

**Q: What makes a component reusable?**  
A: A focused responsibility, a small API, controlled variation, and clear ownership of changing data.

**Q: Does reusable mean highly configurable?**  
A: No. Too much configurability often makes a component harder to understand and easier to misuse.

**Q: What is the biggest design risk?**  
A: Mixing many responsibilities into one component, which creates hidden coupling and invalid state combinations.

**Q: How do you know a component API is too large?**  
A: If callers need many flags, special cases, or mutually dependent options, the abstraction is probably unstable.

**Q: Why does state ownership matter?**  
A: Because the part that owns changing data controls when the UI updates and keeps different views in sync.

**Q: What is the difference between reuse and copy-paste?**  
A: Reuse shares one controlled implementation; copy-paste duplicates code and lets versions drift apart.

**Q: How does composition help reuse?**  
A: It lets a component provide structure while callers supply content, which reduces special-case branching.

**Q: Should reusable components contain business logic?**  
A: Only the logic directly tied to their UI behavior. Page or domain decisions should usually stay outside.

---

## Key Takeaways

- Reusable component design is mainly about controlling how UI data becomes UI output.
- A reusable component should have one clear responsibility.
- Small, explicit APIs make components easier to trust and harder to misuse.
- Variation should be intentional, not unlimited.
- State ownership must be clear or data gets out of sync.
- Reuse means sharing rules, not just sharing markup.
- Composition usually scales better than adding more flags.

---

## Vocabulary

### Nouns (concepts)

**Component**  
A component is a reusable UI unit with inputs, logic, and output. In this topic, it is the main boundary for controlling data and presentation.

**API**  
An API is the public interface of a component: what inputs it accepts and what outputs or events it exposes.

**State**  
State is data that changes over time, such as open/closed or loading/idle. Reusable design depends on knowing who owns that data.

**Props / inputs**  
Inputs are values passed into a component so it can render or behave correctly. They should be explicit and valid.

**Output**  
Output is the rendered UI or emitted event produced by the component after it processes input data.

**Variant**  
A variant is a supported version of a component, such as size or visual tone. Good variants are limited and intentional.

**Boundary**  
A boundary is the line between what the component controls and what the caller controls. Clear boundaries improve predictability.

**Composition**  
Composition is combining smaller UI pieces to build larger ones. It helps reuse by keeping each piece focused.

**Source of truth**  
The source of truth is the single place where the current value of some data is stored. Reusable components work better when this is clear.

**Coupling**  
Coupling is how strongly two parts of a system depend on each other. High coupling makes reuse and change harder.

### Verbs (actions)

**Render**  
To render is to turn data into visible UI output. Reusable components render predictably from valid inputs.

**Compose**  
To compose is to combine smaller units into a larger structure. This is a common way to avoid giant components.

**Emit**  
To emit is to send an event or signal outward, usually in response to user interaction. This is how components communicate changes.

**Derive**  
To derive is to calculate one value from another. For example, a visual state may be derived from input data.

**Validate**  
To validate is to check whether input data or state combinations are allowed. Reusable components often enforce these rules.

**Reuse**  
To reuse is to apply the same controlled component in different contexts without rewriting its core logic.

### Adjectives (properties)

**Reusable**  
Reusable means the component can serve multiple contexts without custom rewriting and without losing correctness.

**Predictable**  
Predictable means the same valid input leads to the same behavior and output. This is a core goal of good component design.

**Explicit**  
Explicit means data flow and control are visible rather than hidden. Explicit APIs are easier to understand in interviews and in code.

**Coupled**  
Coupled describes parts that depend heavily on each other's internals. Highly coupled components are hard to reuse safely.

**Monolithic**  
Monolithic means one component handles too many concerns at once. That usually hurts clarity and reuse.

**Consistent**  
Consistent means the same rules produce the same result across screens and features. Reusable components are a practical way to get consistency.
