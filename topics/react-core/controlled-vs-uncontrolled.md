Saved to `topics/controlled-vs-uncontrolled-components.md`.

The document covers:

- **What it is**: who owns the data — your state or the DOM
- **The problem**: HTML inputs are natively stateful, creating two potential sources of truth
- **How it's solved**: controlled components make state the single source of truth; uncontrolled components use refs to read on demand
- **6 examples** ranging from minimal read-only refs to API pre-filling and the common `value`-without-`onChange` bug
- **10 interview Q&As** covering definitions, trade-offs, and common gotchas
- **Full vocabulary** grouped by nouns, verbs, and adjectives
