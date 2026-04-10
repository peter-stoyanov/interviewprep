# Derived State

**Abstraction level**: concept / pattern
**Category**: state management

---

## Related Topics

- **Implementations of this**: selectors, computed values, memoized selectors
- **Depends on this**: UI synchronization, view models, rendering logic
- **Works alongside**: source of truth, normalization, validation
- **Contrast with**: stored state, cached state, duplicated state
- **Temporal neighbors**: learn state and data flow before this; then learn selectors and memoization

---

## What is it

Derived state is data that is computed from other existing data instead of being stored as an independent source of truth. It is usually a transformation such as count, total, filtered list, status label, or permission flag. The key idea is simple: if a value can be calculated from current state, that value does not need to be separately owned.

- **Data**: base data like items, user role, form fields, timestamps; derived data like totals, booleans, labels, filtered results
- **Where it lives**: usually in memory while the app is running; often in the browser, but the idea also applies on servers
- **Who reads/writes it**: code reads derived state, but code should write only the underlying source data
- **How it changes over time**: when source data changes, the derived value changes as a consequence

---

## What problem does it solve

Start with a cart:

```txt
items = [{ price: 10 }, { price: 20 }]
```

You want to show:

```txt
total = 30
```

At first, storing both `items` and `total` seems harmless. But as the app grows, every update to `items` must also update `total`. If one path forgets, the UI becomes wrong.

Without derived state, common failure modes appear:

- **Duplication**: the same meaning is stored twice, once as raw data and once as a computed copy
- **Inconsistency**: `items` says one thing, `total` says another
- **Invalid data**: a derived flag like `isComplete` becomes false or true at the wrong time because some dependent field changed
- **Hard-to-track changes**: many update paths must manually keep related values in sync
- **Unclear ownership**: developers stop knowing which value is authoritative

Derived state solves this by saying: store the minimal real data, then compute everything else from it.

---

## How does it solve it

### Principle 1: Keep one source of truth

Store only the base data that cannot be reconstructed from something else.

- **Data flow**: writes go to source data only
- **Control**: fewer writable values means fewer places where bugs can enter
- **Predictability**: every derived value comes from a known input set

### Principle 2: Compute, do not copy

If a value is just a transformation, calculate it when needed instead of storing another mutable version.

- **Data flow**: source data flows into a transformation, then into the UI or next step
- **Control**: the transformation is explicit instead of hidden in many update handlers
- **Predictability**: same input always gives same output

### Principle 3: Changes propagate by dependency

Derived state does not change by direct mutation. It changes because its inputs changed.

- **Data flow**: `source -> derivation -> consumer`
- **Control**: you track dependencies instead of manual sync code
- **Predictability**: if inputs are correct, output is correct

### Principle 4: Separate facts from views

Facts are the raw state. Views are interpretations of that state.

- **Data flow**: raw data stays stable; different consumers can derive different views from the same facts
- **Control**: each consumer can compute what it needs without owning new state
- **Predictability**: many outputs can stay consistent because they all start from the same base

### Principle 5: Correctness comes from derivation rules

A derived value is only valid if its formula matches the business rule.

- **Data flow**: correctness depends on accurate input data and correct mapping logic
- **Control**: validation focuses on the source data and derivation rule, not on syncing multiple copies
- **Predictability**: fewer stored copies means fewer stale values

---

## What if we didn't have it (Alternatives)

### 1. Store both source and computed value manually

```txt
items = [{ price: 10 }, { price: 20 }]
total = 30
```

Then an item is removed:

```txt
items = [{ price: 20 }]
total = 30
```

This breaks because the duplicated value was not updated. The data now disagrees with itself.

### 2. Update related fields in every write path

```txt
onAddItem:
  items.push(newItem)
  total = total + newItem.price
```

This looks efficient, but every add, remove, edit, reset, and server refresh must remember the same rules. The logic becomes scattered and easy to miss.

### 3. Store UI flags that can be calculated

```txt
password = "abc123"
confirm = "abc123"
isMatch = true
```

If `confirm` later changes and `isMatch` is not recalculated, the UI lies. `isMatch` is not independent state; it is a comparison result.

### 4. Use hidden informal rules

```txt
"Whenever status changes, remember to update canSubmit too."
```

This is a process rule, not a data rule. It depends on humans remembering sync steps, which does not scale.

---

## Examples

### Example 1: Minimal conceptual example

```txt
birthYear = 2000
currentYear = 2026
age = currentYear - birthYear
```

`age` is derived state. You should not store `age` separately if you already have the needed inputs.

### Example 2: Small code snippet

```js
const items = [{ price: 10 }, { price: 20 }]
const total = items.reduce((sum, item) => sum + item.price, 0)
```

