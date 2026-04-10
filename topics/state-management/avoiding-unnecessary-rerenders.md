# Avoiding unnecessary re-renders

**Abstraction level**: pattern
**Category**: frontend rendering performance

## Related Topics

- **Implementations of this**: component memoization
- **Implementations of this**: selector memoization
- **Depends on this**: component rendering model
- **Works alongside**: state colocation
- **Works alongside**: derived state
- **Contrast with**: reducing DOM mutations
- **Contrast with**: reducing network requests
- **Temporal neighbors**: rendering basics, profiling UI performance

## What is it

Avoiding unnecessary re-renders is a way to control when UI code runs again. A re-render is necessary when a part of the screen depends on data that changed. It is unnecessary when the UI code runs again even though its input data is effectively the same. The goal is not to stop rendering, but to make rendering happen only where data actually changed.

- **Data involved**: local state, shared state, input values, derived values
- **Where it lives**: mostly in browser memory inside the UI tree and state containers
- **Who reads/writes it**: rendering logic reads it; user events, timers, and network responses write it
- **How it changes over time**: an update changes some data, that update invalidates dependent UI, and only that UI should render again

## What problem does it solve

Start with a page that has a search box, a results list, and a static sidebar. Typing one letter changes only the query. If the whole page renders again on every keypress, the system does extra work for the sidebar, header, and unchanged rows even though their data did not change.

As the app grows, the cost grows too. A dashboard can have charts, lists, counters, filters, and forms. One small update can trigger a large wave of recomputation unless data ownership and dependencies are kept narrow.

Without this pattern, common failure modes appear:

- **Duplication**: the same derived value is recomputed or stored in multiple places
- **Inconsistency**: one part of the UI updates, another part still shows old derived data
- **Invalid data flow**: components receive fresh wrapper objects or copied state that do not represent a real change
- **Hard-to-track changes**: a tiny event causes a large render chain and it becomes unclear why
- **Unclear ownership**: state lives too high in the tree, so unrelated UI gets dragged into every update

The practical result is slow typing, laggy scrolling, wasted battery, and noisy performance debugging.

## How does it solve it

### 1. Narrow data ownership

Keep state close to the UI that actually changes it. If a text input owns its own temporary value, typing in that input should not force unrelated widgets to re-run.

This improves control because fewer parts of the tree depend on the update. The flow becomes easier to follow: local event, local state change, local render.

### 2. Render from real dependencies

Each UI part should depend only on the smallest data it needs. If a row only needs `row.name` and `row.selected`, it should not depend on the whole page state.

This improves predictability. When data changes, you can point to exactly which UI depends on it and which UI does not.

### 3. Keep inputs stable when meaning did not change

Many rendering systems can skip work only if they can tell that the input is the same. If you create a new object, array, or function every time, the system may treat it as new input even when the meaning is unchanged.

Stable inputs make control explicit. "Same data" should look like "same input" to the rendering system.

### 4. Derive expensive data only from the source that matters

Derived data such as filtered lists, grouped totals, or sorted rows should update only when their source inputs change. If the theme changes, a filtered list should not be recomputed unless the list data or filter changed.

This keeps data transformation aligned with true dependencies and reduces wasted recomputation.

### 5. Invalidate narrowly

When one item changes, invalidate that item and the few views that depend on it, not the whole page. A checkbox change in row 42 should affect row 42 and maybe a selected-count badge, not every row, header, and sidebar panel.

Narrow invalidation gives predictable flow: small change in, small update out.

### 6. Separate fast-changing and slow-changing data

Some data changes many times per second, such as mouse position or text input. Other data changes rarely, such as page metadata or static configuration. Mixing them in the same render path spreads high-frequency updates too far.

Separating hot data from cold data prevents one noisy signal from constantly waking up unrelated UI.

## What if we didn't have it (Alternatives)

### 1. Re-render everything on every change

```js
function onQueryChange(query) {
  state.query = query;
  renderPage(state);
}
```

This is simple, but it scales badly. Every keystroke reruns rendering for parts of the page that did not receive new data.

### 2. Copy data into many places

```js
headerCount = items.length;
sidebarCount = items.length;
tableCount = items.length;
```

This looks fast because each area reads its own local copy, but now you must update all copies correctly. One missed update creates inconsistent UI and makes render behavior harder to reason about.

### 3. Recreate wrapper inputs every time

```js
renderToolbar({ sortBy: "price", showTax: true });
```

This creates a new object on every call. Even if the values are the same, systems that compare input identity cannot tell that nothing meaningful changed.

## Examples

### 1. Minimal dependency example

`theme` affects page colors. `count` affects the counter label.

- Change `theme` -> recolor the frame
- Do not re-run counter logic if `count` stayed the same

The key idea is simple: rerender by dependency, not by proximity in the tree.

### 2. Whole-page render vs narrow render

```js
function onFilterChange(value) {
  pageState.filter = value;
  renderPage(pageState); // search box, results, sidebar, footer
}
```

Better:

```js
function onFilterChange(value) {
  searchState.filter = value;
  renderSearchArea(searchState); // only search-related UI
}
```

