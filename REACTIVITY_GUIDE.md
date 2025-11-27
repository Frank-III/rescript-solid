# Solid.js Reactivity Guide for ReScript

This guide documents correct reactive patterns and common anti-patterns when using Solid.js with ReScript.

## ✅ Correct Reactive Patterns

### 1. Signal Access in JSX
**Always call signal accessors inside JSX or reactive contexts**

```rescript
let (count, setCount) = createSignal(0)

// ✅ GOOD
<div>{int(count())}</div>

// ❌ BAD
let value = count() // Read once, never updates
<div>{int(value)}</div>
```

### 2. Derived State with createMemo
**Use `createMemo` for expensive computations that depend on signals**

```rescript
let (count, setCount) = createSignal(0)

// ✅ GOOD - Memoized, only recomputes when count changes
let doubled = createMemo(() => count() * 2)
<div>{int(doubled())}</div>

// ❌ BAD - Reads once, never updates
let doubled = count() * 2
<div>{int(doubled)}</div>
```

### 3. Effects for Side Effects
**Use `createEffect` for logging, subscriptions, or other side effects**

```rescript
createEffect(() => {
  Console.log("Count is now: " ++ Int.toString(count()))
})
```

### 4. Passing Signals to Components
**Pass signal accessors, not values, to maintain reactivity**

```rescript
// ✅ GOOD - Pass the accessor function
<Child count={count} />

// In Child component:
let make = (~count: unit => int, ()) => {
  <div>{int(count())}</div> // Call the accessor in JSX
}

// ❌ BAD - Passes value once
<Child count={count()} />
```

### 5. Updating Arrays Immutably
**Create new arrays instead of mutating**

```rescript
// ✅ GOOD
setItems(prev => Array.concat(prev, [newItem]))
setItems(prev => prev->Array.filter(item => item.id !== deletedId))
setItems(prev => prev->Array.map(item =>
  item.id === updatedId ? {...item, name: newName} : item
))

// ❌ BAD - Don't mutate
let items = items()
items->Array.push(newItem) // Mutation!
setItems(_ => items)
```

### 6. Batch Multiple Updates
**Use `batch()` to prevent multiple effect runs**

```rescript
let updateMultiple = () => {
  batch(() => {
    setFirstName(_ => "Jane")
    setLastName(_ => "Smith")
    setAge(_ => 30)
  })
}
```

### 7. Cleanup in Effects
**Always cleanup timers, subscriptions, and event listeners**

```rescript
createEffect(() => {
  let interval = setInterval(() => {
    setCount(prev => prev + 1)
  }, 1000)

  onCleanup(() => {
    clearInterval(interval)
  })
})
```

### 8. Use Untrack When Needed
**Break reactivity intentionally with `untrack()`**

```rescript
createEffect(() => {
  let current = count() // Tracked
  let previous = untrack(() => previousCount()) // NOT tracked
  Console.log2(previous, current)
})
```

### 9. Updater Functions
**Use updater functions for reliable state updates**

```rescript
// ✅ GOOD
setCount(prev => prev + 1)
setCount(prev => prev + 1) // Correctly increments twice

// ❌ RISKY
setCount(_ => count() + 1)
setCount(_ => count() + 1) // Might not work as expected
```

## ❌ Anti-Patterns That Break Reactivity

### 1. Destructuring Signals
**Problem**: Reads signal value once at component creation

```rescript
// ❌ BROKEN
let currentCount = count() // Stale value
<div>{int(currentCount)}</div> // Never updates!
```

**Why it breaks**: Signal accessor is called outside reactive context (JSX/effect), so the value is read once and never updates.

### 2. Computing Without Memo
**Problem**: Computes once instead of reactively

```rescript
// ❌ BROKEN
let doubled = count() * 2 // Computed once
<div>{int(doubled)}</div> // Shows stale value
```

**Why it breaks**: Computation happens at component initialization, not when count changes.

### 3. Passing Values Instead of Accessors
**Problem**: Child component receives static value

```rescript
// ❌ BROKEN
<Child count={count()} /> // Passes number once

// Child never sees updates
let make = (~count: int, ()) => <div>{int(count)}</div>
```

**Why it breaks**: The prop receives a snapshot value, not a reactive accessor.

