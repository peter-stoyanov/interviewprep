# Frontend Folder Structure and Scalability

**Abstraction level**: pattern  
**Category**: frontend architecture

---

## Related Topics

- **Implementations of this**: feature-based structure
- **Implementations of this**: layered frontend architecture
- **Depends on this**: separation of concerns
- **Works alongside**: state management
- **Works alongside**: routing
- **Contrast with**: file-type-based structure
- **Temporal neighbors**: reusable component design

---

## What is it

Frontend folder structure is the pattern used to decide where frontend code lives in a project. Scalability means that the structure still works when the app gets more screens, more logic, more data flows, and more developers. It is not mainly about making the tree look clean. It is about making ownership, change, and data flow easy to understand.

The data here is source code and the meanings inside it: UI pieces, request logic, validation rules, mapping functions, styles, and tests. At rest, that data lives in folders and files in the repository; at runtime, parts of it are loaded into browser memory. Developers read and write it, the build system bundles it, and the browser executes the result. Over time, new features add files, old features split into smaller parts, and some code becomes shared across multiple parts of the app.

---

## What problem does it solve

Start with a small app with two pages: products and checkout. One folder with a few files is enough because there are only a few data flows:

- product data comes from the server
- the page renders it
- the user changes cart state
- checkout sends a payload back to the server

Now the app grows:

- products have filtering, sorting, and pagination
- checkout has validation, error handling, and multiple steps
- account pages reuse user data
- several developers edit the app at the same time

Without a clear structure, the project usually fails in predictable ways:

- **Duplication**: the same mapping or validation logic is copied into several places
- **Inconsistency**: one area treats `price` as a number, another as a formatted string
- **Invalid data**: request-building logic is scattered, so one screen sends incomplete or wrong payloads
- **Hard-to-track changes**: one feature change requires searching across `components`, `utils`, `api`, `hooks`, and `pages`
- **Unclear ownership**: new files get dropped into `shared`, `common`, or `helpers` because nobody knows the correct home

The core problem is uncontrolled change. If related code is spread across the project, then the path from input data to rendered UI or outgoing request becomes hard to follow. Folder structure solves that by making grouping and boundaries explicit.

---

## How does it solve it

### 1. Group by reason to change

Code that changes together should live together. If a search feature has a search box, request building, response mapping, and result rendering, those parts usually change as one unit.

- **Data flow**: input enters one feature area, gets transformed there, and leaves in a known shape
- **Control**: most edits stay inside one folder boundary
- **Predictability**: when a feature changes, the starting point is obvious

### 2. Keep feature code local by default

Most code is not truly global. A validator used only by checkout belongs to checkout, even if it is technically reusable.

- **Data flow**: feature-specific data stays near the feature that owns it
- **Control**: fewer accidental imports from unrelated areas
- **Predictability**: shared folders contain less noise

### 3. Promote to shared only after real reuse

Shared code should exist because multiple features need the same behavior, not because the name looks generic. Moving code to shared too early often creates hidden coupling.

- **Data flow**: shared code handles common transformations, not one feature's special case
- **Control**: the shared surface stays small
- **Predictability**: developers trust that shared code is stable and broadly useful

### 4. Make boundaries visible

A good structure makes levels of responsibility obvious, such as app-level setup, feature-level logic, and shared primitives. Visible boundaries make it easier to see who depends on whom.

- **Data flow**: data crosses boundaries in deliberate ways
- **Control**: dependency direction is easier to enforce mentally and in reviews
- **Predictability**: developers can tell whether a file is local, shared, or infrastructural

### 5. Keep transformations close to their source or destination

If server data needs reshaping before the UI can use it, that mapping should live near the feature using it. If a form needs to build a request payload, that transformation should live near the form or feature boundary.

- **Data flow**: raw data -> transform -> validated feature data -> UI or request
- **Control**: one place owns each important transformation
- **Predictability**: the same data is shaped the same way every time

### 6. Optimize for change cost

Scalable structure reduces the number of folders, files, and people touched by one change. The goal is not a perfect taxonomy. The goal is lower search cost, lower merge conflict risk, and fewer accidental breakages.

---

## What if we didn't have it (Alternatives)

### 1. One large app folder

```text
src/
  app.js
  cart.js
  checkout.js
  products.js
  utils.js
```

This works for very small apps. It breaks when unrelated logic starts sharing the same files, so every change increases coupling.

### 2. Organize only by file type

```text
components/
pages/
api/
utils/
styles/
```

This looks neat, but one feature is now spread across many folders. A simple checkout change becomes a project-wide search problem.

### 3. Put uncertain code into `utils`

```js
// utils.js
export function buildOrderPayload(form) {
  return { ...form, total: Number(form.total) };
}
```

This is a common quick hack. At scale, `utils` becomes a mix of unrelated transformations with unclear ownership, and different features start depending on each other's details.

### 4. Copy logic into each feature

```js
const total = items.reduce((sum, item) => sum + item.price, 0);
```

Copying feels fast at first. Later, one team fixes tax handling in one copy and forgets the others, so the same business idea produces different results in different screens.

### 5. Over-abstract too early

```text
core/
base/
common/
entities/
modules/
```

This is the opposite failure. The structure sounds advanced, but if the boundaries do not match real data flow and real feature ownership, developers still do not know where code belongs.

---

## Examples

### Example 1: Minimal conceptual structure

```text
src/
  app/
  features/
  shared/
```

This is enough to express three jobs: app startup, feature-owned code, and genuinely reusable code.

