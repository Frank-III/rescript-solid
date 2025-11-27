# Generated JavaScript Code Analysis

## Overview

ReScript 12 with **JSX preserve mode** generates clean, modern JavaScript with preserved JSX syntax. This allows downstream tools (Vite, SWC, ESBuild) to handle JSX transformation and enables React Compiler compatibility.

## Key Observations

### 1. **JSX Preserve Mode** ✨

The JSX is **NOT** transformed to `jsx()` calls - it remains as JSX syntax:

```javascript
// ✅ Generated with preserve mode
return <div>
  <h3>{"✅ Correct Signal Access"}</h3>
  <p>{"Count: "}{match[0]()}</p>
  <button onClick={param => setCount(prev => prev + 1 | 0)}>
    {"Increment"}
  </button>
</div>;
```

**Benefits**:
- Downstream bundler can apply optimizations
- Compatible with React Compiler
- More readable output
- Solid's compiler can optimize JSX

### 2. **Clean Modern JavaScript** 🎯

ReScript 12 generates compact, arrow-function-based code:

```javascript
// Counter component - very clean!
function Counter(props) {
  let __initialCount = props.initialCount;
  let initialCount = __initialCount !== undefined ? __initialCount : 0;
  let match = SolidJs.createSignal(initialCount);
  let setCount = match[1];
  let count = match[0];
  let increment = param => setCount(prev => prev + 1 | 0);
  let decrement = param => setCount(prev => prev - 1 | 0);
  let reset = param => setCount(param => initialCount);
  let doubleCount = SolidJs.createMemo(() => (count() << 1));
  return <div>
    <h2>{"Counter Component"}</h2>
    <p>{"Count: "}<strong>{count()}</strong></p>
    <p>{"Double: "}<strong>{doubleCount()}</strong></p>
    <div>
      <button onClick={decrement}>{"Decrement"}</button>
      <button onClick={reset}>{"Reset"}</button>
      <button onClick={increment}>{"Increment"}</button>
    </div>
  </div>;
}
```

**File size**: Only **57 lines** for a complete reactive counter component!

### 3. **Signal Destructuring Pattern** 📦

ReScript destructures signal tuples cleanly:

```javascript
let match = SolidJs.createSignal(0);
let setCount = match[1];  // setter
let count = match[0];     // accessor
```

This is equivalent to JavaScript's:
```javascript
const [count, setCount] = createSignal(0);
```

### 4. **Unified Operators** ➕

ReScript 12's unified operators compile to correct JavaScript:

```javascript
// Integer arithmetic
prev + 1 | 0        // Addition with int coercion
count() << 1        // Bit shift for multiplication by 2
count() << 2        // Bit shift for multiplication by 4

// String concatenation
"Count changed to: " + count().toString()
```

**Note**: The `| 0` is a fast integer coercion (same as `Math.trunc()`).

### 5. **Anti-Pattern Detection in Output** 🔍

You can **see** the anti-patterns in the generated code!

#### ❌ **Stale Value Example**

```javascript
// ReactivityAntiPatterns$DestructuringSignals
function ReactivityAntiPatterns$DestructuringSignals(props) {
  let match = SolidJs.createSignal(0);
  let count = match[0];
  let currentCount = count();  // ⚠️ Called ONCE at component creation!

  return <div>
    <p>{"Count (stale): "}{currentCount}</p>     // Never updates
    <p>{"Count (correct): "}{count()}</p>        // Updates reactively
  </div>;
}
```

**Why it breaks**: `currentCount` is a **number** (10), not a function. The value is frozen at component creation.

#### ❌ **Deriving Without Memo**

```javascript
function ReactivityAntiPatterns$DerivingWithoutMemo(props) {
  let match = SolidJs.createSignal(0);
  let count = match[0];
  let doubled = (count() << 1);  // ⚠️ Computed ONCE!
  let quadrupled = SolidJs.createMemo(() => (count() << 2));  // ✅ Reactive

  return <div>
    <p>{"Doubled (broken): "}{doubled}</p>        // Never updates
    <p>{"Quadrupled (correct): "}{quadrupled()}</p>  // Updates reactively
  </div>;
}
```

**Why it breaks**: `doubled` is computed at component creation and stored as a number.

#### ❌ **Passing Values vs Accessors**

```javascript
// Wrong child - receives primitive
function ReactivityAntiPatterns$PassingValues$Child(props) {
  return <div>
    <p>{"Child count (stale): "}{props.count}</p>  // ⚠️ Never updates
  </div>;
}

// Correct child - receives accessor
function ReactivityAntiPatterns$PassingValues$CorrectChild(props) {
  return <div>
    <p>{"Child count (reactive): "}{props.count()}</p>  // ✅ Calls function
  </div>;
}

// Parent component
function ReactivityAntiPatterns$PassingValues(props) {
  let count = match[0];
  return <div>
    <Child.make count={count()} />        // ⚠️ Passes number: 0
    <CorrectChild.make count={count} />   // ✅ Passes function
  </div>;
}
```

**Clear difference**:
- `count()` → Evaluates to `0` (number)
- `count` → Passes the function itself

### 6. **Array Operations** 🔄

Immutable array updates compile to standard JavaScript:

```javascript
setTodos(prevTodos => prevTodos.map(todo => {
  if (todo.id === id) {
    return {
      id: todo.id,
      text: todo.text,
      completed: !todo.completed
    };
  } else {
    return todo;
  }
}));
```

**ReScript advantages**:
- Record spread `{...todo, completed: !todo.completed}` → Object literal
- Type-safe field access
- No accidental mutations

### 7. **Module Organization** 📂

ReScript creates nested module objects:

