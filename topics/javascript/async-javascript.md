# Asynchronous JavaScript: Promises and async/await

**Abstraction level**: language feature / pattern
**Category**: concurrency, control flow, JavaScript runtime

---

## Related Topics

- **Depends on this**: fetch API, Node.js I/O, service workers, WebSockets
- **Works alongside**: error handling (try/catch), event loop, callbacks
- **Contrast with**: synchronous execution, callback-based patterns
- **Implementations of this**: `Promise`, `async/await`, `Promise.all`, `AbortController`
- **Temporal neighbors**: learn the event loop first; learn async iterators and streams after

---

## What is it

Asynchronous JavaScript is a way to handle operations that take time — network requests, file reads, timers — without blocking execution. Instead of waiting, the program continues running and handles the result when it arrives.

A **Promise** is an object representing the eventual result (or failure) of an async operation. **async/await** is syntax built on top of Promises that makes async code look and read like synchronous code.

- **Data**: the eventual result value, or an error
- **Where it lives**: in memory, as a pending/resolved/rejected Promise object
- **Who reads/writes it**: the caller registers callbacks (`.then`, `.catch`) or uses `await` to receive the resolved value
- **How it changes**: a Promise transitions once — from pending to either fulfilled or rejected; it never changes again

---

## What problem does it solve

JavaScript runs in a single thread. Without async, one slow operation blocks everything else.

**Simple scenario**: you fetch user data from a server. That call takes 300ms. If JS waited synchronously, nothing — no UI updates, no other code — could run during those 300ms. On a page with multiple requests, this stacks up and freezes the browser.

**Without proper async patterns:**

```js
// Callback hell — nested, hard to read, hard to handle errors
fetchUser(id, function(user) {
  fetchPosts(user.id, function(posts) {
    fetchComments(posts[0].id, function(comments) {
      // deeply nested, error handling scattered
    });
  });
});
```

Failure modes without a structured async pattern:
- **Callback hell**: deeply nested, unreadable code
- **Inconsistent error handling**: errors get silently swallowed or handled in incompatible ways
- **Hard-to-track flow**: control jumps around unpredictably
- **Race conditions**: multiple async operations complete in unknown order with no coordination

---

## How does it solve it

### 1. Promises represent future values explicitly

A `Promise` is a container for a value that doesn't exist yet. It gives you a handle you can pass around, chain, and reason about — before the value arrives.

States:
- **pending**: operation not yet complete
- **fulfilled**: completed successfully, carries a value
- **rejected**: failed, carries an error

Once settled (fulfilled or rejected), a Promise never changes state.

### 2. Chaining flattens nested async

`.then()` returns a new Promise. This lets you chain operations in sequence without nesting:

```js
fetchUser(id)
  .then(user => fetchPosts(user.id))
  .then(posts => render(posts))
  .catch(err => handleError(err));
```

Each `.then` receives the resolved value of the previous step. A single `.catch` handles errors from any step in the chain.

### 3. async/await makes async code read like sync

`async` marks a function as returning a Promise. `await` pauses execution *inside* that function until the Promise resolves, then gives you the value directly.

```js
async function loadPage(userId) {
  const user = await fetchUser(userId);
  const posts = await fetchPosts(user.id);
  render(posts);
}
```

This is syntactic sugar over `.then` chains. The behavior is identical; the readability is much better.

### 4. Structured error handling

With `async/await`, you use standard `try/catch` — the same pattern as synchronous code:

```js
async function load(id) {
  try {
    const data = await fetch(`/api/${id}`);
    return await data.json();
  } catch (err) {
    console.error('Failed:', err);
  }
}
```

### 5. Coordinating multiple async operations

`Promise.all` runs operations in parallel and waits for all of them:

```js
const [user, settings] = await Promise.all([fetchUser(id), fetchSettings(id)]);
```

`Promise.race` resolves as soon as the first one settles.

---

## What if we didn't have it

### Callbacks only

```js
setTimeout(function() {
  getData(function(result) {
    process(result, function(output) {
      save(output, function() { /* done */ });
    });
  });
}, 1000);
```

Breaks at scale: error handling requires a callback argument at every level (`cb(err, result)`), errors are easy to miss, and nesting makes the flow hard to follow.

### Synchronous blocking (not viable in browsers)

```js
const data = syncFetch('/api/data'); // hypothetical
```

Freezes the UI thread. No other events can be processed. Not possible for network I/O in browsers; deeply problematic in Node.js.

### Home-grown event emitters

Some codebases use `EventEmitter` patterns to signal completion. These work but have no standardized chaining or error propagation — each library invents its own conventions.

---

## Examples

### Example 1 — Creating a Promise manually

```js
const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

wait(1000).then(() => console.log('1 second passed'));
```

`resolve` is called when the operation completes. The `.then` callback runs after.

### Example 2 — Promise states

```js
const p = fetch('/api/data');
// p is immediately a Promise in "pending" state
// when the response arrives, p becomes "fulfilled"
// if the network fails, p becomes "rejected"
```

### Example 3 — Chaining vs nesting

```js
// Nested (callbacks)
getA(function(a) {
  getB(a, function(b) {
    getC(b, function(c) { use(c); });
  });
});

// Chained (Promises)
getA().then(getB).then(getC).then(use).catch(handleError);
```

The chained version is linear and has one error handler for all steps.

### Example 4 — async/await with error handling

