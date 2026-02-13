// Examples of ANTI-PATTERNS that break Solid.js reactivity in ReScript

open Solid

// ❌ ANTI-PATTERN: Destructuring signals
module DestructuringSignals = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // ❌ BAD: Reading signal value outside reactive context
    let currentCount = count() // This reads once and never updates!

    <div>
      <h3>{string("❌ Destructuring Signals (BROKEN)")}</h3>
      <p>{string("Count (stale): ")}{int(currentCount)}</p>
      <p>{string("Count (correct): ")}{int(count())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment - First value won't update!")}
      </button>
    </div>
  }
}

// ❌ ANTI-PATTERN: Computing derived values without createMemo
module DerivingWithoutMemo = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // ❌ BAD: This recalculates on every render, not just when count changes
    // Also, this runs outside reactive context so it reads once
    let doubled = count() * 2

    // ✅ BETTER: Use createMemo
    let quadrupled = createMemo(() => count() * 4)

    <div>
      <h3>{string("❌ Deriving Without Memo (INEFFICIENT)")}</h3>
      <p>{string("Count: ")}{int(count())}</p>
      <p>{string("Doubled (broken): ")}{int(doubled)}</p>
      <p>{string("Quadrupled (correct): ")}{int(quadrupled())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment - Doubled won't update!")}
      </button>
    </div>
  }
}

// ❌ ANTI-PATTERN: Accessing signals in event handlers without wrapping
module SignalInEventHandler = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // ❌ BAD: Signal read captured at component creation time
    let handleClick = _ => {
      let current = count() // This captures the initial value!
      Console.log("Clicked at count: " ++ Int.toString(current))
      setCount(_ => current + 1) // This will always set to initial + 1
    }

    // ✅ BETTER: Read signal inside the handler
    let handleClickCorrect = _ => {
      let current = count() // This reads the current value
      Console.log("Clicked at count (correct): " ++ Int.toString(current))
      setCount(prev => prev + 1) // Or use updater function
    }

    <div>
      <h3>{string("❌ Signal in Event Handler (BROKEN)")}</h3>
      <p>{string("Count: ")}{int(count())}</p>
      <button onClick={handleClick}>
        {string("Broken - Sets to 1 always")}
      </button>
      <button onClick={handleClickCorrect}>
        {string("Correct - Increments properly")}
      </button>
    </div>
  }
}

// ❌ ANTI-PATTERN: Passing signal values instead of accessors
module PassingValues = {
  module Child = {
    // ❌ BAD: Receiving primitive instead of accessor
    @jsx.component
    let make = (~count: int, ()) => {
      <div>
        <p>{string("Child count (stale): ")}{int(count)}</p>
      </div>
    }
  }

  module CorrectChild = {
    // ✅ GOOD: Receiving accessor
    @jsx.component
    let make = (~count: unit => int, ()) => {
      <div>
        <p>{string("Child count (reactive): ")}{int(count())}</p>
      </div>
    }
  }

  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    <div>
      <h3>{string("❌ Passing Values Instead of Accessors")}</h3>
      <Child count={count()} /> /* ❌ Passes value, loses reactivity */
      <CorrectChild count={count} /> /* ✅ Passes accessor, maintains reactivity */
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment - Only second updates!")}
      </button>
    </div>
  }
}

// ❌ ANTI-PATTERN: Using Array methods that don't preserve reactivity
module ArrayMutations = {
  type item = {id: int, name: string}

