# Local vs Global State

**Abstraction level**: concept / pattern  
**Category**: frontend state management

---

## Related Topics

- **Implementations of this**: component state, shared stores, context systems, signals-based stores
- **Depends on this**: state management in SPA apps, derived state, UI synchronization
- **Works alongside**: props, events, data fetching, caching
- **Contrast with**: server state, props vs state, local mutation via plain variables
- **Temporal neighbors**: learn props and component composition before this; then learn broader state management patterns

---

## What is it

Local vs global state is a way to decide how far a piece of data needs to reach inside an application. Local state belongs to one small part of the UI and is changed there. Global state is shared across multiple distant parts of the app and must stay consistent everywhere. The core question is not "where can I store this?" but "who needs to read it, who can change it, and how long must it stay valid?"

- **Data**: input text, open/closed flags, selected tab, current user, shopping cart, theme, notifications
- **Where it lives**: usually browser memory on the client side; local state lives near one component or feature, global state lives at application scope
- **Who reads/writes it**: local state is read and written by one owner; global state is read by many parts and updated through controlled shared paths
- **How it changes over time**: user actions, server responses, timers, and navigation events move state from one valid value to another

---

## What problem does it solve

Start with a simple case: a search input has some text. Only the search box cares about that text while the user types, so keeping it local is simple and safe.

Now the app grows. The same data may need to be shown in the header, a sidebar, a content area, and a settings screen. If each place keeps its own copy, the copies drift apart. One part updates, another stays stale, and a third uses an invalid value because nobody knows which copy is the real one.

Without a clear local-vs-global decision, common problems appear:

- **Duplication**: the same logical data is stored in multiple places
- **Inconsistency**: one part of the UI shows old data while another shows new data
- **Invalid data**: one copy is updated without updating related values
- **Hard-to-track changes**: many places can change the same thing, so bugs become timing and ownership problems
- **Unclear ownership**: developers cannot tell which part of the app is responsible for correctness

This concept solves the problem by matching the scope of the state to the scope of the consumers. Keep data close when only one place needs it. Share data centrally when many places must agree on it.

---

## How does it solve it

### Principle 1: Scope follows usage

If one component or one small feature is the only reader, keep the state local. If many distant parts of the app need the same value, move it to a shared location.

- **Data flow**: local state flows inside one small area; global state flows outward to many readers
- **Control**: fewer readers means simpler control; more readers require a shared contract
- **Predictability**: the chosen scope matches the actual usage of the data

### Principle 2: Ownership must be explicit

Every piece of state should have a clear owner. The owner is the place responsible for creating it, validating it, and deciding how it changes.

- **Data flow**: readers consume data from the owner instead of inventing copies
- **Control**: changes go through the owner, not through random side paths
- **Predictability**: when something looks wrong, you know where to inspect first

### Principle 3: Share only what must be shared

Global state is useful, but it has a cost. The more data becomes global, the more parts of the app become coupled to each other.

- **Data flow**: unnecessary global state sends updates farther than needed
- **Control**: more shared data means more rules and more coordination
- **Predictability**: a small local change should not trigger app-wide complexity

### Principle 4: One logical value should have one authoritative source

If a value is shared, keep one source of truth for it. Other values that can be computed from it should usually be derived, not stored separately.

- **Data flow**: readers pull from one source instead of syncing multiple copies
- **Control**: updates happen once, at the source
- **Predictability**: fewer duplicated values means fewer mismatch bugs

### Principle 5: State should move upward only when needed

A common progression is local first, then shared later if requirements grow. This keeps the design simple at the beginning and avoids global state that exists "just in case."

- **Data flow**: start narrow, widen only when more readers appear
- **Control**: state promotion is a deliberate design step
- **Predictability**: complexity is added in response to real usage, not speculation

---

## What if we didn't have it (Alternatives)

### 1. Keep separate local copies everywhere

```txt
Header.userName = "Ana"
Profile.userName = "Ana"
Settings.userName = "Ana"
```

This looks simple until one screen updates the name and the others do not. The problem is duplicated data with no synchronization rule.

### 2. Put everything in one giant shared object

```txt
appState = {
  modalOpen: false,
  inputValue: "",
  hoveredRow: 3,
  currentUser: {...},
  cart: [...]
}
```

This removes some duplication but creates a different problem: tiny UI details now live beside app-wide data. Unrelated parts become coupled, and the shared state becomes noisy and hard to reason about.

### 3. Pass everything manually through many layers

```txt
App -> Layout -> Page -> Panel -> Widget
```

If only `Widget` needs the value, passing it through four intermediaries adds wiring and accidental coupling. Those middle layers now know about data they do not actually use.

### 4. Use plain mutable variables

```js
let currentUser = null
```

This allows easy writes, but it gives no structure for who is allowed to change the value or how readers are notified. The data exists, but the flow and control are implicit.

---

## Examples

### Example 1: Local state for an input

A text field stores the current typed value while the user edits it.

```txt
searchText = "lap"
```

Only the search box needs this while typing, so local state is enough. The data is short-lived and owned by one UI area.

### Example 2: Global state for the current user

The header, account page, and permissions checks all need the logged-in user.

```txt
currentUser = { id: 7, name: "Ana", role: "admin" }
```

If each screen stores its own copy, they can disagree. This is shared identity data, so one global source is more correct.

### Example 3: Bad local duplication vs good sharing

Incorrect:

```txt
CartIcon.count = 2
CheckoutPage.count = 3
```

Correct:

```txt
cartItems = [a, b, c]
CartIcon.count = cartItems.length
CheckoutPage.count = cartItems.length
```

The correct version stores the real data once and derives the displayed count from it.

### Example 4: Local state promoted to global state

