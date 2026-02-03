// Comprehensive reactivity test for Solid.js bindings
// This file demonstrates correct vs incorrect patterns

open Solid

module Section = {
  @jsx.component
  let make = (~title: string, ~children: element, ()) => {
    <div>
      <h3>{string(title)}</h3>
      {children}
      <hr />
    </div>
  }
}

// ============================================
// TEST 1: Basic signal reactivity in JSX
// ============================================
module BasicSignal = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    <Section title="1. Basic Signal (SHOULD work)">
      <p>{string("Count: ")}<strong>{int(count())}</strong></p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
      <p className="note">
        {string("Signal read directly in JSX - reactive")}
      </p>
    </Section>
  }
}

// ============================================
// TEST 2: Derived value with createMemo
// ============================================
module DerivedMemo = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)
    let doubled = createMemo(() => count() * 2)
    let tripled = createMemo(() => count() * 3)

    <Section title="2. Derived with createMemo (SHOULD work)">
      <p>{string("Count: ")}<strong>{int(count())}</strong></p>
      <p>{string("Doubled: ")}<strong>{int(doubled())}</strong></p>
      <p>{string("Tripled: ")}<strong>{int(tripled())}</strong></p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
      <p className="note">
        {string("Memos track signal and update reactively")}
      </p>
    </Section>
  }
}

// ============================================
// TEST 3: BROKEN - Eager evaluation
// ============================================
module BrokenEager = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // BUG: This reads the signal ONCE when component renders
    // The value is captured, not reactive
    let capturedValue = count()
    let eagerDoubled = capturedValue * 2

    <Section title="3. BROKEN: Eager Evaluation (will NOT update)">
      <p>{string("Reactive count: ")}<strong>{int(count())}</strong></p>
      <p className="broken">{string("Captured value: ")}<strong>{int(capturedValue)}</strong></p>
      <p className="broken">{string("Eager doubled: ")}<strong>{int(eagerDoubled)}</strong></p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
      <p className="note">
        {string("capturedValue reads signal outside tracking context - static!")}
      </p>
    </Section>
  }
}

// ============================================
// TEST 3b: FIXED with lazy - Deferred evaluation
// ============================================
module FixedLazy = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // FIX: Use lazy* helpers to defer signal reads
    // These compile to () => expr which Solid treats as reactive
    let lazyDoubled = () => count() * 2

    <Section title="3b. FIXED: Lazy Evaluation (SHOULD work)">
      <p>{string("Reactive count: ")}<strong>{int(count())}</strong></p>
      <p className="fixed">{string("Lazy doubled: ")}<strong>{lazyInt(() => count() * 2)}</strong></p>
      <p className="fixed">{string("Via variable: ")}<strong>{lazyInt(lazyDoubled)}</strong></p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
      <p className="note">
        {string("lazyInt(() => expr) defers evaluation - Solid tracks it reactively")}
      </p>
    </Section>
  }
}

// ============================================
// TEST 4: Conditional rendering with Show
// ============================================
module ConditionalShow = {
  @jsx.component
  let make = () => {
    let (visible, setVisible) = createSignal(true)
    let (count, setCount) = createSignal(0)

    <Section title="4. Conditional with Show (SHOULD work)">
      <button onClick={_ => setVisible(prev => !prev)}>
        {string(visible() ? "Hide" : "Show")}
      </button>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
      <SolidJSX.Show when_={visible()} fallback_={string("Hidden")}>
        {_ => <p>{string("Count: ")}<strong>{int(count())}</strong></p>}
      </SolidJSX.Show>
    </Section>
  }
}

// ============================================
// TEST 5: List rendering with For
// ============================================
module ListFor = {
  @jsx.component
  let make = () => {
    let (items, setItems) = createSignal(["A", "B", "C"])

    let addItem = _ => {
      setItems(prev => Array.concat(prev, [String.make(Array.length(prev))]))
    }

    <Section title="5. List with For (SHOULD work)">
      <button onClick=addItem>{string("Add Item")}</button>
      <ul>
        <SolidJSX.For each_={items()} fallback_={string("Empty")}>
          {(item, _i) => <li>{string(item)}</li>}
        </SolidJSX.For>
      </ul>
    </Section>
  }
}

// ============================================
// TEST 6: Effect tracking
// ============================================
module EffectTracking = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)
    let (log, setLog) = createSignal(["Initial"])

    // This effect should run whenever count changes
    createEffect(() => {
      let current = count()
      setLog(prev => Array.concat(prev, ["Effect ran: count = " ++ Int.toString(current)]))
    })

    <Section title="6. Effect Tracking (SHOULD work)">
      <p>{string("Count: ")}<strong>{int(count())}</strong></p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
      <div className="log-box">
        <SolidJSX.For each_={log()} fallback_={null}>
          {(entry, _i) => <div className="log-entry">{string(entry)}</div>}
        </SolidJSX.For>
      </div>
    </Section>
  }
}

// ============================================
// TEST 7: Nested component prop updates
// ============================================
module ChildDisplay = {
  @jsx.component
  let make = (~value: int, ()) => {
    <span className="highlight">
      {string("Received: ")}{int(value)}
    </span>
  }
}

module NestedProps = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    <Section title="7. Nested Component Props (SHOULD work)">
      <p>{string("Parent count: ")}<strong>{int(count())}</strong></p>
      <p>{string("Child: ")}<ChildDisplay value={count()} /></p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
      <p className="note">
        {string("Child should update when parent signal changes")}
      </p>
    </Section>
  }
}

// ============================================
// TEST 8: Batch updates
// ============================================
module BatchUpdates = {
  @jsx.component
  let make = () => {
    let (a, setA) = createSignal(0)
    let (b, setB) = createSignal(0)
    let renderCount = createSignal(0)

    // Track renders
    let (_, setRenderCount) = renderCount
    createEffect(() => {
      let _ = a() + b()  // Track both
      setRenderCount(prev => prev + 1)
    })

    let incrementBoth = _ => {
      batch(() => {
        setA(prev => prev + 1)
        setB(prev => prev + 1)
      })
    }

    let incrementSeparate = _ => {
      setA(prev => prev + 1)
      setB(prev => prev + 1)
    }

    <Section title="8. Batch Updates">
      <p>{string("A: ")}{int(a())}{string(", B: ")}{int(b())}</p>
      <p>{string("Effect runs: ")}{int(fst(renderCount)())}</p>
      <button onClick=incrementBoth>{string("Batch Increment")}</button>
      <button onClick=incrementSeparate>{string("Separate Increment")}</button>
      <p className="note">
        {string("Batch should trigger effect once, separate twice")}
      </p>
    </Section>
  }
}

// ============================================
// Main test component
// ============================================
@jsx.component
let make = () => {
  <div className="container">
    <h1>{string("Solid.js Reactivity Test Suite")}</h1>
    <p className="subtitle">
      {string("Click buttons and observe which sections update correctly.")}
    </p>

    <BasicSignal />
    <DerivedMemo />
    <BrokenEager />
    <FixedLazy />
    <ConditionalShow />
    <ListFor />
    <EffectTracking />
    <NestedProps />
    <BatchUpdates />
  </div>
}