`items` is the source data. `total` is a transformation of that data.

### Example 3: Incorrect vs correct

Incorrect:

```txt
firstName = "Ana"
lastName = "Stone"
fullName = "Ana Stone"
```

Then:

```txt
lastName = "Smith"
fullName = "Ana Stone"
```

Correct:

```txt
firstName = "Ana"
lastName = "Smith"
fullName = firstName + " " + lastName
```

The correct version stores facts and derives the display value.

### Example 4: Filtered list

```txt
products = [shoe, shirt, hat]
query = "sh"
visibleProducts = products matching query
```

`visibleProducts` depends on both `products` and `query`. If either input changes, the result should be recomputed, not manually edited.

### Example 5: Browser interaction

```txt
form = {
  email: "a@b.com",
  password: "secret123"
}
canSubmit = email is valid AND password length >= 8
```

`canSubmit` should come from validation rules. A button enabled state is usually derived from current input values, not stored on its own.

### Example 6: Server example

```txt
orders = [
  { status: "paid" },
  { status: "pending" },
  { status: "paid" }
]
paidCount = 2
```

`paidCount` is derived from the order list. If a pending order becomes paid, the count changes because the source data changed.

### Example 7: Real-world analogy

A warehouse has boxes as raw data. "How many fragile boxes are there?" is not a separate physical thing in the warehouse. It is a count derived from inspecting the boxes.

### Example 8: Multiple consumers from one source

```txt
user = { role: "admin", active: true }
canEdit = role is admin
statusLabel = active ? "Active" : "Disabled"
```

Two different consumers derive different outputs from the same user object. This avoids storing many overlapping copies.

---

## Quickfire (Interview Q&A)

### 1. What is derived state?

Data computed from other state instead of stored as its own independent source of truth.

### 2. Why is derived state useful?

It reduces duplication and keeps related values consistent because only base data is written directly.

### 3. What is the opposite of derived state?

Stored source state: the raw data that must exist because other values depend on it.

### 4. Is a filtered list usually source state or derived state?

Usually derived state, because it comes from existing data plus filter criteria.

### 5. Why is storing both source and derived values risky?

They can drift apart when one changes and the other does not.

### 6. Can a boolean be derived state?

Yes. Flags like `isEmpty`, `isValid`, or `canSubmit` are often computed from other values.

### 7. Does derived state have to be displayed in the UI?

No. It can also be used for decisions, permissions, validation, or control flow.

### 8. What should code mutate directly?

The source data, not the derived result.

### 9. Is derived state always recalculated every time?

Conceptually yes; in practice it may be cached, but it is still defined by its inputs.

### 10. What makes derived state correct?

Correct source data and a correct transformation rule.

---

## Key Takeaways

- Derived state is computed, not owned.
- Store facts once, then derive views from them.
- Writing both source and computed copies creates inconsistency risk.
- A derived value changes because its inputs changed.
- Many UI flags are derived state, not real stored state.
- Source data should be minimal but sufficient.
- Correct derivation improves predictability and debugging.

---

## Vocabulary

### Nouns (concepts)

- **State**: Data that exists at a point in time and may change later. Derived state is one kind of state relationship.
- **Source of truth**: The authoritative data that should be updated directly. Derived state depends on it.
- **Derived state**: A value computed from other state. It should usually not be independently written.
- **Dependency**: An input that a derived value relies on. If a dependency changes, the result may change.
- **Transformation**: A rule that maps input data into output data, such as summing, filtering, or formatting.
- **Selector**: A function or rule that reads source state and returns a derived value.
- **Validation**: Checking whether data satisfies rules. Validation results are often derived state.
- **Duplication**: Storing the same meaning in more than one place. Derived state helps avoid this.
- **Inconsistency**: A situation where related values disagree. This often happens when duplicated data is manually synced.
- **Cache**: A stored copy of computed data used for performance. It may hold derived state, but the real definition still comes from its inputs.

### Verbs (actions)

- **Derive**: Compute a value from existing data rather than storing it separately.
- **Compute**: Produce an output from inputs using a rule or formula.
- **Recalculate**: Compute again after the source data changes.
- **Transform**: Convert data from one form to another, such as items into a count.
- **Synchronize**: Keep multiple values aligned over time. Derived state reduces manual synchronization needs.
- **Mutate**: Change stored data directly. In this topic, mutation should target source state, not computed outputs.

### Adjectives (properties)

- **Derived**: Not original; produced from other data.
- **Stored**: Kept directly in state or memory as an owned value.
- **Stale**: No longer matching the current source data. Bad derived-state handling often creates stale values.
- **Consistent**: Multiple related values agree with the same underlying facts.
- **Deterministic**: Producing the same output from the same input. Good derivation rules should be deterministic.
