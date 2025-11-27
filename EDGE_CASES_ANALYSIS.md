# ReScript + Solid.js: Edge Cases & What Actually Breaks

## Critical Finding: Scope Hoisting Breaks Reactivity

ReScript's compiler **lifts expressions to component scope**, which breaks Solid's reactivity tracking. This happens even with JSX preserve mode and vite-plugin-solid.

## What We Tested

Created 12 comprehensive edge case tests comparing:
- **Computed once** (at component creation) ❌
- **Inline in JSX** (reactive) ✅

## Detailed Analysis of Generated Code

### ❌ **EDGE CASE 1: IIFE Gets Lifted**

**ReScript Code:**
```rescript
let attemptIIFE = {
  (() => count() * 2)()
}
```

**Generated JavaScript:**
```javascript
function Component(props) {
  let count = match[0];
  let attemptIIFE = (count() << 1);  // ❌ LIFTED! Computed once

  return <div>
    <p>{"Attempt IIFE: "}{attemptIIFE}</p>  // Never updates
    <p>{"Direct call: "}{(count() << 1)}</p>  // ✅ Reactive!
  </div>;
}
```

**Why it breaks:** ReScript evaluates the IIFE at component creation, not during render.

---

### ❌ **EDGE CASE 2: Block Expressions Lifted**

**ReScript Code:**
```rescript
let complexCalc = {
  let doubled = count() * 2
  let tripled = count() * 3
  doubled + tripled
}
```

**Generated JavaScript:**
```javascript
let doubled = (count() << 1);      // ❌ Computed once
let tripled = count() * 3 | 0;     // ❌ Computed once
let complexCalc = doubled + tripled | 0;  // ❌ Frozen value

return <div>
  <p>{"Complex calc: "}{complexCalc}</p>  // Never updates
  <p>{"Count: "}{count()}</p>  // ✅ Updates
</div>;
```

**Why it breaks:** Entire block computed at component creation, values frozen.

---

### ❌ **EDGE CASE 3: Ternary Expressions Captured**

**ReScript Code:**
```rescript
let result = count() > 5 ? count() * 2 : count() + 1
```

**Generated JavaScript:**
```javascript
let result = count() > 5 ? (count() << 1) : count() + 1 | 0;  // ❌ Computed once

return <div>
  <p>{"Result (computed once): "}{result}</p>  // Never updates
  <p>{"Result (inline): "}{count() > 5 ? (count() << 1) : count() + 1 | 0}</p>  // ✅ Reactive
</div>;
```

**Why it breaks:** Even though the ternary reads `count()` multiple times, the entire expression is evaluated once.

---

### ❌ **EDGE CASE 4: Pattern Matching Reads Early**

**ReScript Code:**
```rescript
let message = switch count() {
| n if n > 10 => "High"
| n if n > 5 => "Medium"
| _ => "Low"
}
```

**Generated JavaScript:**
```javascript
let n = count();  // ❌ Read once at component creation
let message = n > 10 ? "High" : (n > 5 ? "Medium" : "Low");

return <div>
  <p>{"Message (computed once): "}{message}</p>  // Never updates
  <p>
    {"Message (inline): "}
    {n$1 > 10 ? "High" : (n$1 > 5 ? "Medium" : "Low")}  // ✅ Works if n$1 = count()
  </p>
</div>;
```

**Why it breaks:** Signal read happens at component creation for the variable binding.

---

### ❌ **EDGE CASE 5: Array Operations Frozen**

**ReScript Code:**
```rescript
let mapped = items()->Array.map(x => x * 2)
```

**Generated JavaScript:**
```javascript
let mapped = items().map(x => (x << 1));  // ❌ Computed once

return <div>
  <p>{"Mapped length: "}{mapped.length}</p>  // Never updates
  <p>{"Items count: "}{items().length}</p>  // ✅ Reactive
</div>;
```

**Why it breaks:** `items()` called once, resulting array never updates.

---

### ❌ **EDGE CASE 6: Memo Snapshot**

**ReScript Code:**
```rescript
let combined = createMemo(() => outer() + inner())
let snapshot = combined()  // Reading memo outside JSX
```

**Generated JavaScript:**
```javascript
let combined = SolidJs.createMemo(() => outer() + inner());
let snapshot = combined();  // ❌ Read once

return <div>
  <p>{"Combined (memo): "}{combined()}</p>  // ✅ Reactive
  <p>{"Snapshot: "}{snapshot}</p>  // ❌ Never updates
</div>;
```

**Why it breaks:** Reading the memo at component creation captures its initial value.

---

### ❌ **EDGE CASE 7: Object Literals Freeze Values**

**ReScript Code:**
```rescript
let person = {
  "first": firstName(),
  "last": lastName(),
  "full": firstName() ++ " " ++ lastName(),
}
```

**Generated JavaScript:**
```javascript
let person = {
  first: firstName(),   // ❌ Captured once
  last: lastName(),     // ❌ Captured once
  full: firstName() + " " + lastName()  // ❌ Captured once
};

return <div>
  <p>{"Person.full: "}{person.full}</p>  // Never updates
  <p>{"Direct concat: "}{firstName() + " " + lastName()}</p>  // ✅ Reactive
</div>;
```

