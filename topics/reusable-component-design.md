# Reusable component design

**Abstraction level**: pattern
**Category**: frontend architecture / UI design

---

## Related Topics

- **Implementations of this**: React components, Vue components, Web Components, design systems
- **Depends on this**: component composition, props vs state, separation of concerns
- **Works alongside**: accessibility, design tokens, state management
- **Contrast with**: page-specific components, copy-paste UI, monolithic components
- **Temporal neighbors**: learn component basics first; next study controlled vs uncontrolled components and composition

---

## What is it

Reusable component design is a pattern for building UI pieces that can be used in more than one place without rewriting their core behavior. The idea is to define a small, clear unit that accepts input data, applies stable rules, and produces predictable UI output. A good reusable component is flexible in the ways that matter and strict in the ways that protect correctness.

In simple terms:

- The data is things like text, state, variants, and user actions.
- It usually lives in browser memory as part of the UI tree.
- A parent sends data into the component, the component reads it, and the component may send events back out.
- Over time, the input changes, local UI state may change, and the rendered output changes with it.

Reusable component design is just a way to control how UI data is shaped, transformed, and updated so one building block works in many contexts.

---

## What problem does it solve

Start with one screen that needs one button. Writing the button inline is easy: some label data goes in, a click action happens, the browser shows a visual result.

Now the product grows. The same button appears on the login page, settings page, checkout page, and modal dialogs. Each place needs the same core behavior but slightly different content or state. If every screen builds its own version, the same data is mapped to UI in different ways.

That creates common failures:

- **Duplication**: the same structure and rules are copied into many files
- **Inconsistency**: one version handles disabled state correctly, another does not
- **Invalid data**: impossible combinations appear because nobody defined what is allowed
- **Hard-to-track changes**: one visual or behavior change requires editing many places
- **Unclear ownership**: layout, styling, validation, and business decisions get mixed together

The core problem is loss of control. Without reuse, data enters the UI through many small ad hoc paths, so change becomes scattered and correctness becomes accidental.

---

## How does it solve it

### 1. Single responsibility

A reusable component should do one job. A `Button` should represent an action trigger. It should not also decide page layout, fetch server data, and manage unrelated state.

This keeps flow simple:

- parent decides when the component exists
- parent sends input data
- component turns that data into UI

One responsibility means fewer hidden rules and fewer invalid state combinations.

### 2. Small public API

The component needs a clear interface: what data comes in, what events go out, and what variations are supported. A small API limits ambiguity.

That improves predictability:

- callers know what they control
- the component knows what assumptions are safe
- invalid usage is easier to detect

### 3. Controlled variation

Reuse does not mean one component should handle every possible case. It means the component supports a limited set of meaningful variations, such as size, tone, or status.

This matters because variation is still data. If you allow too many unrelated options, you create combinations that were never designed or tested.

### 4. Clear state ownership

Some data changes over time: open or closed, selected or unselected, loading or idle. Reusable design requires deciding where that changing data lives.

The rule is simple: one piece of data should have one clear owner. That owner controls updates, and everyone else reads or reacts to those updates.

### 5. Stable internal rules

A reusable component should apply the same transformation every time it receives the same valid input. If an input is invalid, the boundary should make that obvious or prevent it.

This is what makes the component trustworthy. Reuse is not only shared markup. It is shared behavior, shared constraints, and shared valid state transitions.

### 6. Composition over branching

When a component starts growing too many special cases, split responsibilities instead of adding more flags. Let one component provide structure and let other pieces provide content.

Composition keeps data flow explicit:

- outer component controls layout
- inner pieces control their own content
- each piece has fewer rules to enforce

---

## What if we didn't have it (Alternatives)

### 1. Manual page-by-page markup

```html
<button>Save</button>
```

This works once. It fails when each screen adds different classes, behavior, and accessibility rules by hand.

### 2. Copy-paste reuse

```html
<button class="primary">Save</button>
<button class="primary">Delete</button>
```

This looks shared, but the logic is still duplicated. Once one copy changes, the others drift.

### 3. Giant configurable component

```txt
Button(
  primary,
  danger,
  compact,
  wide,
  rounded,
  withIcon,
  loading,
  fullWidth
)
```

This centralizes code but weakens correctness. Too many knobs create hidden coupling and invalid combinations.

### 4. Page-specific conditional hacks

```txt
if page == "checkout" then padding = 18
if page == "profile" then padding = 14
```

Now the component knows too much about where it is used. Reuse breaks because the unit is no longer generic; it is secretly tied to screens.

---

## Examples

### 1. Minimal conceptual example

A status badge takes one input and produces one output.

```txt
input: status = "success"
output: green badge with text "Success"
```

The same valid input should always produce the same visible result.

### 2. Small code example: structure vs content

```txt
Badge(label="New", tone="info")
Badge(label="Sold out", tone="warning")
```

The component owns the structure of a badge. The caller owns the actual label data.

### 3. Incorrect vs correct variation

Incorrect:

```txt
Button(primary=true, danger=true, ghost=true)
```

Correct:

```txt
Button(variant="danger")
```

The second version encodes variation more clearly, so invalid combinations are harder to create.

