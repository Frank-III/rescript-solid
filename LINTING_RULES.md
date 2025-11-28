# ReScript + Solid.js: Linting Rules (AI Agent Instructions)

## Overview

These rules ensure ReScript code works correctly with Solid.js reactivity despite scope hoisting.

---

## 🚨 ERROR Rules (Must Fix)

### E1: No Signal Destructuring
```rescript
// ❌ ERROR
let value = count()
<div>{int(value)}</div>

// ✅ FIX
<div>{int(count())}</div>
```

### E2: No IIFEs in JSX
```rescript
// ❌ ERROR
{(() => {
  let (count, setCount) = createSignal(0)
  <button>{int(count())}</button>
})()}

// ✅ FIX
module LocalCounter = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)
    <button>{int(count())}</button>
  }
}
<LocalCounter />
```

### E3: No createResource Outside Suspense
```rescript
// ❌ ERROR
@jsx.component
let make = () => {
  let (data, _) = createResource(fetchData)
  <Suspense fallback_={string("Loading...")}>
    <div>{string(data())}</div>
  </Suspense>
}

// ✅ FIX
module DataLoader = {
  @jsx.component
  let make = () => {
    let (data, _) = createResource(fetchData)
    <div>{string(data())}</div>
  }
}

@jsx.component
let make = () => {
  <Suspense fallback_={string("Loading...")}>
    <DataLoader />
  </Suspense>
}
```

### E4: No Array Ops at Component Scope
```rescript
// ❌ ERROR
let (items, _) = createSignal([1, 2, 3])
let mapped = items()->Array.map(x => x * 2)

// ✅ FIX
let (items, _) = createSignal([1, 2, 3])
let mapped = createMemo(() => items()->Array.map(x => x * 2))
```

---

## ⚠️ WARNING Rules (Should Fix)

### W1: Inline Pattern Matching
```rescript
// ⚠️ WARNING (works but signal read lifted)
<div>{switch status() {
| #idle => string("Ready")
| #done => string("Done")
}}</div>

// ✅ BETTER
let statusText = () => switch status() {
| #idle => "Ready"
| #done => "Done"
}
<div>{string(statusText())}</div>

// ✅ BEST (if reused)
let statusText = createMemo(() => switch status() {
| #idle => "Ready"
| #done => "Done"
})
<div>{string(statusText())}</div>
```

### W2: Complex Derivations Without Memo
```rescript
// ⚠️ WARNING (re-computes every render)
let filtered = () => items()->Array.filter(x => x.active)->Array.map(x => x.name)

// ✅ BETTER (cached)
let filtered = createMemo(() =>
  items()->Array.filter(x => x.active)->Array.map(x => x.name)
)
```

---

## ℹ️ INFO Rules (Style Preference)

### I1: Prefer Memos for Reused Values
```rescript
// ℹ️ OK but recomputes
let doubled = () => count() * 2
<div>{int(doubled())}</div>
<p>{int(doubled())}</p>  // Computed twice

// ✅ BETTER
let doubled = createMemo(() => count() * 2)
<div>{int(doubled())}</div>
<p>{int(doubled())}</p>  // Computed once, cached
```

### I2: Extract Components for Clarity
```rescript
// ℹ️ OK but hard to read
<div>
  {(() => {
    let x = compute(signal())
    string(x)
  })()}
</div>

// ✅ BETTER
let value = () => {
  let x = compute(signal())
  x
}
<div>{string(value())}</div>

// ✅ BEST (if complex)
module ValueDisplay = {
  @jsx.component
  let make = (~signal) => {
    let value = createMemo(() => compute(signal()))
    <div>{string(value())}</div>
  }
}
<ValueDisplay signal />
```

---

## 🎯 Auto-Fix Patterns

### Pattern 1: Convert Destructuring → Accessor
```rescript
// DETECT: Signal call assigned to variable used in JSX
let value = signal()
<div>{value}</div>

// AUTO-FIX:
<div>{signal()}</div>
```

### Pattern 2: Convert IIFE → Component
```rescript
// DETECT: IIFE in JSX children
{(() => { ... })()}

// AUTO-FIX:
module Generated_Component_N = {
  @jsx.component
  let make = () => { ... }
}
<Generated_Component_N />
```

