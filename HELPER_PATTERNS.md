# ReScript + Solid.js Helper Patterns & Utilities

## Problem: Scope Hoisting Limitations

ReScript lifts block expressions and IIFEs to component creation scope, breaking:
- Local signal scopes
- Suspense boundaries
- ErrorBoundary scope
- Context scoping
- Lifecycle hooks in nested scopes

## Solution: Helper Patterns & Type Utilities

### 1. Component Factory Pattern

```rescript
// SolidHelpers.res
module Component = {
  // Create scoped component inline
  type scopedProps<'props> = {
    render: 'props => Jsx.element,
    props: 'props,
  }

  @jsx.component
  let scoped = (~render, ~props) => render(props)

  // Usage:
  // <Component.scoped render={_ => {
  //   let (count, setCount) = createSignal(0)
  //   <button>{int(count())}</button>
  // }} props={()}/>
}
```

### 2. Suspense-Safe Resource Wrapper

```rescript
// Ensures createResource is called in component scope
module SuspenseResource = {
  @jsx.component
  let make = (~fetcher, ~children: 'data => Jsx.element) => {
    let (data, _) = createResource(fetcher)

    switch data() {
    | Some(d) => children(d)
    | None => null
    }
  }
}

// Usage:
// <Suspense fallback_={string("Loading...")}>
//   <SuspenseResource fetcher={fetchData}>
//     {data => <div>{string(data)}</div>}
//   </SuspenseResource>
// </Suspense>
```

### 3. Accessor Builder Pattern

```rescript
module Signal = {
  type accessor<'a> = unit => 'a
  type setter<'a> = ('a => 'a) => unit

  // Create derived accessor (manual memo alternative)
  let derive = (signal: accessor<'a>, fn: 'a => 'b): accessor<'b> => {
    () => fn(signal())
  }

  // Create cached derived (actual memo)
  let deriveMemo = (signal: accessor<'a>, fn: 'a => 'b): accessor<'b> => {
    createMemo(() => fn(signal()))
  }

  // Map signal value
  let map = (signal: accessor<'a>, fn: 'a => 'b): accessor<'b> => {
    () => fn(signal())
  }

  // Filter signal value
  let filter = (signal: accessor<'a>, predicate: 'a => bool, default: 'a): accessor<'a> => {
    () => {
      let value = signal()
      predicate(value) ? value : default
    }
  }
}

// Usage:
// let (count, setCount) = createSignal(0)
// let doubled = Signal.map(count, x => x * 2)
// let isEven = Signal.map(count, x => mod(x, 2) == 0)
// <div>{int(doubled())}</div>
```

### 4. Scoped Component Generator Macro

```rescript
module Scoped = {
  // Pattern: Generate component from render function
  module type Component = {
    @jsx.component
    let make: unit => Jsx.element
  }

  // Helper to create scoped components
  let component = (render: unit => Jsx.element): module(Component) => {
    module Comp = {
      @jsx.component
      let make = render
    }
    module(Comp)
  }
}

// Usage would be limited, but shows the pattern
```

### 5. Context-Safe Provider Pattern

```rescript
module ContextProvider = {
  @jsx.component
  let make = (
    ~context: Context.t<'value>,
    ~value: 'value,
    ~children: Jsx.element,
  ) => {
    <context.Provider value={value}>
      {children}
    </context.Provider>
  }
}
```

### 6. Safe Show Component with Local State

```rescript
module ShowScoped = {
  @jsx.component
  let make = (
    ~when_: bool,
    ~fallback: Jsx.element=null,
    ~children: unit => Jsx.element,
  ) => {
    when_ ? children() : fallback
  }
}

// Usage:
// <ShowScoped when_={count() > 10}>
//   {() => {
//     // This creates a NEW scope - state won't persist!
//     let (local, setLocal) = createSignal(0)
//     <div>{int(local())}</div>
//   }}
// </ShowScoped>
```

### 7. ForScoped - For with Item Components

```rescript
module ForScoped = {
  @jsx.component
  let make = (
    ~each_: array<'item>,
    ~fallback: Jsx.element=null,
    ~children: ('item, accessor<int>) => Jsx.element,
  ) => {
    <For each_={each_} fallback_={fallback}>
      {(item, index) => {
        // Wrap in component to ensure proper scoping
        module Item = {
          @jsx.component
          let make = () => children(item, index)
        }
        <Item />
      }}
    </For>
  }
}
```

