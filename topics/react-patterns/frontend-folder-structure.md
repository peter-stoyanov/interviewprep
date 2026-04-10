# Frontend Folder Structure and Scalability

**Abstraction level**: pattern
**Category**: frontend architecture

---

## Related Topics

- **Implementations of this**: feature-based structure, layered frontend architecture, monorepo package boundaries
- **Depends on this**: separation of concerns, component design
- **Works alongside**: state management, routing, testing strategy
- **Contrast with**: file-type-based structure, backend service boundaries
- **Temporal neighbors**: learn after component basics and before large-scale frontend architecture

---

## What is it

Frontend folder structure is the way a frontend codebase is divided into folders so data, UI, and logic have clear places to live. Scalability means that as features, people, and code increase, the structure still makes it easy to find code, change code, and avoid accidental breakage.

In simple terms:

- **Data**: UI state, server responses, input values, validation rules, mapping functions, styles, tests
- **Where it lives**: files and folders in the frontend project, then in browser memory when the app runs
- **Who reads/writes it**: developers change the files; the build system bundles them; the browser executes them
- **How it changes over time**: new features add files, existing features grow, shared code gets reused, and ownership spreads across more developers

Folder structure is just a way to control where code goes and how related pieces stay together.

---

## What problem does it solve

Start with a small app: a login page and a dashboard. A few files in one folder are fine because there is little data and little change.

Then the app grows:

- the dashboard has charts, filters, tables, and forms
- several pages use the same user data
- API calls, validation, and display logic become more complex
- multiple developers edit the same area at the same time

Without a clear structure, common failure modes appear:

- **Duplication**: the same API mapping or validation logic is copied into several folders
- **Inconsistency**: one page keeps `price` as a number, another treats it as a string
- **Invalid data flow**: UI code directly reshapes server data in different ways in different places
- **Hard-to-track changes**: changing one feature requires searching the whole project for related files
- **Unclear ownership**: nobody knows where a new file belongs, so everything ends up in `utils`, `helpers`, or `components`

The real problem is not "too many files". The real problem is uncontrolled coupling. If related code is scattered, data transformations become hidden, ownership becomes vague, and small changes produce large search costs.

---

## How does it solve it

### 1. Group code by reason to change

Put code together when it changes for the same feature or responsibility. A checkout form's UI, validation, and request mapping often change together, so they should be near each other.

- **Data flow**: data enters a feature boundary, gets validated or transformed there, then flows out
- **Control**: changes stay local to one area
- **Predictability**: when a feature changes, developers know where to start

### 2. Separate shared code from feature code

Not everything should be global. Most code belongs to one feature. Only code used across multiple features should move to shared folders.

- **Data flow**: feature-specific data stays inside the feature; generic helpers stay outside
- **Control**: fewer accidental dependencies
- **Predictability**: shared folders contain truly shared logic, not random leftovers

### 3. Make boundaries visible

A folder boundary is a simple signal: this code belongs together. Good boundaries show whether a file is page-level, feature-level, domain-level, or shared infrastructure.

- **Data flow**: inputs and outputs cross boundaries explicitly
- **Control**: fewer hidden imports between unrelated areas
- **Predictability**: dependencies become easier to reason about

### 4. Keep transformations close to the data they transform

If server data for `orders` needs mapping before the UI uses it, that mapping should live near the `orders` feature, not in a distant generic folder.

- **Data flow**: raw data -> mapping -> validated UI-ready data
- **Control**: one obvious place owns the transformation
- **Predictability**: the same data is shaped the same way everywhere

### 5. Optimize for change, not for aesthetics

A structure is good if it reduces search time, merge conflicts, and accidental breakage. A perfectly neat tree that forces developers to jump across ten folders for one feature is not scalable.

---

## What if we didn't have it (Alternatives)

### 1. One big `components` folder

```text
components/
  Button.js
  LoginForm.js
  OrderTable.js
  UserSettings.js
  ...
```

This works early. At scale, features get mixed together, shared and feature-specific code look the same, and finding related files becomes slow.

### 2. Structure only by file type

```text
components/
api/
hooks/
utils/
styles/
```

This feels tidy, but one feature is spread across many folders. A single change to checkout may touch five directories, which increases coupling and search cost.

### 3. Put unclear code into `utils`

```js
// utils/format.js
export function normalizeOrder(order) { ... }
```

This is a common quick hack. It breaks at scale because `utils` becomes a dump for unrelated transformations, and ownership disappears.

### 4. Copy code into each feature

```js
// Feature A
const total = items.reduce(sumPrices, 0);

// Feature B
const total = items.reduce(sumPrices, 0);
```

This avoids shared folders at first, but duplicated logic drifts over time. One fix lands in one place and not the other.

---

## Examples

### Example 1: Minimal conceptual structure

```text
src/
  app/
  features/
  shared/
```

This already expresses three different jobs: app setup, feature code, and reusable code.

### Example 2: Bad vs good feature locality

Incorrect:

```text
api/orders.js
components/OrderTable.js
utils/orderMapper.js
```

