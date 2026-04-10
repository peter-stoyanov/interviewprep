# JavaScript Event Loop

- **Abstraction level**: language runtime concept / concurrency model
- **Category**: JavaScript internals, asynchronous programming

---

## Related Topics

- **Implementations of this**: Node.js libuv, browser event loop (V8 + Web APIs)
- **Depends on this**: Promises, async/await, setTimeout, setInterval, fetch
- **Works alongside**: call stack, task queue, microtask queue, Web APIs
- **Contrast with**: multi-threaded concurrency (Java threads, OS threads), worker threads
- **Temporal neighbors**: learn callbacks first → then event loop → then Promises → then async/await

---

## What Is It

The event loop is the mechanism that lets JavaScript handle asynchronous operations despite being single-threaded. It continuously checks whether the call stack is empty, and if so, picks up queued tasks and pushes them onto the stack for execution.

- **Data**: function calls, callbacks, resolved promise handlers
- **Where it lives**: inside the JavaScript runtime (browser or Node.js)
- **Who reads/writes it**: the runtime itself — your code doesn't interact with it directly
- **How it changes over time**: tasks accumulate in queues; the loop drains them one at a time when the stack is clear

---

## What Problem Does It Solve

JavaScript runs on a single thread. There is only one call stack. Operations that take time — network requests, timers, file reads — would block everything if run synchronously.

**Without the event loop:**

1. You call `fetch()`. The browser hangs waiting for the response.
2. No user interaction, no rendering, no other code runs.
3. The page freezes.

The event loop solves this by **offloading** slow operations to the browser's Web APIs (or Node.js's libuv), letting JavaScript continue running, and then **scheduling a callback** to run later when the result is ready.

**What goes wrong without this model:**

- UI freezes while waiting for I/O
- Long operations block shorter ones
- No way to prioritize urgent tasks (like rendering) over background work

---

## How It Solves It

### 1. Single call stack, non-blocking I/O

JavaScript executes one function at a time. Long operations (timers, network calls) are handed off to external APIs outside the JS engine. The stack stays free.

### 2. Task queue (macrotask queue)

When an async operation completes (timer fires, response arrives), its callback is placed in the task queue. The event loop picks one task per loop iteration when the stack is empty.

### 3. Microtask queue

Promise `.then()` handlers and `queueMicrotask()` go into the microtask queue. Microtasks are **always drained completely** before the next macrotask runs. They have higher priority than macrotasks.

### 4. The loop itself

On every iteration:
1. Run all synchronous code until the stack is empty.
2. Drain the entire microtask queue.
3. Pick one macrotask from the task queue.
4. Drain the microtask queue again.
5. Repeat.

This ordering is deterministic and predictable.

### 5. Rendering (browser only)

The browser may perform a render step between macrotasks. Long-running macrotasks can delay rendering, causing visible jank.

---

## What If We Didn't Have It (Alternatives)

### Blocking synchronous I/O

```js
// hypothetical blocking call
const data = readFileSync('big.json'); // freezes everything
doSomethingElse(); // never runs until above finishes
```

At scale: user can't interact with the page, other tasks pile up, nothing else can run.

### Multi-threaded model

Languages like Java spin up threads for concurrent work. Each thread has its own stack. This solves blocking but introduces race conditions, deadlocks, and complex synchronization.

JavaScript avoids this complexity by staying single-threaded and using the event loop instead. Simpler mental model, no shared memory issues.

### Callback hell (naive async pattern)

```js
getData(function(a) {
  getMore(a, function(b) {
    getEvenMore(b, function(c) {
      // deeply nested, hard to reason about
    });
  });
});
```

This works but is hard to follow. It doesn't change the event loop — it's just a painful way to use it. Promises and async/await are better syntax over the same mechanism.

---

## Examples

### Example 1: Basic execution order

```js
console.log('A');

setTimeout(() => console.log('B'), 0);

console.log('C');
```

Output: `A`, `C`, `B`

Even with a 0ms delay, `setTimeout` is a macrotask. It goes to the task queue and runs after all synchronous code finishes.

---

### Example 2: Microtask vs macrotask priority

```js
console.log('start');

setTimeout(() => console.log('setTimeout'), 0);

Promise.resolve().then(() => console.log('promise'));

console.log('end');
```

Output: `start`, `end`, `promise`, `setTimeout`

The promise `.then()` is a microtask — it runs before the setTimeout macrotask, even though both were scheduled at the same time.

---

### Example 3: Microtask queue drains completely

```js
Promise.resolve()
  .then(() => {
    console.log('micro 1');
    Promise.resolve().then(() => console.log('micro 2'));
  });

setTimeout(() => console.log('macro'), 0);
```

Output: `micro 1`, `micro 2`, `macro`

When a microtask schedules another microtask, that new one also runs before any macrotask. The microtask queue is fully drained before the event loop moves on.

---

### Example 4: Long synchronous task blocks async callbacks

```js
setTimeout(() => console.log('timer'), 0);

// block the stack for 2 seconds
const start = Date.now();
while (Date.now() - start < 2000) {}

console.log('done blocking');
```

Output after 2s: `done blocking`, then `timer`

The setTimeout callback was ready immediately, but couldn't run until the call stack was clear. This demonstrates why long synchronous work hurts responsiveness.

---

### Example 5: Real-world analogy

Think of a restaurant with one waiter (the JS thread):