**Why it breaks:** Object created at component creation with frozen values.

---

### ❌ **EDGE CASE 8: Function Calls Computed Once**

**ReScript Code:**
```rescript
let result1 = computeExpensive(count())
let result2 = createMemo(() => computeExpensive(count()))
```

**Generated JavaScript:**
```javascript
let result1 = computeExpensive(count());  // ❌ Called once
let result2 = SolidJs.createMemo(() => computeExpensive(count()));  // ✅ Memoized

return <div>
  <p>{"Result1: "}{result1}</p>  // Never updates
  <p>{"Result2: "}{result2()}</p>  // ✅ Updates
  <p>{"Result3: "}{computeExpensive(count())}</p>  // ✅ Reactive but inefficient
</div>;
```

**Why it breaks:** Function called at component creation for `result1`.

**Note:** Inline `result3` is reactive but recalculates on every render (inefficient).

---

### ❌ **EDGE CASE 9: Closures Capture Values**

**ReScript Code:**
```rescript
let getCapturedValue = () => {
  let captured = count()
  () => captured
}
let closureValue = getCapturedValue()
```

**Generated JavaScript:**
```javascript
let captured = count();  // ❌ Read once
let closureValue = () => captured;  // Returns frozen value

return <div>
  <p>{"Closure value: "}{closureValue()}</p>  // Always shows initial value
  <p>{"Direct value: "}{count()}</p>  // ✅ Reactive
</div>;
```

**Why it breaks:** Classic closure capture - `captured` is a number, not a reactive accessor.

---

### ❌ **EDGE CASE 10: Multiple Signal Reads**

**ReScript Code:**
```rescript
let sum = a() + b() + c()
```

**Generated JavaScript:**
```javascript
let sum = (a() + b() | 0) + c() | 0;  // ❌ Computed once

return <div>
  <p>{"Sum (computed once): "}{sum}</p>  // Never updates
  <p>{"Sum (inline): "}{(a() + b() | 0) + c() | 0}</p>  // ✅ Reactive
</div>;
```

**Why it breaks:** All three signals read at component creation.

---

### ❌ **EDGE CASE 11: String Concatenation Frozen**

**ReScript Code:**
```rescript
let greeting = "Hello " ++ name() ++ ", count: " ++ Int.toString(count())
```

**Generated JavaScript:**
```javascript
let greeting = "Hello " + name() + ", count: " + count().toString();  // ❌ Computed once

return <div>
  <p>{"Greeting (created once): "}{greeting}</p>  // Never updates
  <p>
    {"Greeting (inline): "}
    {"Hello " + name() + ", count: " + count().toString()}  // ✅ Reactive
  </p>
</div>;
```

**Why it breaks:** String built at component creation.

---

### ❌ **EDGE CASE 12: Object Property Access Captured**

**ReScript Code:**
```rescript
let age = user().age
```

**Generated JavaScript:**
```javascript
let age = user().age;  // ❌ Read once

return <div>
  <p>
    {"Age (captured): "}
    {age !== undefined ? age : "N/A"}  // Never updates
  </p>
  <p>
    {"Age (inline): "}
    {user().age !== undefined ? user().age : "N/A"}  // ✅ Reactive
  </p>
</div>;
```

**Why it breaks:** `user()` called once, property extracted and frozen.

---

## Summary: The Pattern

### ❌ **What ALWAYS Breaks:**

Any expression assigned to a `let` binding at component level that reads signals:

```rescript
// All of these break reactivity:
let value = signal()
let computed = signal() * 2
let text = "Count: " ++ Int.toString(signal())
let array = signals()->Array.map(fn)
let object = {field: signal()}
let ternary = condition ? signal1() : signal2()
let matched = switch signal() { ... }
let called = fn(signal())
```

**Why:** ReScript evaluates these at component creation (outside reactive context).

### ✅ **What ALWAYS Works:**

Same expressions **directly in JSX**:

```rescript
<div>
  {int(signal())}
  {int(signal() * 2)}
  {string("Count: " ++ Int.toString(signal()))}
  <For each_={signals()->Array.map(fn)}>...</For>
  {string(condition ? signal1() : signal2())}
  {string(switch signal() { ... })}
  {int(fn(signal()))}
</div>
```

**Why:** Solid's reactivity tracks all signal reads during JSX rendering.

### ⚠️ **The Only Exception: createMemo**

```rescript
// ✅ This works because memo is reactive
let doubled = createMemo(() => signal() * 2)

<div>
  {int(doubled())}  // ✅ Reactive
</div>
```

---

## Critical Rules for ReScript + Solid

### Rule 1: Never Assign Signal Reads to Variables (Unless Using Memo)

```rescript
// ❌ WRONG
let count = signal()
let doubled = signal() * 2

// ✅ RIGHT
let doubled = createMemo(() => signal() * 2)

// ✅ OR: Use inline
<div>{int(signal() * 2)}</div>
```

### Rule 2: Put Complex Expressions Directly in JSX

