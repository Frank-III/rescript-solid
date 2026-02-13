# ReScript + Solid.js: Safe Patterns Allow List

## Philosophy: What We Keep vs What We Avoid

### ✅ What We **KEEP** (ReScript's Core Value)

1. **Type Safety** - Full type inference and safety ✅
2. **Pattern Matching** - Just in accessors/memos, not inline JSX ✅
3. **Variants & Tagged Unions** - Perfect for state machines ✅
4. **Pipe Operator** - Works great in accessors ✅
5. **Immutability** - Core benefit, unchanged ✅
6. **Fast Compilation** - Even faster in ReScript 12 ✅
7. **JS Interop** - Clean output, works perfectly ✅
8. **Labeled Arguments** - Makes components self-documenting ✅

### ⚠️ What We **ADJUST** (Not Lose, Just Use Differently)

1. **Block Expressions in JSX** → Extract to accessors or components
2. **IIFEs in JSX** → Use separate components
3. **Inline Pattern Matching** → Extract to memoized accessors
4. **Local Scopes** → Use component boundaries

### ❌ What We Actually **LOSE**

**Honestly? Almost nothing important.**

The adjustments are just **organizational patterns**, not feature losses. You still get all of ReScript's power, just with clear rules about where to use it.

---

## 🎯 The Allow List: Safe Pattern Rules

### Rule 1: Signal Access
✅ **ALLOWED** - Direct signal calls in JSX
```rescript
let (count, setCount) = createSignal(0)
<div>{int(count())}</div>
```

✅ **ALLOWED** - Signal access in event handlers
```rescript
<button onClick={_ => setCount(prev => prev + 1)}>
```

❌ **FORBIDDEN** - Destructuring signals
```rescript
let value = count()  // ❌ Frozen value
<div>{int(value)}</div>
```

---

### Rule 2: Derived Values

✅ **ALLOWED** - Manual accessors for simple derivations
```rescript
let (count, setCount) = createSignal(0)
let doubled = () => count() * 2  // ✅ Re-evaluates every time
<div>{int(doubled())}</div>
```

✅ **ALLOWED** - Memos for expensive/reused computations
```rescript
let filtered = createMemo(() => items()->Array.filter(isActive))
<For each_={filtered()}> ... </For>
```

❌ **FORBIDDEN** - Computed values outside accessors
```rescript
let doubled = count() * 2  // ❌ Evaluated once
```

---

### Rule 3: Pattern Matching

✅ **ALLOWED** - Pattern matching in accessors
```rescript
let message = () => switch status() {
| #idle => "Ready"
| #loading => "Loading..."
| #done => "Complete"
}
<div>{string(message())}</div>
```

✅ **ALLOWED** - Pattern matching with memo
```rescript
let message = createMemo(() => switch status() {
| #idle => "Ready"
| #loading => "Loading..."
| #done => "Complete"
})
<div>{string(message())}</div>
```

⚠️ **AVOID** - Inline pattern matching in JSX
```rescript
// Works but signal read gets lifted
<div>{switch status() {
| #idle => string("Ready")
| #done => string("Done")
}}</div>

// Better: Extract to accessor
let statusText = () => switch status() { ... }
<div>{string(statusText())}</div>
```

---

### Rule 4: Array Operations

✅ **ALLOWED** - Array ops in memos (reused/expensive)
```rescript
let filtered = createMemo(() => items()->Array.filter(x => x.active))
let mapped = createMemo(() => items()->Array.map(x => x.name))
<For each_={filtered()}> ... </For>
```

✅ **ALLOWED** - Array ops in accessors (cheap/one-time)
```rescript
let count = () => items()->Array.length
<div>{int(count())}</div>
```

❌ **FORBIDDEN** - Array ops at component scope
```rescript
let (items, _) = createSignal([1, 2, 3])
let mapped = items()->Array.map(x => x * 2)  // ❌ Frozen
```

---

### Rule 5: Conditional Rendering

✅ **ALLOWED** - Show component with function children
```rescript
<Show when_={user()}>
  {u => <div>{string(u.name)}</div>}
</Show>
```

✅ **ALLOWED** - Ternary with accessors
```rescript
{count() > 10 ? <div>{string("High")}</div> : <div>{string("Low")}</div>}
```

