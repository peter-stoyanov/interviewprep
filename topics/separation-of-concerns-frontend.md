# Separation of Concerns in Frontend

**Abstraction level**: concept / pattern
**Category**: frontend architecture

---

## Related Topics

- **Implementations of this**: component-based architecture, container/presentational pattern, MVC, MVVM
- **Depends on this**: state management patterns, component design, testability
- **Works alongside**: single responsibility principle, dependency injection, layered architecture
- **Contrast with**: monolithic components, colocated logic, ad-hoc scripting
- **Temporal neighbors**: learn before diving into state management or component design patterns

---

## What Is It

Separation of concerns (SoC) is the practice of dividing a system into distinct sections, where each section is responsible for one thing and only one thing.

In frontend, the main concerns are: what data exists, how it changes, how it is displayed, and how the user interacts with it. These are different jobs. SoC means those jobs live in different places.

- **Data**: what the application knows (user info, a list of items, a loading flag)
- **Logic**: rules that decide how data changes (validate input, fetch on mount, transform a list)
- **View**: turning data into visible markup
- **Interaction**: capturing user events and translating them into actions

The goal is to change one concern without touching the others.

---

## What Problem Does It Solve

Start simple: a button that fetches a list of users and shows it.

Without SoC, a developer puts everything in one place: the fetch call, the error handling, the filtering logic, the HTML structure, and the click handler — all in one function or component.

This works at first. As complexity grows, problems appear:

**Duplication**: another screen needs the same user list. The fetch logic is copy-pasted. Now two places need to be updated when the API changes.

**Inconsistency**: one copy of the fetch gets updated, the other does not. The two screens behave differently.

**Untestable code**: you cannot test display logic without triggering a real network request. You cannot test the fetch logic without rendering a component.

**Unclear ownership**: a bug is reported. Is it in the data layer, the display, or the event handler? Nobody knows where to look.

**Fragile changes**: fixing a layout bug requires touching the same file as the business logic. A typo breaks both.

All of these are caused by the same root problem: multiple concerns are coupled inside one unit of code.

---

## How Does It Solve It

### 1. Give each concern a clear boundary

Split code so that data concerns, logic concerns, and display concerns cannot accidentally depend on each other's internals.

A display component should not know how data is fetched. A data-fetching module should not know how data will be rendered.

### 2. Define flow between concerns explicitly

Data flows in one direction: from source → through logic → into the view. User interaction flows back out: event → action → state update → re-render.

When flow is explicit, you can trace a bug along the path rather than searching everywhere.

### 3. Each unit is independently replaceable

If the display layer has no fetch logic inside it, you can replace the entire display without touching the fetch. If the data layer has no HTML, you can change the API contract without rewriting templates.

### 4. Each unit is independently testable

Logic can be tested with plain data inputs and outputs. Display can be tested by passing fake data. The two tests do not interfere.

### 5. Enforce boundaries through structure

Concerns are often enforced through: file structure, module imports, component hierarchy, and naming conventions. The structure makes violations visible.

---

## What If We Didn't Have It (Alternatives)

### Inline everything in one component

```js
function UserList() {
  const [users, setUsers] = useState([]);
  useEffect(() => {
    fetch('/api/users')
      .then(r => r.json())
      .then(data => setUsers(data.filter(u => u.active)));
  }, []);
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

This works once. It breaks when:
- another component needs the same filtered user list
- you want to test the filter logic without rendering
- the API changes and you need to find all callers

### Global state scattered across files

Each component reads and writes to a global object directly. There is no single owner of the data. When a bug causes bad state, you cannot tell which component wrote it or when.

### Event listeners and DOM manipulation mixed with business logic

```js
document.querySelector('#btn').addEventListener('click', () => {
  const val = document.querySelector('#input').value;
  if (val.length > 3) {  // validation
    fetch('/api/save', { body: val });  // network
    document.querySelector('#status').textContent = 'Saved';  // display
  }
});
```

All three concerns — validation, network, display update — are inside one event handler. Impossible to reuse or test any of them in isolation.

---

## Examples

### Example 1 — Minimal: three layers in plain terms

```
data layer:    fetch('/api/users') → returns raw list
logic layer:   filter(users, { active: true }) → returns filtered list
display layer: <UserList users={filteredUsers} /> → renders HTML
```

Each step takes the output of the previous one. None of them need to know how the others work.

---

### Example 2 — Container vs presentational component

```js
// Container: knows about data and logic
function UserListContainer() {
  const users = useUsers(); // fetches and filters
  return <UserList users={users} />;
}