### 4. Incorrect vs correct state ownership

Incorrect:

```txt
Modal()
```

If the modal decides by itself when it opens and closes, the rest of the page cannot coordinate with it.

Correct:

```txt
Modal(isOpen=true, onClose=...)
```

Now the changing data has a visible owner, and the flow is explicit.

### 5. Composition example

Less reusable:

```txt
Card(showHeader=true, headerText="Profile", footerText="Save")
```

More reusable:

```txt
Card(
  header=Title("Profile"),
  body=Form(...),
  footer=Button(label="Save")
)
```

The card controls layout. The caller controls what data fills each slot.

### 6. Browser interaction example

```txt
parent sends value = "rea"
user types "c"
input emits change = "reac"
parent stores "reac"
input re-renders with value = "reac"
```

This shows the full loop: data comes in, user action creates a new value, the owner updates state, and the UI refreshes.

### 7. Real-world analogy

A shipping label template is reusable because the structure stays fixed while the package data changes. Sender, receiver, and barcode values differ each time, but the placement rules stay the same.

That is reusable component design: stable structure, variable data, controlled output.

---

## Quickfire (Interview Q&A)

**Q: What is reusable component design?**  
A: It is a way to build UI units with clear inputs, outputs, and responsibilities so the same unit can be used in multiple places predictably.

**Q: Why is reusability useful?**  
A: It reduces duplication and keeps behavior, structure, and correctness rules consistent across screens.

**Q: What makes a component reusable?**  
A: A narrow responsibility, a small API, controlled variation, and clear ownership of changing data.

**Q: Does reusable mean highly configurable?**  
A: No. Too much configurability often means the abstraction is weak and easy to misuse.

**Q: Why is state ownership important?**  
A: Because one piece of changing data needs one clear owner, or different parts of the UI will drift out of sync.

**Q: What is the difference between reuse and copy-paste?**  
A: Reuse shares one controlled implementation. Copy-paste duplicates code and lets versions diverge over time.

**Q: Why is composition often better than more flags?**  
A: Composition splits responsibility into smaller units, which reduces invalid combinations and hidden coupling.

**Q: What is a bad sign in a component API?**  
A: Many boolean flags, screen-specific conditions, or props that only make sense together are signs the design is unstable.

**Q: Can reusable components contain logic?**  
A: Yes, but mainly logic tied to their own UI behavior and correctness, not broad page or domain decisions.

**Q: How would you explain this in one sentence?**  
A: Reusable component design is a way to control how UI data becomes UI output so the same building block works reliably in different places.

---

## Key Takeaways

- Reusability is mostly about controlling data flow and state changes.
- A reusable component should do one job well.
- A small API is easier to understand, test, and trust.
- Variation should be intentional, not unlimited.
- One changing value should have one clear owner.
- Reuse means sharing rules and behavior, not just markup.
- Composition usually scales better than adding more special cases.

---

## Vocabulary

### Nouns (concepts)

**Component**  
A component is a UI unit with inputs, rules, and output. In this topic, it is the main boundary for controlling how data becomes visible UI.

**API**  
An API is the public interface of a component: the inputs it accepts and the outputs or events it exposes.

**State**  
State is data that changes over time, such as open/closed or loading/idle. Reusable design depends on knowing who owns that data.

**Variant**  
A variant is a supported version of a component, such as `small`, `large`, or `danger`. Good variants are limited and intentional.

**Boundary**  
A boundary is the line between what the component controls and what its caller controls. Clear boundaries improve predictability.

**Composition**  
Composition means combining smaller pieces into a larger UI structure. It helps reuse by keeping each piece focused.

**Source of truth**  
The source of truth is the single place where the current value of some data is stored. Reusable components work best when that source is explicit.

**Coupling**  
Coupling is the degree to which two parts depend on each other. High coupling makes reuse harder because changes spread across many places.

### Verbs (actions)

**Render**  
To render is to transform input data into visible UI output. Reusable components should render predictably from valid input.

**Compose**  
To compose is to combine smaller units into a larger one. This is a common way to avoid giant, fragile components.

**Emit**  
To emit is to send an event or signal outward, usually after user interaction. This is one of the main output flows from a component.

**Derive**  
To derive is to compute one value from another. For example, a visual state can be derived from a status input.

**Validate**  
To validate is to check whether incoming data or state combinations are allowed. Validation protects correctness at the component boundary.

**Reuse**  
To reuse is to apply the same controlled component in different contexts without rewriting its core rules.

### Adjectives (properties)

**Reusable**  
Reusable means the same unit can serve multiple contexts without custom rewriting and without losing correctness.

**Predictable**  
Predictable means the same valid input produces the same behavior and output. This is one of the main goals of good component design.

**Explicit**  
Explicit means the data flow and control are visible rather than hidden. Explicit APIs are easier to reason about in both code and interviews.

**Coupled**  
Coupled describes parts that depend heavily on each other's internals. Highly coupled components are harder to change safely.

**Monolithic**  
Monolithic means one component handles too many concerns at once. That usually makes reuse weaker and bugs harder to track.

**Consistent**  
Consistent means the same rules produce the same result across different screens and features. Reusable components are a practical way to achieve that.