✅ **ALLOWED** - Switch in accessor
```rescript
let content = () => switch state() {
| #loading => <Spinner />
| #error => <ErrorMsg />
| #success(data) => <DataView data />
}
<div>{content()}</div>
```

❌ **FORBIDDEN** - Destructured conditionals
```rescript
let isHigh = count() > 10  // ❌ Frozen
{isHigh ? <div>...</div> : <div>...</div>}
```

---

### Rule 6: Component Boundaries

✅ **ALLOWED** - Separate components for scopes
```rescript
module DataLoader = {
  @jsx.component
  let make = () => {
    let (data, _) = createResource(fetchData)
    <div>{string(data())}</div>
  }
}

<Suspense fallback_={string("Loading...")}>
  <DataLoader />
</Suspense>
```

✅ **ALLOWED** - Nested components for local state
```rescript
module Counter = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)
    <button onClick={_ => setCount(x => x + 1)}>
      {int(count())}
    </button>
  }
}
```

❌ **FORBIDDEN** - IIFEs for scoping
```rescript
{(() => {
  let (count, setCount) = createSignal(0)  // ❌ Executes at creation
  <button>{int(count())}</button>
})()}
```

---

### Rule 7: Suspense & Resources

✅ **ALLOWED** - createResource in component scope (inside Suspense)
```rescript
module DataLoader = {
  @jsx.component
  let make = () => {
    let (data, _) = createResource(fetchData)
    // This component will be inside Suspense boundary
  }
}

<Suspense fallback_={...}>
  <DataLoader />
</Suspense>
```

✅ **ALLOWED** - Helper component wrapper
```rescript
<Suspense fallback_={string("Loading...")}>
  <SuspenseResource fetcher={fetchData}>
    {data => <div>{string(data.name)}</div>}
  </SuspenseResource>
</Suspense>
```

❌ **FORBIDDEN** - createResource outside Suspense
```rescript
let (data, _) = createResource(fetchData)  // ❌ Outside boundary
<Suspense fallback_={...}>
  <div>{string(data())}</div>
</Suspense>
```

---

### Rule 8: Lifecycle Hooks

✅ **ALLOWED** - onMount/onCleanup at component top level
```rescript
@jsx.component
let make = () => {
  let (count, setCount) = createSignal(0)

  onMount(() => {
    Console.log("Mounted!")
  })

  createEffect(() => {
    onCleanup(() => Console.log("Cleanup!"))
  })

  <div>...</div>
}
```

❌ **FORBIDDEN** - Lifecycle hooks in nested scopes
```rescript
// Don't try to use onMount/onCleanup inside IIFEs or blocks
```

---

### Rule 9: Effects

✅ **ALLOWED** - createEffect at component top level
```rescript
@jsx.component
let make = () => {
  let (count, setCount) = createSignal(0)

  createEffect(() => {
    Console.log("Count changed: " ++ Int.toString(count()))
  })

  <div>...</div>
}
```

✅ **ALLOWED** - Effects with cleanup
```rescript
createEffect(() => {
  let interval = setInterval(() => setCount(x => x + 1), 1000)
  onCleanup(() => clearInterval(interval))
})
```

---

### Rule 10: Context

✅ **ALLOWED** - Context provider at component level
```rescript
module App = {
  @jsx.component
  let make = () => {
    let (theme, setTheme) = createSignal(#light)

    <ThemeContext.Provider value={theme}>
      <ChildComponents />
    </ThemeContext.Provider>
  }
}
```

✅ **ALLOWED** - useContext in component
```rescript
@jsx.component
let make = () => {
  let theme = useContext(ThemeContext)
  <div className={theme() == #light ? "light" : "dark"}>...</div>
}
```

---

## 🎨 Pattern Template Library

### Template 1: List with Filtering
```rescript
@jsx.component
let make = () => {
  let (items, setItems) = createSignal([...])
  let (filter, setFilter) = createSignal("")

  // Memoized filtering
  let filtered = createMemo(() => {
    let f = filter()
    items()->Array.filter(item => String.includes(item.name, f))
  })

  <div>
    <input onInput={e => setFilter(e.target.value)} />
    <For each_={filtered()}>
      {(item, _) => <div>{string(item.name)}</div>}
    </For>
  </div>
}
```