  @jsx.component
  let make = () => {
    let (items, setItems) = createSignal([
      {id: 1, name: "Item 1"},
      {id: 2, name: "Item 2"},
    ])

    // ❌ BAD: Mutating the array directly
    let addItemBroken = () => {
      let currentItems = items()
      // Don't do this! It mutates the array without triggering updates
      // currentItems->Array.push({id: 3, name: "Item 3"})
      // setItems(_ => currentItems)

      // This also won't work as expected because we're reading once
      Console.log("Array length: " ++ Int.toString(Array.length(currentItems)))
    }

    // ✅ GOOD: Creating new array
    let addItemCorrect = () => {
      setItems(prev => Array.concat(prev, [{id: 3, name: "New Item"}]))
    }

    module For = SolidJSX.For

    <div>
      <h3>{string("❌ Array Mutations")}</h3>
      <For each_={items()}>
        {(item, _i) => <div>{string(item.name)}</div>}
      </For>
      <button onClick={_ => addItemBroken()}>
        {string("Add (broken - check console)")}
      </button>
      <button onClick={_ => addItemCorrect()}>
        {string("Add (correct)")}
      </button>
    </div>
  }
}

// ❌ ANTI-PATTERN: Creating effects inside JSX
module EffectsInJSX = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    <div>
      <h3>{string("❌ Creating Effects in JSX")}</h3>
      {
        // ❌ BAD: This creates a new effect on every render
        createEffect(() => {
          Console.log("This runs too often: " ++ Int.toString(count()))
        })
        null
      }
      <p>{string("Count: ")}{int(count())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ❌ ANTI-PATTERN: Conditional signal creation
module ConditionalSignals = {
  @jsx.component
  let make = (~useSignal: bool, ()) => {
    // ❌ BAD: Signals should always be created, not conditionally
    // This breaks the rules of hooks/signals
    let (count, setCount) = if useSignal {
      createSignal(0)
    } else {
      ((() => 0), (_ => ()))
    }

    <div>
      <h3>{string("❌ Conditional Signal Creation")}</h3>
      <p>{string("This can cause issues!")}</p>
      <p>{string("Count: ")}{int(count())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ❌ ANTI-PATTERN: Not using updater functions
module NoUpdaterFunction = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    let incrementTwiceBroken = _ => {
      // ❌ BAD: Both calls use the same current value
      setCount(_ => count() + 1)
      setCount(_ => count() + 1) // This reads count() again, which might still be the old value
    }

    let incrementTwiceCorrect = _ => {
      // ✅ GOOD: Using updater function
      setCount(prev => prev + 1)
      setCount(prev => prev + 1)
    }

    <div>
      <h3>{string("❌ Not Using Updater Functions")}</h3>
      <p>{string("Count: ")}{int(count())}</p>
      <button onClick={incrementTwiceBroken}>
        {string("Increment Twice (might be broken)")}
      </button>
      <button onClick={incrementTwiceCorrect}>
        {string("Increment Twice (correct)")}
      </button>
    </div>
  }
}

// ❌ ANTI-PATTERN: Reading signals outside reactive context without untrack
module ReadingOutsideContext = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // ❌ BAD: This reads the signal but creates no tracking dependency
    // because it's not in a reactive context
    let initialValue = count()

    createEffect(() => {
      // This effect only depends on count, not initialValue
      Console.log("Count: " ++ Int.toString(count()) ++ ", Initial: " ++ Int.toString(initialValue))
    })

    <div>
      <h3>{string("❌ Reading Outside Context")}</h3>
      <p>{string("Initial Value (stale): ")}{int(initialValue)}</p>
      <p>{string("Current Count: ")}{int(count())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment - Check console")}
      </button>
    </div>
  }
}

// Main component showcasing all anti-patterns
@jsx.component
let make = () => {
  <div>
    <h1>{string("❌ Anti-Patterns That Break Reactivity")}</h1>
    <p>{string("These examples demonstrate INCORRECT usage that breaks Solid.js reactivity")}</p>
    <p><strong>{string("⚠️ These are intentionally broken to illustrate what NOT to do!")}</strong></p>
    <hr />
    <DestructuringSignals />
    <hr />
    <DerivingWithoutMemo />
    <hr />
    <SignalInEventHandler />
    <hr />
    <PassingValues />
    <hr />
    <ArrayMutations />
    <hr />
    <EffectsInJSX />
    <hr />
    <ConditionalSignals useSignal={true} />
    <hr />
    <NoUpdaterFunction />
    <hr />
    <ReadingOutsideContext />
  </div>
}