Correct:

```text
features/orders/
  OrderTable.js
  api.js
  mapOrder.js
```

The correct version keeps one data flow together: fetch orders -> map orders -> render orders.

### Example 3: Shared code only when reuse is real

Too early:

```text
shared/
  DateLabel.js
```

Better:

```text
features/invoices/DateLabel.js
```

Move it to shared only after multiple features need the same behavior. Premature sharing creates coupling.

### Example 4: Browser-to-server flow

```text
features/profile/
  edit-form.js
  validate-profile.js
  map-profile-request.js
  api.js
```

Flow:

```text
user input -> validate -> map request -> send -> receive response -> update UI
```

The folder mirrors the real data flow of the feature.

### Example 5: Incorrect ownership

Incorrect:

```js
// shared/utils.js
export function buildCheckoutPayload(form) { ... }
```

Correct:

```js
// features/checkout/buildCheckoutPayload.js
export function buildCheckoutPayload(form) { ... }
```

This transformation belongs to checkout data, not to the whole app.

### Example 6: Scaling a team

```text
features/search/
features/cart/
features/checkout/
```

Three developers can work mostly independently because each feature has a clear area. The structure reduces collisions and makes review easier.

---

## Quickfire (Interview Q&A)

**Q: What is frontend folder structure?**  
A: It is the way frontend code is organized so related files are grouped and changes stay understandable.

**Q: What does "scalable" mean here?**  
A: It means the structure still works when the codebase, feature count, and team size grow.

**Q: What is the main goal of a good folder structure?**  
A: To control how code is grouped so related data and transformations stay close and changes stay local.

**Q: Why is a file-type-based structure often weak at scale?**  
A: Because one feature gets split across many folders, which makes data flow harder to follow.

**Q: Why is feature-based grouping common?**  
A: Because features often change as units, so grouping by feature reduces search and coordination cost.

**Q: When should code move to a shared folder?**  
A: Only when multiple features genuinely use the same behavior or abstraction.

**Q: What is a common smell in bad folder structures?**  
A: Large `utils`, `helpers`, or `common` folders with unrelated code and unclear ownership.

**Q: Is folder structure only about cleanliness?**  
A: No. It affects correctness, change speed, merge conflicts, and how easily developers understand data flow.

**Q: Can a small app use a simple structure?**  
A: Yes. Structure should match current complexity, but it should still leave room for controlled growth.

**Q: What is the trade-off of more structure?**  
A: Better control and locality, but more decisions about boundaries and naming.

---

## Key Takeaways

- Folder structure is a way to control where frontend code lives.
- A scalable structure optimizes for change, not for visual neatness.
- Group code by feature or responsibility, not only by file type.
- Keep data transformations close to the feature that owns the data.
- Shared folders should contain truly shared code, not uncertain code.
- Good boundaries reduce duplication, coupling, and search cost.
- A bad structure makes ownership unclear and bugs harder to trace.

---

## Vocabulary

### Nouns (concepts)

**Folder structure**  
The arrangement of folders and files in a project. In this topic, it is the mechanism for expressing ownership and boundaries.

**Feature**  
A unit of user-facing functionality, such as checkout or search. Features are often the best unit for grouping related frontend code.

**Boundary**  
A visible separation between parts of the codebase. Boundaries control which code belongs together and how dependencies cross between areas.

**Shared code**  
Code reused by multiple features. It should be generic and stable enough that centralizing it reduces duplication instead of creating coupling.

**Coupling**  
A situation where parts of the system depend on each other tightly. High coupling makes changes spread further than necessary.

**Ownership**  
The clear answer to "which part of the codebase is responsible for this logic or data transformation?" Good structure makes ownership obvious.

**Locality**  
The property that related code is physically near other related code. High locality reduces search time and makes changes easier to reason about.

**Transformation**  
A change from one data shape to another, such as mapping server data into UI-ready data. Good folder structure keeps transformations near the feature that owns them.

### Verbs (actions)

**Group**  
To place related files together based on shared purpose or shared change. Grouping is the core action behind code organization.

**Separate**  
To keep different responsibilities in different places. Separation prevents unrelated changes from colliding.

**Reuse**  
To use the same code in more than one feature. Reuse is useful, but only after the shared behavior is real and stable.

**Scatter**  
To spread related logic across many folders. Scattered code makes data flow harder to follow and changes harder to make safely.

**Refactor**  
To reorganize code without changing behavior. Folder structure often needs refactoring as the project grows.

### Adjectives (properties)

**Scalable**  
Able to handle growth in code, features, and contributors without becoming confusing or fragile.

**Shared**  
Used by more than one feature or area of the app. Shared code should be intentionally generic.

**Feature-specific**  
Owned by one feature and mainly useful there. This code usually should not live in global folders.

**Cohesive**  
Describes code that belongs together because it serves one clear purpose. High cohesion is a sign of a healthy boundary.

**Implicit**  
Not made clear in the structure or API. Implicit ownership and implicit dependencies are common causes of confusion in large frontend codebases.