```js
async function getUser(id) {
  try {
    const res = await fetch(`/users/${id}`);
    if (!res.ok) throw new Error('Not found');
    return await res.json();
  } catch (err) {
    return null;
  }
}
```

### Example 5 — Sequential vs parallel

```js
// Sequential — total time: A + B
const a = await fetchA();
const b = await fetchB();

// Parallel — total time: max(A, B)
const [a, b] = await Promise.all([fetchA(), fetchB()]);
```

Use `Promise.all` when operations are independent.

### Example 6 — Common mistake: forgetting await

```js
// Bug: result is a Promise, not the value
async function bad() {
  const data = fetchData(); // missing await
  console.log(data); // logs Promise { <pending> }
}

// Correct
async function good() {
  const data = await fetchData();
  console.log(data); // logs actual data
}
```

### Example 7 — Promise.all vs Promise.allSettled

```js
// Promise.all rejects as soon as one rejects
await Promise.all([ok(), fails(), ok()]); // throws immediately

// Promise.allSettled waits for all, reports each outcome
const results = await Promise.allSettled([ok(), fails(), ok()]);
// [{ status: 'fulfilled', value: ... }, { status: 'rejected', reason: ... }, ...]
```

---

## Quickfire (Interview Q&A)

**Q: What are the three states of a Promise?**
Pending, fulfilled, and rejected. A Promise can only transition once and never goes backwards.

**Q: What does `async` do to a function's return value?**
It wraps the return value in a Promise. Even if you return a plain value, the caller receives a Promise that resolves to it.

**Q: What does `await` actually do?**
It pauses execution inside an `async` function until the Promise resolves, then unwraps the value. It does not block the main thread.

**Q: How do you handle errors with async/await?**
Use `try/catch` around `await` calls. Alternatively, attach `.catch()` to the returned Promise.

**Q: What's the difference between `Promise.all` and `Promise.allSettled`?**
`Promise.all` short-circuits on the first rejection. `Promise.allSettled` waits for all and reports the outcome of each.

**Q: Can you `await` a non-Promise value?**
Yes. `await 42` just resolves immediately to `42`. It's valid but unnecessary.

**Q: What is callback hell?**
Deeply nested callbacks required to handle sequential async operations, making code hard to read and error handling fragmented.

**Q: Is async/await just syntactic sugar?**
Yes. It compiles to Promise chains under the hood. The runtime behavior is identical; only the syntax changes.

**Q: What happens if you don't `catch` a rejected Promise?**
In Node.js, it throws an `UnhandledPromiseRejection` warning (and can crash the process). In browsers, it fires a `unhandledrejection` event and may be silently ignored.

**Q: When would you use `Promise.race`?**
To implement a timeout — race a real request against a `setTimeout` that rejects, so you reject if the request takes too long.

**Q: What's the difference between `.then(onFulfilled, onRejected)` and `.then().catch()`?**
With two arguments to `.then`, the `onRejected` handler does not catch errors thrown inside `onFulfilled`. A separate `.catch()` at the end handles errors from any step.

---

## Key Takeaways

- A Promise is a container for a value that will exist in the future; it has three states and settles exactly once.
- async/await is syntax sugar over Promises — same behavior, better readability.
- Chaining `.then()` creates a flat, readable sequence instead of nested callbacks.
- A single `.catch()` at the end of a chain handles errors from any step.
- `await` does not block the main thread; it only pauses execution within the current `async` function.
- Use `Promise.all` to run independent async operations in parallel, not sequentially.
- Forgetting `await` is a common bug — you get a Promise object instead of the resolved value.

---

## Vocabulary

### Nouns (concepts)

**Promise** — an object representing the eventual result of an async operation; it is either pending, fulfilled, or rejected.

**async function** — a function declared with `async`; always returns a Promise, even if you return a plain value.

**await expression** — pauses an async function until the given Promise settles and unwraps its value.

**callback** — a function passed as an argument to be called when an async operation completes; the predecessor pattern to Promises.

**callback hell** — a deeply nested structure of callbacks required for sequential async operations; also called "pyramid of doom."

**microtask queue** — where Promise resolution callbacks are queued; processed before the next macrotask (e.g. `setTimeout`).

**rejection** — the failure state of a Promise, carrying an error or reason.

**fulfillment** — the success state of a Promise, carrying a resolved value.

**Promise.all** — takes an array of Promises and returns a new Promise that resolves when all resolve, or rejects when any one rejects.

**Promise.allSettled** — like `Promise.all` but waits for all Promises regardless of outcome and returns each result.

**Promise.race** — resolves or rejects as soon as the first Promise in the array settles.

**unhandled rejection** — a rejected Promise with no `.catch()` or `try/catch` handler; can cause runtime warnings or crashes.

### Verbs (actions)

**resolve** — to settle a Promise as fulfilled, passing a value to `.then` handlers.

**reject** — to settle a Promise as failed, passing a reason to `.catch` handlers.

**chain** — to attach `.then()` calls sequentially so each step receives the result of the previous.

**await** — to pause execution in an async function until a Promise settles.

**catch** — to handle a rejected Promise, either via `.catch()` or a `try/catch` block.

### Adjectives (properties)

**pending** — the initial state of a Promise; not yet settled.

**fulfilled** — a Promise that has resolved successfully with a value.

**rejected** — a Promise that has failed with a reason/error.

**settled** — a Promise that is either fulfilled or rejected; no longer pending.

**synchronous** — code that executes in order, blocking until each step is complete.

**asynchronous** — code that initiates an operation and continues executing without waiting for the result.
