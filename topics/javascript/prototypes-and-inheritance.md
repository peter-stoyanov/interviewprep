# Prototypes and Inheritance

**Abstraction level**: language feature
**Category**: object-oriented programming / JavaScript runtime model

---

## Related Topics

- **Depends on this**: classes in JavaScript (syntactic sugar over prototypes), `this` binding
- **Contrast with**: classical inheritance (as in Java/C++), composition over inheritance
- **Works alongside**: closures and scope, object creation patterns (factory functions, constructors)
- **Temporal neighbors**: learn objects and `this` before this; learn ES6 classes and design patterns after

---

## What Is It

Prototypal inheritance is the mechanism JavaScript uses to share properties and behavior between objects. Every object has an internal link to another object called its **prototype**. When you access a property on an object and it is not found there, JavaScript automatically looks up the prototype chain until it finds it or reaches `null`.

- **Data**: objects with properties and methods
- **Where it lives**: in memory — each object has a hidden `[[Prototype]]` slot pointing to another object
- **Who reads/writes it**: the JavaScript runtime reads it on every property lookup; you write it when constructing objects
- **How it changes**: the chain is set at object creation and rarely changed at runtime

---

## What Problem Does It Solve

Without a sharing mechanism, every object would have to carry its own copy of every method it uses.

**Simple scenario**: You have 1000 user objects. Each needs a `greet()` method.

Without inheritance:
```js
const user1 = { name: "Alice", greet: function() { return "Hi, " + this.name; } };
const user2 = { name: "Bob",   greet: function() { return "Hi, " + this.name; } };
// 1000 objects × 1 function copy = 1000 function copies in memory
```

Problems:
- **Duplication**: identical logic stored in memory N times
- **Inconsistency**: if you want to update `greet`, you must update every object
- **No shared behavior**: objects have no structural relationship; you cannot treat them polymorphically

Prototypes solve this by letting all user objects share one `greet` function defined in a single place.

---

## How Does It Solve It

### 1. The Prototype Chain

Every object has a `[[Prototype]]` link. Property lookup walks up this chain.

```
myObj → prototypeObj → Object.prototype → null
```

When you access `myObj.greet`, JavaScript checks:
1. Does `myObj` have `greet`? No.
2. Does `myObj.__proto__` have `greet`? Yes — use it.

**Data flow**: property access triggers a traversal upward through linked objects.

### 2. One Definition, Many Owners

Methods live on the prototype. All instances share the same function object. Only data (state) lives on each instance.

```js
function User(name) {
  this.name = name; // own property — lives on the instance
}
User.prototype.greet = function() {
  return "Hi, " + this.name; // shared — lives on the prototype
};

const u1 = new User("Alice");
const u2 = new User("Bob");
u1.greet === u2.greet; // true — same function reference
```

### 3. Delegation, Not Copying

JavaScript does not copy methods from parent to child. It delegates: "I don't have this, ask the next object in the chain." This means updates to the prototype are immediately visible to all instances.

### 4. The `new` Keyword Wires the Chain

When you call `new Fn()`, JavaScript:
1. Creates a new empty object
2. Sets its `[[Prototype]]` to `Fn.prototype`
3. Calls `Fn` with `this` pointing to the new object
4. Returns the object

```js
// What `new User("Alice")` does internally:
const obj = Object.create(User.prototype); // step 1 + 2
User.call(obj, "Alice");                   // step 3
// returns obj                             // step 4
```

### 5. Extending the Chain (Prototype Chaining)

You can create a chain of prototypes to model inheritance hierarchies.

```js
function Animal(name) { this.name = name; }
Animal.prototype.speak = function() { return this.name + " makes a sound."; };

function Dog(name) { Animal.call(this, name); }
Dog.prototype = Object.create(Animal.prototype);
Dog.prototype.constructor = Dog;

Dog.prototype.bark = function() { return this.name + " barks."; };

const d = new Dog("Rex");
d.speak(); // found on Animal.prototype via chain
d.bark();  // found on Dog.prototype
```

**Chain**: `d → Dog.prototype → Animal.prototype → Object.prototype → null`

---

## What If We Didn't Have It

### Naive: copy methods into every object

```js
function makeUser(name) {
  return {
    name,
    greet() { return "Hi " + name; },
    logout() { /* ... */ }
  };
}
```

Works for small cases. Breaks because:
- Every call to `makeUser` allocates new function objects
- No shared identity — `instanceof` does not work
- Cannot extend or specialize behavior without duplicating code

### Naive: manual delegation

```js
const base = { greet() { return "Hi"; } };
const user = { name: "Alice" };
user.greet = base.greet; // manual copy
```

Still copies. Any update to `base.greet` does not propagate. Hidden coupling.

### Over-reliance on deep prototype chains

Chains longer than 2–3 levels become hard to trace. Property lookup is a live traversal; deeply nested chains slow lookups and obscure where behavior comes from.

---

## Examples

### Example 1 — Property lookup traversal

```js
const proto = { type: "animal" };
const obj = Object.create(proto);
obj.name = "Rex";

obj.name;  // "Rex"    — found on obj
obj.type;  // "animal" — not on obj, found on proto
obj.age;   // undefined — not found anywhere in chain
```

### Example 2 — Shared method, own data

```js
function Counter(start) {
  this.count = start; // own property
}
Counter.prototype.increment = function() { this.count++; };

const c1 = new Counter(0);
const c2 = new Counter(10);
c1.increment();
c1.count; // 1
c2.count; // 10 — not affected
c1.increment === c2.increment; // true — shared
```

### Example 3 — Shadowing a prototype property