### Pattern 3: Convert Array Ops → Memo
```rescript
// DETECT: Array operation on signal at component scope
let mapped = signal()->Array.map(fn)

// AUTO-FIX:
let mapped = createMemo(() => signal()->Array.map(fn))
```

### Pattern 4: Extract Inline Switch → Accessor
```rescript
// DETECT: Switch expression in JSX with signal call
<div>{switch signal() { ... }}</div>

// AUTO-FIX:
let value = () => switch signal() { ... }
<div>{value()}</div>
```

---

## 🔍 Detection Patterns (AST Rules)

### Rule: Detect Signal Destructuring
```
IF:
  - Variable assignment: let x = expr
  - expr is function call to signal accessor
  - Variable x used in JSX without calling it
THEN:
  - ERROR E1
```

### Rule: Detect IIFE in JSX
```
IF:
  - JSX children contains expression
  - Expression is IIFE: (() => { ... })()
THEN:
  - ERROR E2
```

### Rule: Detect Resource Outside Suspense
```
IF:
  - Component calls createResource
  - Component renders Suspense component
  - createResource call is before Suspense in same scope
THEN:
  - ERROR E3
```

### Rule: Detect Array Ops at Component Scope
```
IF:
  - Variable assignment at component top level
  - RHS contains Array.map/filter/reduce/sort
  - Array comes from signal call
  - Not wrapped in createMemo
THEN:
  - ERROR E4
```

### Rule: Detect Inline Pattern Match
```
IF:
  - JSX children contains switch expression
  - Switch scrutinee contains signal call
THEN:
  - WARNING W1
```

### Rule: Detect Expensive Derivation Without Memo
```
IF:
  - Arrow function accessor: () => ...
  - Body contains multiple Array operations
  - Used more than once in JSX
THEN:
  - WARNING W2
```

---

## 📋 AI Agent Prompt Template

Use this as a system prompt for AI agents writing ReScript + Solid.js:

```
You are writing ReScript code using Solid.js. Follow these STRICT rules:

FORBIDDEN PATTERNS:
1. Never destructure signals: let x = signal() ❌
   Always call in JSX: {signal()} ✅

2. Never use IIFEs in JSX: {(() => {...})()} ❌
   Always create separate components ✅

3. Never createResource outside Suspense boundary ❌
   Always in separate component inside Suspense ✅

4. Never do Array ops at component scope ❌
   Always wrap in createMemo ✅

REQUIRED PATTERNS:
1. Simple derivations: let x = () => signal() * 2
2. Complex derivations: let x = createMemo(() => ...)
3. Pattern matching: Extract to accessor or memo
4. Local scopes: Create separate component modules
5. Suspense: Resource in separate component

When you see these patterns, automatically fix:
- Signal destructuring → Direct call
- IIFE → Component module
- Inline switch → Extracted accessor
- Array ops → Wrapped in memo
```

---

## 🚀 Quick Reference Card

| Pattern | ❌ Wrong | ✅ Right |
|---------|----------|----------|
| Signal access | `let x = s()` | `{s()}` or `let x = () => s()` |
| Derivation | `let x = s() * 2` | `let x = () => s() * 2` |
| Array map | `let m = arr()->map(f)` | `let m = memo(() => arr()->map(f))` |
| Pattern match | `<div>{switch s() {...}}</div>` | `let v = () => switch s() {...}` |
| Local scope | `{(() => {let x; <div/>})()}` | `module M = {@jsx.component ...}` |
| Suspense | `let (d,_)=r(); <Suspense>` | `module D={let (d,_)=r()}; <Suspense><D/>` |

---

## 🎯 Summary

**3 Core Principles:**

1. **Signals are functions** - Always call them where you need the value
2. **Derivations are accessors** - Wrap in `() =>` or `createMemo(() =>)`
3. **Scopes are components** - Use modules, not IIFEs

Follow these and you get:
- ✅ Full type safety
- ✅ Reactive updates
- ✅ Proper Suspense boundaries
- ✅ Correct lifecycle behavior
- ✅ Clean, maintainable code

**You lose nothing.** You gain discipline.
