# Local vs Global State

**Abstraction level**: concept / pattern
**Category**: frontend state management

---

## Related Topics

- **Implementations of this**: Context API, Redux, Zustand
- **Depends on this**: props vs state
- **Works alongside**: derived state, data fetching, routing
- **Contrast with**: server state, props drilling, persistent storage
- **Temporal neighbors**: state management in SPA apps, unidirectional data flow

---

## What is it

Local vs global state is a way to decide how widely a piece of data should be shared inside an application. Local state belongs to one small UI area. Global state belongs to the application as a whole because multiple distant parts need the same current value. In simple terms, it is a rule for matching the scope of data to the scope of the parts that read and change it.

- **Data**: input text, open/closed flags, selected item, current user, cart items, active filter
- **Where it lives**: usually in browser memory while the app is running
- **Who reads/writes it**: one component or feature reads local state; many features may read global state
- **How it changes over time**: user actions, navigation, timers, and server responses move it from one valid value to another

---

## What problem does it solve

Start with a simple case: a modal has an `isOpen` flag. One button changes it, and one modal reads it. Keeping that data local is simple because ownership is obvious.

Now the app grows. A selected filter may affect the page header, results list, URL, and export button. If each place stores its own copy, the copies drift apart. One part updates, another stays stale, and nobody knows which value is the real one.

Without a clear local-vs-global decision, common failures appear:

- **Duplication**: the same logical fact is stored in multiple places
- **Inconsistency**: different screens show different versions of the same data
- **Invalid data**: one part updates a value without updating related values
- **Hard-to-track changes**: many places can write the same state, so bugs become hard to trace
- **Unclear ownership**: developers cannot tell who is responsible for keeping the data correct

This concept solves the problem by asking one practical question: how many places must agree on this value right now?

---

## How does it solve it

### 1. Scope matches usage

Keep state local when only one small area needs it. Move it to global scope when many distant parts need to read the same value.

- **Data flow**: short path for local data, shared path for app-wide data
- **Control**: fewer readers and writers when the scope is small
- **Predictability**: the storage location matches actual usage

### 2. Ownership is explicit

Every piece of state should have a clear owner. The owner decides what values are valid and how changes happen.

- **Data flow**: readers get data from one owner instead of making copies
- **Control**: writes happen through known paths
- **Predictability**: when data is wrong, there is one place to inspect first

### 3. One fact should have one source of truth

If many parts need the same fact, store it once and let the rest read or derive from it. Do not keep parallel copies of the same meaning.

- **Data flow**: one source, many readers
- **Control**: fewer manual sync steps
- **Predictability**: fewer contradictions between UI parts

### 4. Share only what must be shared

Global state is useful, but it increases coupling. Making everything global spreads changes farther than necessary.

- **Data flow**: unnecessary updates travel through more of the app
- **Control**: more shared data means more coordination rules
- **Predictability**: small UI details stay isolated instead of affecting unrelated areas

### 5. Separate temporary data from shared committed data

Some data is only a local draft. Some data is the shared current truth of the app.

- **Data flow**: draft values stay local until confirmed
- **Control**: validation can happen before shared data changes
- **Predictability**: the app can distinguish "editing" from "saved"

---

## What if we didn't have it (Alternatives)

### 1. Separate local copies everywhere

```txt
Header.filter = "open"
Sidebar.filter = "open"
Table.filter = "closed"
```

This starts simple but breaks as soon as one copy changes and the others do not. The app now has duplication with no control over consistency.

### 2. Put everything in one shared state object

```txt
appState = {
  currentUser: {...},
  cart: [...],
  tooltipVisible: true,
  hoveredRow: 4
}
```

This avoids some duplication, but tiny local UI details now become global concerns. Unrelated parts become coupled to data they should not care about.

### 3. Pass data manually through many layers

```txt
App -> Layout -> Page -> Panel -> Button
```

If only `Button` needs the value, the middle layers become wiring. This creates hidden coupling because components that do not use the data still depend on it.

### 4. Use plain mutable variables

```js
let currentUser = null
```

This makes writes easy, but control is weak. Any code can change the value, and readers may not know when it changed or whether it is still valid.

---

## Examples

### 1. Minimal conceptual example

A tooltip has one piece of data:

```txt
isVisible = false
```

One small UI area reads it and one hover event changes it. This is local state because the data is short-lived and isolated.

### 2. Small code example

```js
const dialogState = { isOpen: false }

function openDialog() {
  dialogState.isOpen = true
}
```