### Example 2: Incorrect vs correct feature locality

Incorrect:

```text
api/orders.js
components/OrderTable.js
utils/mapOrder.js
```

Correct:

```text
features/orders/
  OrderTable.js
  api.js
  mapOrder.js
```

The correct version keeps one flow together: fetch orders -> map orders -> render orders.

### Example 3: Keeping request building near the feature

```text
features/checkout/
  CheckoutForm.js
  validateCheckout.js
  buildCheckoutPayload.js
  api.js
```

Flow:

```text
user input -> validate -> build payload -> send request -> handle response
```

The folder mirrors the actual change path of the data.

### Example 4: Shared only after proven reuse

Too early:

```text
shared/formatCurrency.js
```

Better at first:

```text
features/orders/formatCurrency.js
```

Move it to `shared` only when multiple features use the same formatting rules. Otherwise shared code becomes a storage area for guesses.

### Example 5: Real-world analogy

Imagine a company where all documents are stored by paper type:

- invoices in one cabinet
- letters in another
- approvals in another

Now try to handle one customer issue. You must visit several cabinets to reconstruct one story. A feature-based folder structure is like storing all documents for one customer case together.

### Example 6: Incorrect vs correct ownership

Incorrect:

```js
// shared/helpers.js
export function normalizeProfileResponse(data) {
  return {
    name: data.full_name,
    joinedAt: data.created_at
  };
}
```

Correct:

```js
// features/profile/normalizeProfileResponse.js
export function normalizeProfileResponse(data) {
  return {
    name: data.full_name,
    joinedAt: data.created_at
  };
}
```

The transformation belongs to profile data. Naming it "shared" hides that ownership.

### Example 7: Team scaling

```text
features/search/
features/cart/
features/checkout/
```

Three developers can work with fewer collisions because each feature has a clear area. Structure does not remove coordination, but it reduces unnecessary overlap.

---

## Quickfire (Interview Q&A)

**Q: What is frontend folder structure?**  
A: It is the pattern used to decide where frontend code lives so related logic stays grouped and changes stay understandable.

**Q: What does "scalable" mean in this context?**  
A: It means the structure still works when features, code size, and team size increase.

**Q: What is the main purpose of a good folder structure?**  
A: To control ownership and data flow so changes are easier to make safely.

**Q: Why is organizing only by file type often weak at scale?**  
A: Because one feature gets split across many folders, which hides the full path of the data.

**Q: Why is feature-based grouping common?**  
A: Because features often change as units, so grouping by feature keeps related edits local.

**Q: When should code move into a shared folder?**  
A: After multiple features clearly need the same behavior or transformation.

**Q: What is a common smell of a weak structure?**  
A: Large `utils`, `helpers`, or `common` folders with unrelated code and vague ownership.

**Q: Is folder structure only about cleanliness?**  
A: No. It affects correctness, change speed, merge conflicts, and how fast developers can find the right code.

**Q: What is the trade-off of adding more structure?**  
A: Better control and locality, but more decisions about boundaries and naming.

**Q: Can a small app start simple?**  
A: Yes. The structure should match current complexity, but it should still leave a clean path for growth.

---

## Key Takeaways

- Folder structure is a way to control how frontend code changes.
- A scalable structure optimizes for change, not for visual neatness.
- Group code by feature or responsibility, not only by file type.
- Keep transformations close to the data they transform.
- Shared code should be truly shared, not just unnamed leftover logic.
- Good boundaries reduce duplication, coupling, and search cost.
- Clear ownership makes bugs and changes easier to trace.

---

## Vocabulary

### Nouns (concepts)

**Folder structure**  
The arrangement of files and folders in a project. In this topic, it is the visible map of ownership and boundaries.

**Feature**  
A unit of user-facing behavior, such as search or checkout. Features are often a good unit for grouping frontend code because they change together.

**Boundary**  
A line between parts of the codebase. It helps show what belongs together and where dependencies cross.

**Shared code**  
Code used by more than one feature. It should contain stable, generic behavior rather than one feature's special rules.

**Ownership**  
The answer to "which part of the codebase is responsible for this logic?" Good structure makes that answer obvious.

**Coupling**  
The degree to which one part of the code depends on another. High coupling makes changes spread further than necessary.

**Locality**  
The property that related files are physically near each other. High locality lowers search cost and makes change easier to reason about.

**Transformation**  
A change from one data shape to another, such as converting server data into UI-ready data. Folder structure should make these transformations easy to find.

### Verbs (actions)

**Group**  
To place related files together because they serve one feature or one responsibility.

**Separate**  
To keep different concerns in different places so unrelated changes do not collide.

**Share**  
To make code available to multiple features. Good sharing is deliberate and based on real reuse.

**Scatter**  
To spread related logic across many folders. Scattered code makes data flow harder to follow.

**Refactor**  
To reorganize code without changing behavior. Folder structures often need refactoring as the project grows.

### Adjectives (properties)

**Scalable**  
Able to handle growth in features, files, and contributors without becoming confusing or fragile.

**Feature-specific**  
Owned by one feature and mainly useful there. This code usually should stay local.

**Shared**  
Used across multiple parts of the app. Shared code should have clear, stable meaning.

**Cohesive**  
Describes code that belongs together because it serves one clear purpose. High cohesion usually signals a healthy folder boundary.

**Implicit**  
Not clearly expressed in structure or naming. Implicit ownership and implicit dependencies make large codebases harder to understand.
