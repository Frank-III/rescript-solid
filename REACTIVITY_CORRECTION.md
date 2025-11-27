# Reactivity Correction: How Solid's Compiler Helps

## Important Clarification

After further investigation, **some "anti-patterns" I identified aren't actually broken** when using **vite-plugin-solid** or Babel plugin, because Solid's compiler automatically wraps props in getters!

## How It Actually Works

### With vite-plugin-solid (Your Setup)

```rescript
// In ReScript
<Child count={count()} />  // Passing value
```

**Build Pipeline:**
1. **ReScript** compiles to:
   ```javascript
   <Child count={count()} />  // JSX preserved
   ```

2. **vite-plugin-solid** transforms to:
   ```javascript
   // Solid wraps it in a getter automatically!
   <Child count={(() => count())} />  // Pseudo-code
   ```

3. **Child component** receives:
   ```javascript
   function Child(props) {
     // props.count is now a getter!
     return <div>{props.count}</div>  // Actually reactive!
   }
   ```

### ✅ So This Pattern WORKS (with vite-plugin-solid):

```rescript
// Parent
let (count, setCount) = createSignal(0)
<Child count={count()} />  // ✅ Works! Solid compiler wraps it

// Child
let make = (~count: int, ()) => {
  <div>{int(count)}</div>  // ✅ Reactive! count is actually a getter
}
```

**Why it works:** Solid's compiler transforms the props object to use getters for reactivity tracking.

## What Actually Breaks Reactivity

Let me correct which patterns are **real** anti-patterns:

### ❌ **REAL Anti-Pattern #1: Reading Signals Outside Reactive Context**

```rescript
let make = () => {
  let (count, setCount) = createSignal(0)
  let snapshot = count()  // ❌ Read once at creation

  <div>{int(snapshot)}</div>  // Never updates - it's a captured number
}
```

**Why it breaks:** `snapshot` is a JavaScript number (e.g., `0`), not reactive. Solid's compiler can't help here.

### ❌ **REAL Anti-Pattern #2: Deriving Without Memo**

```rescript
let make = () => {
  let (count, setCount) = createSignal(0)
  let doubled = count() * 2  // ❌ Computed once

  <div>{int(doubled)}</div>  // Never updates
}
```

**Why it breaks:** `doubled` is computed once and stored as a number.

**Fix:** Use `createMemo(() => count() * 2)`

### ❌ **REAL Anti-Pattern #3: Array Mutations**

```rescript
let addItem = () => {
  let current = items()
  current->Array.push(newItem)  // ❌ Mutation!
  setItems(_ => current)  // Same reference = no update
}
```

**Why it breaks:** Solid uses referential equality. Same array reference = no reactivity trigger.

**Fix:** `setItems(prev => Array.concat(prev, [newItem]))`

### ❌ **REAL Anti-Pattern #4: Effects in JSX**

```rescript
<div>
  {
    createEffect(() => Console.log("Effect!"))  // ❌ New effect every render
    null
  }
</div>
```

**Why it breaks:** Creates duplicate effects, memory leak.

**Fix:** Create effects at component top level.

### ❌ **REAL Anti-Pattern #5: Conditional Signal Creation**

```rescript
let (count, setCount) = if condition {  // ❌ Breaks rules
  createSignal(0)
} else {
  ((() => 0), (_ => ()))
}
```

**Why it breaks:** Violates Solid's rules (like React hooks).

**Fix:** Always create signals unconditionally.

## What About Passing Accessors vs Values?

### The Nuance

**With vite-plugin-solid:**
```rescript
// Both work, but have different semantics!

// Option 1: Pass value (Solid wraps it)
<Child count={count()} />  // ✅ Works, but reads immediately

// Option 2: Pass accessor (deferred reading)
<Child count={count} />    // ✅ Works, reads lazily
```

**The difference:**

```javascript
// Option 1: count() called in parent
<Child count={count()} />
// → <Child count={0} />
// → Solid wraps: <Child count$={() => 0} />
// Child reads: props.count → 0 (but wrapped, so still reactive)

// Option 2: count passed as function
<Child count={count} />
// → <Child count={[Function]} />
// Child reads: props.count() → calls function, gets current value
```

### Best Practice (Even With Compiler)

**Still prefer passing accessors** for:

1. **Lazy evaluation**: Child only reads when needed
2. **Clearer intent**: "This is reactive data"
3. **Performance**: Avoid unnecessary evaluations
4. **Portability**: Works without compiler magic

```rescript
// ✅ Best practice: Pass accessor
type childProps = {
  count: unit => int,  // Signal accessor
}

let make = (~count: unit => int, ()) => {
  <div>{int(count())}</div>
}
```

## Updated Anti-Pattern Classification

### ❌ **Broken Even With Compiler**
1. Reading signals at component creation
2. Deriving without memo
3. Array mutations
4. Effects in JSX
5. Conditional signal creation
6. Not using updater functions (race conditions)

### ⚠️ **Works With Compiler, But Avoid**
1. Passing values instead of accessors (works, but less efficient)
2. Creating closures that capture signal values (can work, but confusing)

### ✅ **Always Works**
1. Reading signals inside JSX
2. Using createMemo for derived state
3. Passing accessors
4. Immutable array updates
5. Using updater functions
6. Cleanup in effects

## Recommendations for ReScript Solid Bindings

### 1. **Document Both Approaches**

```rescript
// Approach A: Rely on Solid compiler (simpler types)
type childProps = {
  count: int,  // Solid will wrap this
}

// Approach B: Explicit accessors (recommended)
type childProps = {
  count: unit => int,  // Explicitly reactive
}
```

### 2. **Add Type Aliases for Clarity**

```rescript
// In Solid.res
type reactive<'a> = unit => 'a  // Signal accessor
type writable<'a> = (('a => 'a) => unit)  // Setter

// Usage
type props = {
  count: reactive<int>,
  setCount: writable<int>,
}
```

### 3. **Lint Rules (Future)**

Could detect:
- Signal reads at top level ✓ (real issue)
- Missing createMemo ✓ (real issue)
- Array mutations ✓ (real issue)
- ~~Value passing~~ ✗ (not actually broken with compiler)

## Conclusion

**I was partially wrong!**

With **vite-plugin-solid**, many patterns I marked as "broken" actually work because Solid's compiler wraps props in getters automatically.

**However:**
- Some anti-patterns (reading signals outside reactive context, no memo, array mutations) are **real issues**
- Passing accessors is still **best practice** even though passing values works
- Understanding the compilation pipeline is crucial

**The real anti-patterns are:**
1. ❌ Signal reads at component creation
2. ❌ Deriving without memo
3. ❌ Array mutations
4. ❌ Effects in JSX
5. ❌ Conditional signal creation

**These work but are discouraged:**
1. ⚠️ Passing values instead of accessors (less efficient, less clear)

Thank you for the correction! This is an important nuance that shows why understanding the build pipeline matters.

---

**Updated**: 2025-11-27
**Correction**: Props wrapping with vite-plugin-solid
**Credit**: User correction on Solid compiler behavior