### 8. Type-Safe Manual Accessor Pattern

```rescript
module Accessor = {
  type t<'a> = unit => 'a

  // Compose accessors
  let compose: (t<'a>, 'a => 'b) => t<'b> = (accessor, fn) => () => fn(accessor())

  // Combine two accessors
  let combine: (t<'a>, t<'b>, ('a, 'b) => 'c) => t<'c> =
    (a, b, fn) => () => fn(a(), b())

  // Conditional accessor
  let when_: (t<'a>, t<bool>, 'a) => t<'a> =
    (accessor, condition, default) => () => condition() ? accessor() : default
}

// Usage:
// let message = Accessor.compose(count, n =>
//   n > 10 ? "High" : "Low"
// )
// <div>{string(message())}</div>
```

### 9. ErrorBoundary-Safe Wrapper

```rescript
module SafeComponent = {
  @jsx.component
  let make = (~fallback: Jsx.element, ~children: unit => Jsx.element) => {
    <ErrorBoundary fallback={fallback}>
      {children()}
    </ErrorBoundary>
  }
}
```

### 10. Lifecycle Hook Wrapper

```rescript
module WithLifecycle = {
  @jsx.component
  let make = (
    ~onMount: option<unit => unit>=?,
    ~onCleanup: option<unit => unit>=?,
    ~children: Jsx.element,
  ) => {
    switch onMount {
    | Some(fn) => Solid.onMount(fn)
    | None => ()
    }

    switch onCleanup {
    | Some(fn) =>
      createEffect(() => {
        Solid.onCleanup(fn)
      })
    | None => ()
    }

    children
  }
}
```

## Best Practice Patterns

### Pattern 1: Always Use Separate Components for Scoping

```rescript
// ❌ NEVER - IIFE gets lifted
{(() => {
  let (count, setCount) = createSignal(0)
  <button>{int(count())}</button>
})()}

// ✅ ALWAYS - Separate component
module LocalCounter = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)
    <button>{int(count())}</button>
  }
}
<LocalCounter />
```

### Pattern 2: Manual Accessors for Derived Values

```rescript
// ✅ Simple derived - manual accessor (no caching)
let doubled = () => count() * 2

// ✅ Complex/reused - use memo (cached)
let filtered = createMemo(() => items()->Array.filter(item => item.active))
```

### Pattern 3: Suspense Boundaries Need Component Boundaries

```rescript
// ❌ BROKEN
let (data, _) = createResource(fetchData)  // Outside Suspense!
<Suspense fallback_={string("Loading...")}>
  <div>{string(data())}</div>
</Suspense>

// ✅ CORRECT
module DataLoader = {
  @jsx.component
  let make = () => {
    let (data, _) = createResource(fetchData)  // Inside component
    <div>{string(data())}</div>
  }
}
<Suspense fallback_={string("Loading...")}>
  <DataLoader />
</Suspense>
```

### Pattern 4: Type-Safe Accessor Composition

```rescript
// Define accessor type
type accessor<'a> = unit => 'a

// Create composable accessors
let (count, setCount) = createSignal(0)
let doubled: accessor<int> = () => count() * 2
let message: accessor<string> = () => doubled() > 10 ? "High" : "Low"

// Use in JSX
<div>{string(message())}</div>
```

### Pattern 5: Switch Statements - Extract to Accessor

```rescript
// ⚠️ AVOID - Inline switch gets partially lifted
<div>{switch count() {
| n if n > 10 => string("High")
| _ => string("Low")
}}</div>

// ✅ BETTER - Extract to accessor
let message = () => switch count() {
| n if n > 10 => "High"
| _ => "Low"
}
<div>{string(message())}</div>

// ✅ BEST - Use memo for complex logic
let message = createMemo(() => switch count() {
| n if n > 10 => "High"
| _ => "Low"
})
<div>{string(message())}</div>
```

---

## AI Implementation Instructions

Create the following helper module in `src/SolidHelpers.res`:

1. **Signal utilities** - map, filter, derive, deriveMemo functions
2. **Accessor type** - type-safe accessor composition utilities
3. **Component wrappers** - SuspenseResource, SafeComponent, WithLifecycle
4. **Scoped component helpers** - Component.scoped pattern

Export all utilities and document with examples showing:
- ❌ What breaks (IIFE lifting)
- ✅ How to fix (separate components, accessors)

Make it production-ready with proper types and JSDoc comments.