```js
function Vehicle() {}
Vehicle.prototype.fuel = "gasoline";

const car = new Vehicle();
car.fuel;       // "gasoline" — from prototype

car.fuel = "electric"; // own property created on car
car.fuel;       // "electric" — shadowed
delete car.fuel;
car.fuel;       // "gasoline" — prototype visible again
```

### Example 4 — `Object.create` for explicit prototype wiring

```js
const animal = {
  speak() { return this.name + " speaks."; }
};

const dog = Object.create(animal);
dog.name = "Rex";
dog.speak(); // "Rex speaks." — delegated to animal
```

No constructor functions needed. `Object.create` makes the relationship explicit.

### Example 5 — ES6 class is syntactic sugar

```js
class Animal {
  constructor(name) { this.name = name; }
  speak() { return this.name + " speaks."; }
}

class Dog extends Animal {
  bark() { return this.name + " barks."; }
}

const d = new Dog("Rex");
```

Under the hood: `Dog.prototype` is set up to delegate to `Animal.prototype`. The prototype chain is identical to the manual approach. `class` does not introduce a new runtime model.

### Example 6 — Incorrect inheritance (forgetting `Object.create`)

```js
// Wrong — both share the same prototype object
Dog.prototype = Animal.prototype;
Dog.prototype.bark = function() { /* ... */ };
// Now Animal.prototype also has bark!

// Correct
Dog.prototype = Object.create(Animal.prototype);
Dog.prototype.constructor = Dog;
```

---

## Quickfire (Interview Q&A)

**Q: What is a prototype in JavaScript?**
An object that another object delegates to for property lookup when the property is not found on the object itself.

**Q: What is `[[Prototype]]` vs `prototype`?**
`[[Prototype]]` is the internal link on every object pointing to its parent. `prototype` is a property on constructor functions that becomes the `[[Prototype]]` of instances created with `new`.

**Q: How does `Object.create(proto)` work?**
It creates a new object whose `[[Prototype]]` is set to `proto`, with no own properties.

**Q: What does the `new` keyword do?**
Creates an empty object, sets its `[[Prototype]]` to `Fn.prototype`, calls `Fn` with `this` as that object, and returns it.

**Q: Is ES6 `class` different from prototype-based inheritance?**
No. `class` is syntactic sugar. The runtime still uses prototype chains; `class` just makes the syntax cleaner.

**Q: What is prototype chain traversal?**
When accessing a property, JavaScript walks up the `[[Prototype]]` links one by one until it finds the property or reaches `null`.

**Q: What is shadowing?**
When an object defines a property with the same name as one on its prototype, hiding the prototype's version.

**Q: Why should methods go on the prototype rather than in the constructor?**
Methods on the prototype are shared across all instances (one copy). Methods defined inside the constructor are re-created per instance (N copies), wasting memory.

**Q: What does `hasOwnProperty` do?**
Returns `true` only if the property exists directly on the object, not inherited from the prototype chain.

**Q: When does prototype chain traversal return `undefined`?**
When the property is not found on any object in the chain and the top (`Object.prototype`) is reached.

**Q: What is the difference between inheritance via prototypes and composition?**
Prototype inheritance links objects through a chain (is-a relationship). Composition assembles behavior by mixing independent objects or functions (has-a relationship).

---

## Key Takeaways

- Every JavaScript object has an internal `[[Prototype]]` link to another object or `null`.
- Property lookup walks up the chain — this is delegation, not copying.
- Methods belong on the prototype; data (state) belongs on the instance.
- `new Fn()` wires the created object's prototype to `Fn.prototype`.
- `Object.create(proto)` is the explicit, low-level way to set up the chain.
- ES6 `class` and `extends` are syntax sugar over the same prototype mechanism.
- Shadowing lets an instance override a prototype property without mutating it.
- Deep prototype chains are hard to reason about — keep hierarchies shallow.

---

## Vocabulary

### Nouns (concepts)

**Prototype**: An object that serves as the fallback source of properties for another object. Every object has one (or `null` at the top of the chain).

**Prototype chain**: The linked sequence of objects traversed during property lookup, from the instance up to `Object.prototype` and then `null`.

**`[[Prototype]]`**: The internal (hidden) slot on every object that holds a reference to its prototype. Accessible in code via `Object.getPrototypeOf(obj)` or the legacy `__proto__`.

**`prototype` property**: A property on constructor functions (and classes). When you call `new Fn()`, the resulting object's `[[Prototype]]` is set to `Fn.prototype`.

**Constructor function**: A regular function intended to be called with `new` to produce objects with a shared prototype.

**Own property**: A property that exists directly on an object, not inherited via the chain. `hasOwnProperty` checks for these.

**Shadowing**: When an object defines a property with the same name as one on its prototype, hiding the prototype's version for that object.

**Delegation**: The runtime behavior of forwarding a missing property lookup to the prototype rather than failing immediately.

**`Object.create(proto)`**: A built-in method that creates a new object with `[[Prototype]]` explicitly set to `proto`.

### Verbs (actions)

**Inherit**: Gain access to properties or methods by being linked to a prototype that defines them.

**Delegate**: Forward a property lookup to the prototype rather than handling it locally.

**Shadow**: Override a prototype property by defining an own property with the same name on the instance.

**Traverse**: Walk up the prototype chain during property lookup.

**Instantiate**: Create a new object from a constructor function or class via `new`.

### Adjectives (properties)

**Own**: Describes a property that belongs directly to an object, not inherited.

**Enumerable**: A property descriptor flag. Inherited properties that are enumerable appear in `for...in` loops.

**Shared**: A method or value that lives on the prototype and is accessible to all linked instances without duplication.

**Mutable**: The prototype chain can be changed at runtime via `Object.setPrototypeOf`, though this is rare and has performance costs.