// Presentational: knows only about display
function UserList({ users }) {
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

`UserList` can be tested with any fake array. `UserListContainer` can be changed to use a different data source without touching the markup.

---

### Example 3 — Logic extracted into a custom hook

```js
// Concern: data fetching and transformation
function useUsers() {
  const [users, setUsers] = useState([]);
  useEffect(() => {
    fetchUsers().then(data => setUsers(data.filter(u => u.active)));
  }, []);
  return users;
}

// Concern: display only
function UserList() {
  const users = useUsers();
  return <ul>{users.map(u => <li>{u.name}</li>)}</ul>;
}
```

The hook owns the data concern. The component owns the display concern.

---

### Example 4 — File structure as enforced separation

```
src/
  api/
    users.js        ← data: fetch calls, API contract
  store/
    usersSlice.js   ← state: how user data changes over time
  hooks/
    useUsers.js     ← logic: derived/transformed data
  components/
    UserList.jsx    ← display: markup only
```

The folder structure makes violations visible: if `UserList.jsx` imports from `api/`, something is wrong.

---

### Example 5 — Before and after a change

**Requirement**: change the API endpoint from `/api/users` to `/v2/users`.

Without SoC: the URL is embedded in 6 different components. You must find and update all 6.

With SoC: the URL lives only in `api/users.js`. One change, one file.

---

### Example 6 — Incorrect vs correct

**Incorrect**: display component decides what data is valid.

```js
function UserCard({ user }) {
  if (!user.email.includes('@')) return null; // validation in display
  return <div>{user.name}</div>;
}
```

**Correct**: validation happens before data reaches the display.

```js
// logic layer validates before passing down
const validUsers = users.filter(u => isValidEmail(u.email));
// display layer only renders
function UserCard({ user }) {
  return <div>{user.name}</div>;
}
```

---

## Quickfire (Interview Q&A)

**Q: What is separation of concerns?**
A: Dividing a system so each part has one responsibility — data, logic, or display — and those parts do not bleed into each other.

**Q: Why does it matter in frontend?**
A: Because UI code mixes many concerns by nature (events, data, rendering). Without explicit separation, it becomes untestable, duplicated, and fragile.

**Q: What are the main concerns in a frontend app?**
A: Data (what exists), logic (how it changes and is validated), display (how it is rendered), and interaction (how user events are handled).

**Q: How do you enforce separation in practice?**
A: Through file structure, module boundaries, naming conventions, and component hierarchy — making violations structurally obvious.

**Q: What is the container/presentational pattern?**
A: A container component owns data fetching and logic; a presentational component only receives props and renders markup.

**Q: How does SoC relate to testability?**
A: When concerns are separated, each can be tested in isolation — logic with unit tests, display with fake data, network calls with mocks.

**Q: What is the risk of putting business logic in display components?**
A: It becomes impossible to reuse the logic, test it without rendering, or change the display without risking logic bugs.

**Q: Is SoC the same as single responsibility principle?**
A: They are closely related. SRP says a module should have one reason to change. SoC says concerns should be split into separate modules. SRP is the principle; SoC is the application.

**Q: Can SoC be over-applied?**
A: Yes. Splitting trivial code into too many layers adds indirection without benefit. Apply it where change in one concern is likely to be independent from change in another.

**Q: How does unidirectional data flow support SoC?**
A: It enforces that data moves in one direction (source → view) and events move in the other (user → action → state). This makes the ownership of each concern explicit.

---

## Key Takeaways

- Separation of concerns means each unit of code is responsible for one job: data, logic, or display.
- When concerns are mixed, a change to one silently breaks another.
- The primary gains are testability, reusability, and the ability to change one layer without touching the others.
- Structure enforces separation — the file system and module imports make violations visible.
- Data should flow in one direction; concerns should not reach across layers to read each other's internals.
- SoC is not about more files — it is about clear ownership of data and behavior.
- The test question: can I change the display without touching any data logic? If no, concerns are mixed.

---

## Vocabulary

### Nouns (concepts)

**Concern**: a distinct responsibility within a system — in frontend: data, logic, display, or interaction. Each concern should have a clear owner.

**Layer**: a conceptual grouping of code by concern — e.g., the data layer, the presentation layer.

**Container component**: a component responsible for fetching data and holding logic. It passes data down to presentational components.

**Presentational component**: a component that only receives props and renders markup. It has no knowledge of where data comes from.

**Coupling**: when two pieces of code depend on each other's internals. High coupling means changing one requires changing the other.

**Module boundary**: the explicit interface between two concerns — what one module exposes to another, and what it hides.

**Single Responsibility Principle (SRP)**: the principle that a module should have only one reason to change. Closely related to SoC.

**Unidirectional data flow**: a pattern where data flows one way — from state to view — and events flow the other way — from view to state update.

### Verbs (actions)

**Separate**: to place different concerns into different files, modules, or components.

**Encapsulate**: to hide internal details of a concern so other concerns cannot depend on them.

**Compose**: to combine separated concerns together at a higher level without mixing their internals.

**Derive**: to compute a value from existing data (e.g., filtering a list) — a transformation concern, not a display concern.

### Adjectives (properties)

**Decoupled**: two units of code that do not depend on each other's internals. A goal of SoC.

**Testable**: code that can be verified in isolation, without requiring the full system to run.

**Reusable**: code that can be applied in multiple contexts without modification — enabled when concerns are separated.

**Cohesive**: a module where all its contents relate to the same concern. High cohesion is a sign of good separation.