```rescript
// ❌ WRONG
let message = switch count() {
| n if n > 10 => "High"
| _ => "Low"
}
<div>{string(message)}</div>

// ✅ RIGHT
<div>
  {string(switch count() {
  | n if n > 10 => "High"
  | _ => "Low"
  })}
</div>

// ✅ OR: Use memo for complex logic
let message = createMemo(() =>
  switch count() {
  | n if n > 10 => "High"
  | _ => "Low"
  }
)
<div>{string(message())}</div>
```

### Rule 3: Never Create Objects/Arrays with Signal Values

```rescript
// ❌ WRONG
let person = {
  "name": firstName(),
  "age": age(),
}

// ✅ RIGHT: Use memo
let person = createMemo(() => ({
  "name": firstName(),
  "age": age(),
}))

// ✅ OR: Read signals inline
<div>
  {string(firstName())}
  {int(age())}
</div>
```

### Rule 4: Function Calls with Signals Need Memos

```rescript
// ❌ WRONG
let formatted = formatDate(date())

// ✅ RIGHT
let formatted = createMemo(() => formatDate(date()))

// ⚠️ WORKS but inefficient (recalculates every render)
<div>{string(formatDate(date()))}</div>
```

### Rule 5: String Concatenation Inline Only

```rescript
// ❌ WRONG
let greeting = "Hello " ++ name()

// ✅ RIGHT: Inline
<div>{string("Hello " ++ name())}</div>

// ✅ OR: Memo
let greeting = createMemo(() => "Hello " ++ name())
```

---

## Comparison with Pure JavaScript Solid

### In JavaScript Solid:

```javascript
// Both work in JS (but not ideal):
const doubled = () => count() * 2;  // Manual accessor
const doubled2 = createMemo(() => count() * 2);  // Memoized

return <div>
  <p>{doubled()}</p>  {/* Works */}
  <p>{doubled2()}</p>  {/* Works + cached */}
</div>;
```

### In ReScript Solid:

```rescript
// ❌ WRONG: Can't create manual accessor easily
let doubled = () => count() * 2  // This creates a function, but ReScript might optimize it

// ✅ RIGHT: Must use memo
let doubled = createMemo(() => count() * 2)

<div>
  <p>{int(doubled())}</p>
</div>
```

---

## Why This Happens

1. **ReScript's optimization**: Evaluates expressions eagerly
2. **Component scope**: Variables initialized at component creation
3. **No re-execution**: Component function runs once, only JSX is reactive
4. **Solid's model**: Tracks signal reads during render, not during component init

## The Solution Flowchart

```
Need to compute something from a signal?
│
├─ Is it simple (1 operation)?
│  └─ Put it inline in JSX ✅
│
├─ Is it complex or used multiple times?
│  └─ Use createMemo ✅
│
└─ Is it a constant derived from signals?
   └─ Use createMemo ✅
```

---

## Real-World Impact

### ❌ **Bug Example 1: Stale Formatted Date**

```rescript
// BUG:
let formatted = Intl.DateTimeFormat.format(timestamp())
<div>{string(formatted)}</div>  // Never updates!

// FIX:
let formatted = createMemo(() => Intl.DateTimeFormat.format(timestamp()))
<div>{string(formatted())}</div>
```

### ❌ **Bug Example 2: Stale Filtered List**

```rescript
// BUG:
let filtered = items()->Array.filter(item => item.active)
<For each_={filtered}>...</For>  // Never updates!

// FIX:
let filtered = createMemo(() => items()->Array.filter(item => item.active))
<For each_={filtered()}>...</For>
```

### ❌ **Bug Example 3: Stale User Display Name**

```rescript
// BUG:
let displayName = user().firstName ++ " " ++ user().lastName
<div>{string(displayName)}</div>  // Never updates!

// FIX 1: Inline
<div>{string(user().firstName ++ " " ++ user().lastName)}</div>

// FIX 2: Memo (better if used multiple times)
let displayName = createMemo(() => user().firstName ++ " " ++ user().lastName)
<div>{string(displayName())}</div>
```

---

## Testing These Edge Cases

Run the example:

```bash
cd example
bun install  # or npm install
bun run dev  # or npm run dev
```

Visit the "Edge Cases" page and click buttons to see which values update (reactive ✅) vs stay frozen (broken ❌).

---

## Conclusion

**The Golden Rule for ReScript + Solid:**

> Any signal read outside of JSX or `createMemo` is evaluated ONCE at component creation and becomes stale.

**Always:**
- ✅ Read signals directly in JSX
- ✅ Use `createMemo` for computed values
- ✅ Inline complex expressions when possible

**Never:**
- ❌ Assign signal reads to variables
- ❌ Create objects/arrays with signal values
- ❌ Call functions with signal args and store result

**This is different from JavaScript Solid** where you can create manual accessors. ReScript's compilation model requires explicit `createMemo` for reactivity.

---

**Generated:** 2025-11-27
**ReScript:** 12.0.0
**Test File:** `example/src/ReactivityEdgeCases.res`
**Generated JS:** `example/src/ReactivityEdgeCases.mjs`