- The waiter takes your order (synchronous code runs).
- The kitchen prepares food (Web API handles async work — timer, fetch).
- The waiter doesn't stand at the kitchen window. They take other orders.
- When food is ready, it's placed on a counter (the task queue).
- When the waiter is free, they pick up the next dish and deliver it.

Microtasks are urgent notes the waiter reads between every table visit — they always get handled before moving to the next table.

---

### Example 6: async/await is just syntax over the same model

```js
async function run() {
  console.log('before');
  await Promise.resolve();
  console.log('after await'); // this is a microtask
}

run();
console.log('outside');
```

Output: `before`, `outside`, `after await`

`await` pauses the function and schedules the rest as a microtask. Code after `run()` continues synchronously first.

---

## Quickfire (Interview Q&A)

**Q: Is JavaScript multi-threaded?**
No. JavaScript has a single call stack and runs one piece of code at a time. Concurrency is achieved through the event loop, not threads.

**Q: What is the call stack?**
A LIFO (last-in, first-out) data structure that tracks which function is currently executing. When a function is called, it's pushed on; when it returns, it's popped off.

**Q: What is the task queue (macrotask queue)?**
A queue of callbacks from async operations like `setTimeout`, `setInterval`, and I/O events. The event loop picks one macrotask per iteration when the stack is empty.

**Q: What is the microtask queue?**
A higher-priority queue for Promise `.then()` handlers and `queueMicrotask()`. It is fully drained after every task (including synchronous code) before any macrotask runs.

**Q: Which runs first — a resolved Promise or a setTimeout(fn, 0)?**
The resolved Promise. Promise callbacks are microtasks and always run before macrotasks.

**Q: Can a microtask loop infinitely and block macrotasks?**
Yes. If a microtask keeps scheduling new microtasks, macrotasks (and rendering) will never run. The microtask queue must eventually empty.

**Q: What happens if a synchronous function runs for 5 seconds?**
All queued callbacks — timers, promises, I/O — are blocked until the stack is clear. This is called "blocking the event loop."

**Q: What are Web APIs?**
Browser-provided APIs (like `setTimeout`, `fetch`, DOM events) that handle work outside the JS engine. They notify the event loop when work is done by putting callbacks in the task queue.

**Q: What does `await` do under the hood?**
It pauses the async function and schedules the remaining code as a microtask. The call stack is freed immediately, so other synchronous code can continue.

**Q: Why is Node.js good for I/O-heavy work?**
Because I/O is handled by libuv (non-blocking), not the JS thread. The event loop processes results as they arrive, allowing high throughput with a single thread.

**Q: What is a "tick" of the event loop?**
One full iteration: run synchronous code → drain microtasks → run one macrotask → drain microtasks again.

---

## Key Takeaways

- JavaScript is single-threaded; the event loop is how it handles async work without blocking.
- Async operations are handed off to external APIs; their callbacks are queued, not run immediately.
- The call stack must be empty before any queued callback can run.
- Microtasks (Promises) always run before macrotasks (setTimeout, I/O).
- The entire microtask queue is drained before the next macrotask is picked up.
- `async/await` is syntax sugar over Promises — it uses the same microtask queue.
- Long synchronous code blocks everything, including rendering and user input.
- Understanding execution order (sync → microtasks → macrotask) is essential for reasoning about async bugs.

---

## Vocabulary

### Nouns (concepts)

**Call stack** — The data structure tracking active function calls. Only one function runs at a time; it occupies the top of the stack.

**Event loop** — The runtime mechanism that repeatedly checks if the call stack is empty and, if so, moves queued callbacks onto the stack for execution.

**Task queue / Macrotask queue** — Holds callbacks from `setTimeout`, `setInterval`, I/O events. One macrotask is dequeued per event loop iteration.

**Microtask queue** — Holds Promise `.then()` callbacks and `queueMicrotask()` calls. Fully drained before any macrotask runs.

**Macrotask** — A unit of work scheduled via `setTimeout`, `setInterval`, or I/O. Lower priority than microtasks.

**Microtask** — A unit of work scheduled via Promise resolution or `queueMicrotask()`. Higher priority; runs before the next macrotask.

**Web APIs** — Browser-provided interfaces (fetch, setTimeout, DOM events) that run outside the JS engine and push callbacks into the task queue when done.

**libuv** — The C library in Node.js that handles non-blocking I/O and feeds callbacks into the event loop.

**Concurrency** — The ability to handle multiple tasks over time. JavaScript achieves this via the event loop, not parallel threads.

**Single-threaded** — Having one execution context with one call stack. JavaScript's runtime is single-threaded.

### Verbs (actions)

**Enqueue** — To place a callback into a queue (task queue or microtask queue) to be run later.

**Drain** — To run all items in a queue until it is empty. The microtask queue is drained completely before macrotasks run.

**Block** — To occupy the call stack with long-running synchronous code, preventing other callbacks from executing.

**Offload** — To delegate a slow operation (network request, timer) to Web APIs or libuv so the JS thread stays free.

**Schedule** — To register a callback for future execution via the event loop.

### Adjectives (properties)

**Non-blocking** — Describes I/O or operations that return immediately and notify via callback, without stalling the call stack.

**Asynchronous** — Describes operations whose results arrive at an unknown future time, handled via callbacks, promises, or async/await.

**Synchronous** — Executes immediately and blocks the call stack until complete.

**Deterministic** — The event loop's ordering rules (microtasks before macrotasks) produce predictable, consistent execution order.