```javascript
let Child = {
  make: ReactivityPatterns$CorrectPropsUsage$Child
};

let CorrectPropsUsage = {
  Child: Child,
  make: ReactivityPatterns$CorrectPropsUsage
};
```

Used as:
```javascript
<Child.make count={count} onIncrement={...} />
```

### 8. **Runtime Dependencies** 📦

Minimal runtime imports:

```javascript
import * as SolidJs from "solid-js";
import * as H from "solid-js/h";  // For JSX (imported but not used with preserve)
import * as Stdlib_Option from "@rescript/runtime/lib/es6/Stdlib_Option.js";
```

**Note**: `@rescript/runtime` is automatically installed with ReScript 12.

### 9. **Optional Props Handling** 🎁

ReScript generates safe optional prop handling:

```javascript
function Counter(props) {
  let __initialCount = props.initialCount;
  let initialCount = __initialCount !== undefined ? __initialCount : 0;
  // ...
}
```

This handles:
- Missing props → Default value
- `undefined` → Default value
- Actual value → Use it

### 10. **Effect Cleanup** 🧹

Effects with cleanup compile correctly:

```javascript
function ReactivityPatterns$CorrectCleanup(props) {
  let match = SolidJs.createSignal(0);
  let setCount = match[1];

  SolidJs.createEffect(() => {
    let interval = setInterval(() => {
      setCount(prev => prev + 1 | 0);
    }, 1000);

    SolidJs.onCleanup(() => {
      clearInterval(interval);
    });
  });

  return <div>
    <p>{"Auto-incrementing count: "}{match[0]()}</p>
  </div>;
}
```

### 11. **Component Exports** 📤

Standard ES module exports:

```javascript
let make = Counter;

export {
  make,
}
/* solid-js Not a pure module */
```

Can be imported as:
```javascript
import { make as Counter } from './Counter.mjs';
```

## File Size Comparison

| Component | Lines (ReScript) | Lines (Generated JS) | Ratio |
|-----------|------------------|---------------------|-------|
| Counter | 30 | 57 | 1.9x |
| ReactivityPatterns | ~230 | 318 | 1.4x |
| ReactivityAntiPatterns | ~270 | 386 | 1.4x |

**Conclusion**: Generated code is very compact, only ~1.5x the source size!

## Performance Optimizations Visible in Output

### 1. **Bit Shift for Multiplication**
```javascript
count() << 1  // Same as count() * 2, but faster
```

### 2. **Integer Coercion**
```javascript
prev + 1 | 0  // Ensures integer result, avoids float ops
```

### 3. **Direct Signal Calls**
```javascript
{count()}  // Direct function call, no wrapper
```

### 4. **Minimal Function Wrapping**
```javascript
// ReScript optimizes simple expressions
onClick={decrement}  // Direct reference, no wrapper

// But wraps when needed
onClick={param => setCount(prev => prev + 1 | 0)}
```

## Interesting Patterns

### 1. **Closure Capture (Anti-pattern)**

```javascript
let handleClick = param => {
  let current = count();  // ⚠️ Captures value once
  console.log("Clicked at count: " + current.toString());
  setCount(param => current + 1 | 0);  // Always uses initial value
};
```

**The bug**: Each click reads `count()` fresh, but then uses that snapshot in the setter, not the latest value.

### 2. **Correct Closure**

```javascript
let handleClickCorrect = param => {
  let current = count();  // ✅ Reads current value each time
  console.log("Clicked at count (correct): " + current.toString());
  setCount(prev => prev + 1 | 0);  // Uses prev from setter
};
```

## What JSX Preserve Mode Enables

### Before (without preserve):
```javascript
// Would transform to:
H.jsx("div", {
  children: [
    H.jsx("h3", { children: "✅ Correct Signal Access" }),
    // ...
  ]
});
```

### After (with preserve):
```javascript
// Keeps JSX intact:
<div>
  <h3>{"✅ Correct Signal Access"}</h3>
  {/* ... */}
</div>
```

**Advantages**:
- ✅ Vite/SWC can optimize JSX
- ✅ React Compiler compatible
- ✅ Solid's own JSX optimizations apply
- ✅ Better source maps
- ✅ More readable debugging

## Potential Issues in Generated Code

### 1. **Null Handling**
The warning about `null` shadowing is visible:
```javascript
// In Solid.res.mjs
function jsxFragment(props) {
  return Stdlib_Option.getOr(props.children, null);  // Uses JS null
}
```

This is fine - just a naming collision warning.

### 2. **Array Identity**
Array operations create new arrays (correct for reactivity):
```javascript
setTodos(prevTodos => prevTodos.map(todo => {
  // Returns NEW array with potentially new objects
}));
```

### 3. **Function Identity**
Event handlers may create new functions on each call:
```javascript
onClick={param => setCount(prev => prev + 1 | 0)}
// New arrow function each time (usually fine for Solid)
```

## Conclusion

The generated JavaScript is:
- ✅ **Clean and readable** - Easy to debug
- ✅ **Modern ES6+** - Arrow functions, const/let, modules
- ✅ **Optimized** - Bit shifts, minimal wrapping
- ✅ **JSX preserved** - Enables downstream optimizations
- ✅ **Type-safe origin** - No runtime type errors from ReScript bugs
- ✅ **Compact** - Only ~1.5x source size
- ✅ **Standards-compliant** - Works with all bundlers

The anti-patterns are **clearly visible** in the output:
- Stale values are stored as primitives
- Missing memos are simple variables
- Wrong prop passing is obvious (value vs function)

This makes debugging easier - you can see **exactly** what went wrong!

---

**Generated**: 2025-11-27
**ReScript**: 12.0.0
**JSX Mode**: v4 preserve
**Output**: ES Modules (.mjs)