### 4. Array Mutations
**Problem**: Mutating arrays doesn't trigger updates

```rescript
// ❌ BROKEN
let items = items()
items->Array.push(newItem) // Mutation!
setItems(_ => items) // Same reference, no update!
```

**Why it breaks**: Solid uses referential equality. Same array reference = no update.

### 5. Effects in JSX
**Problem**: Creates new effect on every render

```rescript
// ❌ BROKEN
<div>
  {
    createEffect(() => Console.log("Too many effects!"))
    null
  }
</div>
```

**Why it breaks**: JSX body re-executes on renders, creating duplicate effects.

### 6. Conditional Signal Creation
**Problem**: Violates rules of reactive primitives

```rescript
// ❌ BROKEN
let (count, setCount) = if condition {
  createSignal(0)
} else {
  ((() => 0), (_ => ()))
}
```

**Why it breaks**: Signals must be created unconditionally in the same order every render (like React hooks).

### 7. Reading Outside Reactive Context
**Problem**: Creates no tracking dependency

```rescript
// ❌ BROKEN
let make = () => {
  let (count, setCount) = createSignal(0)
  let snapshot = count() // Not reactive!

  createEffect(() => {
    // Effect doesn't depend on snapshot
    Console.log(snapshot) // Always shows initial value
  })
}
```

**Why it breaks**: Reading outside effect/JSX doesn't establish reactive dependency.

### 8. Not Using Updater Functions
**Problem**: Can lead to race conditions or stale closures

```rescript
// ❌ RISKY
let incrementTwice = () => {
  setCount(_ => count() + 1)
  setCount(_ => count() + 1) // Might read stale value
}
```

**Why it breaks**: The second call might read the old value before the first update completes.

## ReScript-Specific Considerations

### 1. Optional Props
Use optional types properly with Solid's reactivity:

```rescript
type props = {
  count?: unit => int, // Optional signal accessor
}

let make = (~count: option<unit => int>=?, ()) => {
  switch count {
  | Some(accessor) => <div>{int(accessor())}</div>
  | None => <div>{string("No count")}</div>
  }
}
```

### 2. Belt/Stdlib vs ReScript 12 Stdlib
ReScript 12 includes Stdlib. Prefer:

```rescript
// ✅ ReScript 12
Array.map(items, fn)
Int.toString(count())
Option.getOr(value, default)

// ❌ Old Belt (still works but deprecated path)
Belt.Array.map(items, fn)
Belt.Int.toString(count())
Belt.Option.getWithDefault(value, default)
```

### 3. JSX Preserve Mode
With preserve mode enabled:
- JSX is emitted as-is for downstream tooling
- Solid's compiler can optimize better
- Works well with React DevTools

```json
// rescript.json
{
  "jsx": {
    "version": 4,
    "preserve": true
  }
}
```

## Testing Reactivity

To verify reactivity is working:

1. **Console Logging**: Check if effects run expected number of times
2. **UI Updates**: Verify DOM updates when signals change
3. **Performance**: Use `createMemo` to avoid expensive recalculations
4. **DevTools**: Use Solid DevTools browser extension to track reactivity graph

## Common Debugging Tips

1. **Effect runs too often?**
   - Check if you're reading more signals than intended
   - Use `untrack()` for non-reactive reads

2. **UI not updating?**
   - Verify signal accessor is called inside JSX: `count()` not `count`
   - Check if you're passing values instead of accessors to components
   - Ensure arrays/objects are immutably updated

3. **Stale values in closures?**
   - Use updater functions: `setCount(prev => prev + 1)`
   - Read signals inside the closure where needed

4. **Memory leaks?**
   - Add `onCleanup()` for intervals, subscriptions, listeners
   - Verify effects aren't created in JSX

## Examples

Full working examples are available in:
- `example/src/ReactivityPatterns.res` - ✅ Correct patterns
- `example/src/ReactivityAntiPatterns.res` - ❌ Common mistakes

Build and run the examples:
```bash
cd example
npm install
npm run dev
```

## Resources

- [Solid.js Reactivity Docs](https://www.solidjs.com/tutorial/introduction_signals)
- [ReScript 12 Release Notes](https://rescript-lang.org/blog/release-12-0-0)
- [ReScript Stdlib Docs](https://rescript-lang.org/docs/manual/latest/api)