Same user action, smaller flow, less wasted work.

### 3. Unstable input vs stable input

Incorrect:

```js
renderRow(row, { selected: row.id === selectedId });
```

Correct:

```js
const rowViewState = selectedById[row.id];
renderRow(row, rowViewState);
```

In the first case, a fresh object is created every time. In the second, the row gets a stable input that changes only when that row's selection state changes.

### 4. Derived data should follow real inputs

```js
visibleItems = filter(items, query);
```

This should rerun when `items` changes or `query` changes. It should not rerun when `theme`, `panelOpen`, or `mouseX` changes, because those values do not change the filtered result.

### 5. Large list with one changed row

Imagine a table with 1,000 rows. The user checks one checkbox.

- Naive flow: rerender all 1,000 rows
- Better flow: rerender row 42 and the "1 selected" summary

The data change is tiny, so the invalidation should also be tiny.

### 6. Browser and server example

The browser receives a new notifications payload from the server.

- Data that changed: `notifications`
- UI that depends on it: badge count, notifications panel
- UI that does not depend on it: draft email text, left navigation, theme picker

Correct rendering follows the message flow from server data to the few views that read that data.

### 7. Real-world analogy

Think of a warehouse board with sections for incoming orders, staffing, and temperature. If one new order arrives, you update the orders section. You do not erase and rewrite the staffing and temperature sections too.

That is all this topic is: update the board areas whose data changed, leave the rest alone.

## Quickfire (Interview Q&A)

### 1. What is an unnecessary re-render?

It is when UI rendering runs again for a part of the screen whose effective input data did not change.

### 2. Is every re-render bad?

No. Re-renders are required for correctness when dependent data changes. The problem is wasted re-renders.

### 3. Why do unnecessary re-renders matter?

They waste CPU time, can cause input lag, and make performance problems harder to trace.

### 4. What usually causes them?

State stored too high, broad dependencies, unstable input references, and expensive derived data recomputed too often.

### 5. What is the core idea behind avoiding them?

Keep data ownership narrow and rerender only the UI that depends on changed data.

### 6. How is this different from reducing DOM updates?

A render is UI computation. A DOM update is a concrete browser change. You often want to reduce both, but they are not the same step.

### 7. Why does stable input matter?

If the system cannot tell that input is unchanged, it cannot safely skip work.

### 8. What role does derived data play?

Derived data should update only when its source data changes; otherwise you waste transformation work.

### 9. Is colocating state a performance optimization?

Yes, but it is also a design improvement because it makes ownership and update flow clearer.

### 10. What is a good interview summary for this topic?

Avoiding unnecessary re-renders means controlling data ownership and dependencies so a small state change causes a small, predictable UI update.

## Key Takeaways

- Re-render only where input data actually changed.
- Small ownership boundaries lead to small render boundaries.
- Stable inputs help the rendering system skip work safely.
- Derived data should follow true source dependencies.
- Broad shared state often creates broad unnecessary invalidation.
- Re-renders are not bugs; wasted re-renders are the problem.
- Good performance starts with clear data flow, not tricks.

## Vocabulary

### Nouns

- **Render**: The process of computing UI output from current data. In this topic, the goal is to do that work only where needed.
- **Re-render**: Running rendering again after data changes. It is necessary for correctness, but can be wasteful if the data did not really change for that view.
- **State**: Data that changes over time, such as input text, selected rows, or fetched results.
- **Dependency**: A piece of data that a UI part reads to decide what to show. Dependencies should be explicit and narrow.
- **Derived data**: Data computed from other data, such as a filtered list or total count. It should change only when its source changes.
- **Invalidation**: The act of marking some UI as needing recomputation because relevant data changed.
- **Ownership**: Which part of the system is responsible for storing and updating a piece of state.
- **Subtree**: A smaller branch of the UI tree under one parent. Good render control often means invalidating only one subtree.
- **Memoization**: Reusing a previous computed result when the inputs are the same. It is useful for avoiding repeated rendering or derivation work.
- **Reference**: The identity of an object, array, or function in memory. Stable references help systems detect unchanged input.

### Verbs

- **Derive**: Compute new data from existing data, such as filtering or sorting.
- **Invalidate**: Mark some computed UI or data as out of date because a dependency changed.
- **Propagate**: Let a change travel through the parts of the system that depend on it.
- **Memoize**: Store and reuse a previous result when the same inputs appear again.
- **Colocate**: Keep state near the code that owns and changes it, instead of placing it far away.

### Adjectives

- **Necessary**: A render is necessary when the UI depends on data that changed.
- **Unnecessary**: A render is unnecessary when the same UI work runs without a meaningful input change.
- **Stable**: An input is stable when it keeps the same identity and meaning across renders.
- **Shared**: Data used by multiple parts of the UI. Shared data needs careful ownership to avoid broad updates.
- **Derived**: Computed from source data rather than stored as a separate source of truth.
- **Expensive**: Work that costs noticeable time or CPU, such as rendering large lists or recalculating heavy transformations.
