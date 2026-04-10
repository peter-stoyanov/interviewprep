#!/usr/bin/env bash

set -euo pipefail

# Root output folder
ROOT_DIR="topics"

# Generic prompt file
PROMPT_FILE="./prompts/topic.md"

# Claude Code binary
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

# Optional model override:
# export CLAUDE_MODEL="sonnet"
CLAUDE_MODEL="${CLAUDE_MODEL:-}"

# Extra safety/behavior knobs
MAX_TURNS="${MAX_TURNS:-10}"

if [[ ! -f "$PROMPT_FILE" ]]; then
	echo "Error: $PROMPT_FILE not found in current directory."
	exit 1
fi

mkdir -p "$ROOT_DIR"

run_topic() {
	local folder="$1"
	local slug="$2"
	local title="$3"

	local dir_path="${ROOT_DIR}/${folder}"
	local out_file="${dir_path}/${slug}.md"

	mkdir -p "$dir_path"

	echo "Generating: ${title}"
	echo " -> ${out_file}"

	local full_prompt
	full_prompt="$(cat "$PROMPT_FILE")

Topic: ${title}

Generate the final markdown document for this topic.
Return only the final markdown document.
"

	if [[ -n "$CLAUDE_MODEL" ]]; then
		"$CLAUDE_BIN" -p \
			--dangerously-skip-permissions \
			--output-format text \
			--max-turns "$MAX_TURNS" \
			--model "$CLAUDE_MODEL" \
			"$full_prompt" > "$out_file"
	else
		"$CLAUDE_BIN" -p \
			--dangerously-skip-permissions \
			--output-format text \
			--max-turns "$MAX_TURNS" \
			"$full_prompt" > "$out_file"
	fi
}

# Format:
# run_topic "folder" "file-name" "Human Topic Title"

run_topic "javascript" "es6-and-core-javascript" "ES6+ and core JavaScript fundamentals"
run_topic "javascript" "closures-and-scope" "Closures and scope"
run_topic "javascript" "prototypes-and-inheritance" "Prototypes and inheritance"
run_topic "javascript" "event-loop" "JavaScript event loop"
run_topic "javascript" "async-javascript" "Asynchronous JavaScript: Promises and async/await"
run_topic "javascript" "immutability-vs-mutation" "Immutability vs mutation"
run_topic "javascript" "functional-programming-basics" "Functional programming basics in JavaScript"

run_topic "typescript" "typescript-basics" "TypeScript fundamentals"
run_topic "typescript" "types-vs-interfaces" "Types vs interfaces"
run_topic "typescript" "generics" "Generics in TypeScript"
run_topic "typescript" "type-inference-and-narrowing" "Type inference and type narrowing"
run_topic "typescript" "utility-types" "TypeScript utility types"
run_topic "typescript" "strict-typing-in-react" "Strict typing in React"
run_topic "typescript" "any-vs-unknown" "any vs unknown"

run_topic "react-core" "functional-components-and-jsx" "React functional components and JSX"
run_topic "react-core" "props-vs-state" "Props vs state"
run_topic "react-core" "usestate" "React useState"
run_topic "react-core" "useeffect" "React useEffect"
run_topic "react-core" "usememo-and-usecallback" "React useMemo and useCallback"
run_topic "react-core" "react-rerendering" "React re-rendering behavior"
run_topic "react-core" "controlled-vs-uncontrolled" "Controlled vs uncontrolled components"

run_topic "react-patterns" "component-composition" "Component composition"
run_topic "react-patterns" "separation-of-concerns" "Separation of concerns in frontend"
run_topic "react-patterns" "container-vs-presentational" "Container vs presentational components"
run_topic "react-patterns" "custom-hooks" "Custom hooks"
run_topic "react-patterns" "reusable-components" "Reusable component design"
run_topic "react-patterns" "frontend-folder-structure" "Frontend folder structure and scalability"

run_topic "state-management" "state-management-browser" "State management in the browser"
run_topic "state-management" "local-vs-global-state" "Local vs global state"
run_topic "state-management" "redux-fundamentals" "Redux fundamentals"
run_topic "state-management" "redux-toolkit" "Redux Toolkit"
run_topic "state-management" "context-api-vs-redux" "Context API vs Redux"
run_topic "state-management" "derived-state" "Derived state"
run_topic "state-management" "avoiding-unnecessary-rerenders" "Avoiding unnecessary re-renders"