The important idea is not the syntax. The important idea is that one owner controls one small piece of data.

### 3. Shared current user

```txt
currentUser = { id: 7, role: "admin" }
```

If the header, profile page, and permission checks all need this value, keeping separate copies is dangerous. This is a good candidate for global state because many distant readers must agree on one current identity.

### 4. Incorrect vs correct cart count

Incorrect:

```txt
CartIcon.count = 2
Checkout.count = 3
```

Correct:

```txt
cartItems = [a, b, c]
CartIcon.count = cartItems.length
Checkout.count = cartItems.length
```

The correct version stores the real data once and derives the display value from it.

### 5. Local draft vs shared saved value

```txt
draftEmail = "ana@new.com"
savedEmail = "ana@old.com"
```

While the user is typing, the draft can stay local. After validation and save, the shared saved value changes. This keeps temporary edits separate from app-wide truth.

### 6. State promoted from local to global

At first:

```txt
settingsPanel.language = "en"
```

Later the whole app must use the selected language:

```txt
app.language = "en"
```

The key idea is that the data itself did not change much, but its audience changed.

### 7. Real-world analogy

A sticky note on one desk is local state. A schedule board for the whole team is global state.

- The sticky note is private and easy to change
- The board is shared and must stay accurate for everyone

That is the same trade-off in UI systems: private convenience versus shared coordination.

---

## Quickfire (Interview Q&A)

**Q: What is local state?**  
State used and owned by one small part of the UI.

**Q: What is global state?**  
State shared across multiple distant parts of the application.

**Q: How do you decide between local and global state?**  
Ask who reads it, who writes it, and how many parts must stay in sync.

**Q: Why not make everything global?**  
Because global state increases coupling, coordination cost, and the chance of unrelated updates affecting each other.

**Q: Why not keep everything local?**  
Because shared facts then get copied into multiple places and become inconsistent.

**Q: What is a source of truth?**  
It is the one authoritative place where a fact is stored and updated.

**Q: Can state move from local to global over time?**  
Yes. When more parts of the app need the same value, the scope can expand.

**Q: Is temporary form input usually local or global?**  
Usually local, because it is short-lived and belongs to one editing flow.

**Q: What kind of data is often global?**  
Current user, cart contents, selected workspace, active permissions, or app-wide filters.

**Q: How does this topic relate to correctness?**  
Correctness improves when one fact has one owner and one current value.

---

## Key Takeaways

- Local vs global state is mainly a question of scope.
- Keep data close to where it is used unless multiple distant parts must share it.
- One logical fact should have one source of truth.
- Global state solves consistency problems but adds coupling.
- Local state is simpler for temporary, isolated UI data.
- Shared committed data and local draft data should not be mixed.
- Good state design makes ownership and data flow obvious.

---

## Vocabulary

### Nouns

**State**  
Data that can change over time and affect what the UI shows or does.

**Local state**  
State owned by one small UI area or feature. It is usually private and short-lived.

**Global state**  
State shared across multiple distant parts of the application. It exists so those parts can stay consistent.

**Source of truth**  
The authoritative place where a fact is stored. Other values should read or derive from it instead of duplicating it.

**Owner**  
The part of the system responsible for creating, validating, and updating a piece of state.

**Consumer**  
A part of the system that reads state in order to render UI or make decisions.

**Draft**  
A temporary local version of data that is still being edited and is not yet the shared committed value.

**Derived state**  
A value computed from existing state instead of stored as another separate copy.

**Coupling**  
A dependency between parts of the system. More shared state usually means more coupling.

**Consistency**  
The property that different parts of the app agree on the same logical fact.

### Verbs

**Read**  
To consume the current value of state. Readers depend on the state being up to date and valid.

**Write**  
To change state from one value to another. Good designs limit who can write shared data.

**Share**  
To make state available to more than one part of the application. Shared data needs stronger control.

**Derive**  
To compute one value from another. This reduces duplication and inconsistency.

**Synchronize**  
To keep multiple readers aligned with one current value. Global state often exists to support synchronization.

### Adjectives

**Local**  
Limited in scope to one small area. Local data usually has fewer readers and simpler control.

**Global**  
Wide in scope across the application. Global data must be coordinated carefully.

**Shared**  
Read by multiple parts of the app. Shared values need a clear source of truth.

**Temporary**  
Short-lived and often tied to an in-progress interaction, such as typing into a field.

**Authoritative**  
Trusted as the real current value. An authoritative state location is the one other parts should rely on.