At first, a selected language only affects one settings panel.

```txt
settingsPanel.language = "en"
```

Later, the whole app must re-render text in the chosen language. The same data now affects many screens, so it becomes global:

```txt
app.language = "en"
```

The important idea is not the mechanism. The important idea is that the scope changed.

### Example 5: Real-world analogy

A sticky note on one engineer's desk is local state. A whiteboard in the team room is global state.

- The sticky note is fast and private, but nobody else sees updates.
- The whiteboard is shared and visible, but it should contain only information the team really needs.

This is the same trade-off in UI design: private convenience versus shared coordination.

### Example 6: Browser and server interaction

A form field being edited is local state. The saved customer record returned by the server may become global state if many parts of the app need it.

```txt
Local: draftEmail = "ana@new.com"
Server-backed shared data: customer.email = "ana@old.com"
```

When the user clicks Save:

1. The local draft is validated.
2. The browser sends the new value to the server.
3. The shared customer data is updated after success.

This keeps temporary edits separate from shared committed data.

### Example 7: Incorrect scope choice

```txt
Global: tooltipVisible = true
```

This is usually the wrong choice. A tooltip shown in one small area does not need app-wide coordination, so making it global adds unnecessary coupling.

---

## Quickfire (Interview Q&A)

**Q: What is local state?**  
State owned and used by one small part of the UI. It usually represents temporary or isolated data.

**Q: What is global state?**  
State shared across multiple distant parts of an application. It exists so those parts can stay consistent.

**Q: How do you decide whether state should be local or global?**  
Ask who reads it, who writes it, and how many parts must stay in sync. Scope should match usage.

**Q: Is global state always better because it is easier to access?**  
No. Easier access often means more coupling and more accidental dependencies.

**Q: Why is duplicated state dangerous?**  
Because two copies of one logical value can drift apart. Once they disagree, the UI becomes inconsistent.

**Q: What does "single source of truth" mean here?**  
It means one authoritative place holds the real value. Other views read or derive from that value instead of copying it.

**Q: Can local state become global later?**  
Yes. That is a normal evolution when more parts of the app need the same data.

**Q: What kind of data is usually local?**  
Transient UI details like input drafts, open/closed flags, hover state, or the selected item in one small widget.

**Q: What kind of data is usually global?**  
Shared application data like the current user, cart contents, theme, active permissions, or app-wide notifications.

**Q: What is the main risk of making too much state global?**  
The app becomes harder to change because unrelated features start depending on shared structures and shared updates.

**Q: What is the main risk of keeping shared state local?**  
Other parts of the UI create their own copies or awkward data paths, leading to inconsistency and unclear ownership.

**Q: Is local vs global state mainly a storage decision?**  
No. It is mainly a control and ownership decision about how data changes and who must agree on it.

---

## Key Takeaways

- Local vs global state is about scope, not just storage.
- Keep state as local as possible, but no more local than correctness allows.
- Promote state to global only when multiple distant consumers must agree on it.
- One logical value should have one authoritative source.
- Duplicated state creates inconsistency faster than it creates convenience.
- Global state improves coordination but increases coupling.
- Temporary UI details are usually local; shared application facts are usually global.
- The best question is: who owns this data, and who must stay in sync with it?

---

## Vocabulary

### Nouns (concepts)

**State**  
Data that can change over time and affects behavior or rendering. In this topic, the main issue is where that data should live.

**Local state**  
State scoped to one component or one small feature. It is usually read and updated by a single owner.

**Global state**  
State shared across broad parts of the application. It exists so multiple consumers can rely on the same value.

**Scope**  
The area of the application in which a value matters. Scope helps decide whether state should stay local or be shared.

**Owner**  
The part of the system responsible for holding and changing a piece of state. Clear ownership improves correctness.

**Consumer**  
A part of the UI or logic that reads a value. The number and distance of consumers strongly affect scope decisions.

**Source of truth**  
The authoritative location of a logical value. If multiple copies exist, only one should be considered the real one.

**Duplication**  
Storing the same logical data in multiple places. Duplication is a common cause of mismatch bugs.

**Derived state**  
A value computed from existing state instead of stored separately. It reduces synchronization problems.

**Synchronization**  
The act of keeping multiple values or views consistent with each other. Good state design tries to minimize manual synchronization.

**Coupling**  
A dependency between parts of a system. Too much global state can increase coupling between unrelated features.

**Transient data**  
Short-lived data that matters only for a brief interaction. This is often a good candidate for local state.

### Verbs (actions)

**Read**  
To consume a value in order to render UI or make a decision. Reading patterns help reveal whether state is local or shared.

**Write**  
To change a value. The more writers a value has, the more control and structure it usually needs.

**Share**  
To expose one value to multiple consumers. Sharing is the main reason state moves from local to global.

**Promote**  
To move state from a narrow scope to a wider scope. This happens when the data becomes relevant to more of the app.

**Derive**  
To compute one value from another value. Deriving avoids storing redundant copies of the same information.

**Synchronize**  
To keep different views or copies aligned. A strong local-vs-global decision reduces how much manual synchronization is needed.

### Adjectives (properties)

**Local**  
Limited in scope to one small area. Local state is easier to reason about because fewer parts can affect it.

**Global**  
Shared across large parts of the application. Global state is useful for consistency but requires careful control.

**Shared**  
Used by more than one consumer. Shared data often needs a clearly defined owner and update path.

**Authoritative**  
Considered the official correct value. An authoritative source prevents arguments between multiple copies.

**Consistent**  
In agreement across all readers and views. Good state management tries to keep shared data consistent at all times.

**Transient**  
Temporary and short-lived. Transient values are usually better kept local.