run_topic "api-fetching" "http-basics" "HTTP basics for frontend developers"
run_topic "api-fetching" "fetch-and-axios" "Fetch API and Axios"
run_topic "api-fetching" "request-lifecycle" "Request lifecycle: loading, success, error"
run_topic "api-fetching" "error-handling" "Frontend API error handling"
run_topic "api-fetching" "caching-basics" "Caching basics in frontend applications"
run_topic "api-fetching" "race-conditions" "Race conditions in frontend data fetching"

run_topic "async-ui" "partial-page-updates" "Partial page updates"
run_topic "async-ui" "loading-states" "Loading states"
run_topic "async-ui" "optimistic-updates" "Optimistic updates"
run_topic "async-ui" "debouncing-and-throttling" "Debouncing and throttling"
run_topic "async-ui" "concurrent-requests" "Handling concurrent requests in the UI"

run_topic "css-layout" "semantic-html" "Semantic HTML"
run_topic "css-layout" "css-box-model" "CSS box model"
run_topic "css-layout" "flexbox" "Flexbox"
run_topic "css-layout" "css-specificity" "CSS specificity"
run_topic "css-layout" "layout-systems" "CSS layout systems"

run_topic "responsive-design" "responsive-design-basics" "Responsive design basics"
run_topic "responsive-design" "mobile-vs-desktop" "Mobile vs desktop UI differences"
run_topic "responsive-design" "breakpoints" "Responsive breakpoints"
run_topic "responsive-design" "design-to-code" "Translating design prototypes into code"
run_topic "responsive-design" "accessibility-basics" "Accessibility basics for frontend developers"

run_topic "code-quality" "clean-code" "Clean code in frontend development"
run_topic "code-quality" "dry-and-kiss" "DRY and KISS principles"
run_topic "code-quality" "naming-conventions" "Naming conventions"
run_topic "code-quality" "refactoring-strategies" "Refactoring strategies"
run_topic "code-quality" "technical-debt" "Technical debt"

run_topic "oop" "object-oriented-design-principles" "Object-oriented design principles"
run_topic "oop" "solid-principles" "SOLID principles"
run_topic "oop" "encapsulation-and-abstraction" "Encapsulation and abstraction"
run_topic "oop" "composition-vs-inheritance" "Composition vs inheritance"
run_topic "oop" "oop-in-frontend" "When object-oriented design makes sense in frontend"

run_topic "algorithms" "arrays-objects-maps" "Arrays, objects, and maps"
run_topic "algorithms" "big-o-basics" "Big O basics"
run_topic "algorithms" "filter-map-search-patterns" "Common collection patterns: filtering, mapping, searching"
run_topic "algorithms" "problem-solving-under-constraints" "Problem solving under constraints"

run_topic "browser" "dom-basics" "DOM basics"
run_topic "browser" "browser-events" "Browser events: bubbling and capturing"
run_topic "browser" "rendering-pipeline" "Browser rendering pipeline"
run_topic "browser" "memory-and-performance-basics" "Browser memory and performance basics"

run_topic "performance" "react-performance-basics" "React performance basics"
run_topic "performance" "memoization" "Memoization in frontend"
run_topic "performance" "list-keys" "React key prop in lists"
run_topic "performance" "virtual-dom" "Virtual DOM"

run_topic "workflow" "technical-documentation" "Writing technical documentation"
run_topic "workflow" "explaining-technical-decisions" "Explaining technical decisions"
run_topic "workflow" "participating-in-team-discussions" "Participating in technical discussions"
run_topic "workflow" "understanding-requirements" "Understanding product and technical requirements"

run_topic "testing" "frontend-testing-basics" "Frontend testing basics"
run_topic "testing" "react-testing-library" "React Testing Library basics"

run_topic "tooling" "npm-and-package-management" "npm and package management"
run_topic "tooling" "build-tools" "Frontend build tools: Vite and Webpack basics"
run_topic "tooling" "eslint-and-prettier" "ESLint and Prettier"

run_topic "git" "git-basics" "Git basics"
run_topic "git" "branching-and-prs" "Branching and pull requests"

echo
echo "Done. Generated materials under: ${ROOT_DIR}"