### Template 2: State Machine with Variants
```rescript
type state =
  | Idle
  | Loading
  | Success(string)
  | Error(string)

@jsx.component
let make = () => {
  let (state, setState) = createSignal(Idle)

  // Pattern match in memo
  let content = createMemo(() => switch state() {
  | Idle => <button onClick={_ => setState(_ => Loading)}>Load</button>
  | Loading => <div>{string("Loading...")}</div>
  | Success(data) => <div>{string(data)}</div>
  | Error(msg) => <div>{string("Error: " ++ msg)}</div>
  })

  <div>{content()}</div>
}
```

### Template 3: Suspense Resource Loading
```rescript
module DataLoader = {
  @jsx.component
  let make = (~userId: int) => {
    let (user, _) = createResource(() => fetchUser(userId))

    switch user() {
    | Some(u) => <UserProfile user={u} />
    | None => null
    }
  }
}

@jsx.component
let make = (~userId: int) => {
  <Suspense fallback_={<Spinner />}>
    <DataLoader userId />
  </Suspense>
}
```

### Template 4: Derived Signals Chain
```rescript
@jsx.component
let make = () => {
  let (count, setCount) = createSignal(0)

  // Chain of manual accessors (cheap)
  let doubled = () => count() * 2
  let isHigh = () => doubled() > 10
  let message = () => isHigh() ? "High" : "Low"

  <div>
    <p>{string("Count: ")}{int(count())}</p>
    <p>{string("Doubled: ")}{int(doubled())}</p>
    <p>{string("Status: ")}{string(message())}</p>
  </div>
}
```

### Template 5: Component with Cleanup
```rescript
@jsx.component
let make = () => {
  let (time, setTime) = createSignal(0)

  createEffect(() => {
    let interval = setInterval(() => setTime(t => t + 1), 1000)
    onCleanup(() => {
      Console.log("Cleaning up interval")
      clearInterval(interval)
    })
  })

  <div>{string("Time: " ++ Int.toString(time()))}</div>
}
```

---

## 🔍 Quick Decision Tree

**Need to transform a signal value?**
- Simple/cheap → Manual accessor `let x = () => signal() * 2`
- Complex/reused → Memo `let x = createMemo(() => ...)`

**Need pattern matching?**
- Put in accessor or memo, never inline in JSX

**Need local scope?**
- Create separate component module

**Need Suspense?**
- Resource must be in separate component inside Suspense boundary

**Need array operations?**
- Cheap (length, access) → Accessor
- Expensive (map, filter, sort) → Memo

**Need lifecycle?**
- Always at component top level, never nested

---

## 📊 What You DON'T Lose

| ReScript Feature | Still Available? | How to Use |
|-----------------|------------------|------------|
| Pattern Matching | ✅ YES | In accessors/memos |
| Variants | ✅ YES | Everywhere |
| Type Safety | ✅ YES | Everywhere |
| Pipe Operator | ✅ YES | In accessors/memos |
| Labeled Args | ✅ YES | Component props |
| Immutability | ✅ YES | Default behavior |
| Records | ✅ YES | Component state/props |
| Options | ✅ YES | Perfect for nullable data |
| Results | ✅ YES | Error handling |
| Modules | ✅ YES | Component organization |
| Fast Compile | ✅ YES | Even faster now |

**You lose: Nothing significant. Just need clear patterns.**

---

## 🎯 The Real Trade-off

### What JS Solid Can Do:
```javascript
// IIFE for local scope
{(() => {
  const [count, setCount] = createSignal(0);
  return <button>{count()}</button>;
})()}
```

### What ReScript Should Do Instead:
```rescript
// Separate component (clearer, reusable, properly scoped)
module LocalCounter = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)
    <button>{int(count())}</button>
  }
}
<LocalCounter />
```

**Is this a loss?** No! It's actually **better architecture**:
- More reusable
- Better type inference
- Easier to test
- Clearer component boundaries
- Self-documenting code

---

## 🚀 Bottom Line

**ReScript + Solid.js is totally viable** if you follow these patterns:

1. ✅ Use manual accessors for simple derivations
2. ✅ Use memos for expensive/reused computations
3. ✅ Extract pattern matching to accessors
4. ✅ Use separate components for scoping
5. ✅ Keep lifecycle hooks at component top level
6. ✅ Put resources inside component boundaries

**You keep 95%+ of ReScript's power** with just organizational discipline. The "losses" are actually **architectural improvements** that make code more maintainable.

The allow list makes you write **better Solid.js code** than you might in JavaScript!
