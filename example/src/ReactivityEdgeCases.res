// Edge cases and limitations of ReScript + Solid.js reactivity
// Testing what actually breaks when ReScript compiles JSX

open Solid

// ❌ EDGE CASE 1: IIFE in JSX (Solid supports, ReScript might not)
module IIFEInJSX = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // In pure Solid.js, you can do: {(() => count() * 2)()}
    // But ReScript might compile this differently...

    // Let's try different approaches:
    let attemptIIFE = {
      // This might get lifted to outer scope
      (() => count() * 2)()
    }

    <div>
      <h3>{string("IIFE in JSX Test")}</h3>
      <p>{string("Attempt IIFE: ")}{int(attemptIIFE)}</p>
      <p>{string("Direct call: ")}{int(count() * 2)}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 2: Complex expressions lifted to outer scope
module ComplexExpressionsLifted = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // Will this be lifted?
    let complexCalc = {
      let doubled = count() * 2
      let tripled = count() * 3
      doubled + tripled
    }

    <div>
      <h3>{string("Complex Expression Lifting")}</h3>
      <p>{string("Complex calc: ")}{int(complexCalc)}</p>
      <p>{string("Count: ")}{int(count())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment - Does complexCalc update?")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 3: Inline conditionals with signal reads
module InlineConditionals = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // Multiple signal reads in ternary
    let result = count() > 5 ? count() * 2 : count() + 1

    <div>
      <h3>{string("Inline Conditionals")}</h3>
      <p>{string("Result (computed once): ")}{int(result)}</p>
      <p>{string("Result (inline): ")}{int(count() > 5 ? count() * 2 : count() + 1)}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 4: Pattern matching that reads signals
module PatternMatchingSignals = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // Pattern match reading signal
    let message = switch count() {
    | n if n > 10 => "High"
    | n if n > 5 => "Medium"
    | _ => "Low"
    }

    <div>
      <h3>{string("Pattern Matching with Signals")}</h3>
      <p>{string("Message (computed once): ")}{string(message)}</p>
      <p>
        {string("Message (inline): ")}
        {string(
          switch count() {
          | n if n > 10 => "High"
          | n if n > 5 => "Medium"
          | _ => "Low"
          },
        )}
      </p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 5: Array operations in JSX body
module ArrayOpsInJSX = {
  @jsx.component
  let make = () => {
    let (items, setItems) = createSignal([1, 2, 3])

    // Will this mapping be reactive?
    let mapped = items()->Array.map(x => x * 2)

    module For = SolidJSX.For

    <div>
      <h3>{string("Array Operations in JSX")}</h3>
      <p>{string("Mapped length (computed once): ")}{int(Array.length(mapped))}</p>
      <p>{string("Items count: ")}{int(Array.length(items()))}</p>
      <For each_={items()->Array.map(x => x * 2)}>
        {(item, _i) => <span>{int(item)}{string(" ")}</span>}
      </For>
      <button onClick={_ => setItems(prev => Array.concat(prev, [Array.length(prev) + 1]))}>
        {string("Add Item")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 6: Nested reactive contexts
module NestedReactiveContexts = {
  @jsx.component
  let make = () => {
    let (outer, setOuter) = createSignal(0)
    let (inner, setInner) = createSignal(0)

    // Memo depending on multiple signals
    let combined = createMemo(() => outer() + inner())

    // What if we read combined() outside JSX?
    let snapshot = combined()

    <div>
      <h3>{string("Nested Reactive Contexts")}</h3>
      <p>{string("Outer: ")}{int(outer())}</p>
      <p>{string("Inner: ")}{int(inner())}</p>
      <p>{string("Combined (memo): ")}{int(combined())}</p>
      <p>{string("Snapshot: ")}{int(snapshot)}</p>
      <button onClick={_ => setOuter(prev => prev + 1)}>
        {string("Inc Outer")}
      </button>
      <button onClick={_ => setInner(prev => prev + 1)}>
        {string("Inc Inner")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 7: Object/Record creation with signal values
module ObjectCreationWithSignals = {
  @jsx.component
  let make = () => {
    let (firstName, setFirstName) = createSignal("John")
    let (lastName, setLastName) = createSignal("Doe")

    // Creating object with signal values - captured once?
    let person = {
      "first": firstName(),
      "last": lastName(),
      "full": firstName() ++ " " ++ lastName(),
    }

    <div>
      <h3>{string("Object Creation with Signals")}</h3>
      <p>{string("Person.full (created once): ")}{string(person["full"])}</p>
      <p>{string("Direct concat: ")}{string(firstName() ++ " " ++ lastName())}</p>
      <button onClick={_ => setFirstName(_ => "Jane")}>
        {string("Change First Name")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 8: Function calls that read signals
module FunctionCallsWithSignals = {
  let computeExpensive = (n: int) => {
    Console.log("Computing expensive: " ++ Int.toString(n))
    n * n
  }

  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // Called once at component creation
    let result1 = computeExpensive(count())

    // Should we use a memo?
    let result2 = createMemo(() => computeExpensive(count()))

    <div>
      <h3>{string("Function Calls with Signals")}</h3>
      <p>{string("Result1 (called once): ")}{int(result1)}</p>
      <p>{string("Result2 (memo): ")}{int(result2())}</p>
      <p>{string("Result3 (inline): ")}{int(computeExpensive(count()))}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment - Check console")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 9: Closure scoping issues
module ClosureScoping = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    // Create a closure that captures signal value
    let getCapturedValue = () => {
      let captured = count() // Captured at closure creation
      () => captured
    }

    let closureValue = getCapturedValue()

    <div>
      <h3>{string("Closure Scoping")}</h3>
      <p>{string("Closure value: ")}{int(closureValue())}</p>
      <p>{string("Direct value: ")}{int(count())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 10: Multiple signal reads in one expression
module MultipleSignalReads = {
  @jsx.component
  let make = () => {
    let (a, setA) = createSignal(1)
    let (b, setB) = createSignal(2)
    let (c, setC) = createSignal(3)

    // Multiple reads - which ones get tracked?
    let sum = a() + b() + c()

    <div>
      <h3>{string("Multiple Signal Reads")}</h3>
      <p>{string("Sum (computed once): ")}{int(sum)}</p>
      <p>{string("Sum (inline): ")}{int(a() + b() + c())}</p>
      <button onClick={_ => setA(prev => prev + 1)}>
        {string("Inc A")}
      </button>
      <button onClick={_ => setB(prev => prev + 1)}>
        {string("Inc B")}
      </button>
      <button onClick={_ => setC(prev => prev + 1)}>
        {string("Inc C")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 11: String interpolation with signals
module StringInterpolation = {
  @jsx.component
  let make = () => {
    let (name, setName) = createSignal("World")
    let (count, setCount) = createSignal(0)

    // String concat with signals - captured?
    let greeting = "Hello " ++ name() ++ ", count: " ++ Int.toString(count())

    <div>
      <h3>{string("String Interpolation")}</h3>
      <p>{string("Greeting (created once): ")}{string(greeting)}</p>
      <p>
        {string("Greeting (inline): ")}
        {string("Hello " ++ name() ++ ", count: " ++ Int.toString(count()))}
      </p>
      <button onClick={_ => setName(_ => "Solid")}>
        {string("Change Name")}
      </button>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Inc Count")}
      </button>
    </div>
  }
}

// ❌ EDGE CASE 12: Optional chaining with signals
module OptionalChainingSignals = {
  type user = {name: string, age: option<int>}

  @jsx.component
  let make = () => {
    let (user, setUser) = createSignal({name: "Alice", age: Some(25)})

    // Optional access - captured?
    let age = user().age

    <div>
      <h3>{string("Optional Chaining")}</h3>
      <p>
        {string("Age (captured): ")}
        {switch age {
        | Some(n) => int(n)
        | None => string("N/A")
        }}
      </p>
      <p>
        {string("Age (inline): ")}
        {switch user().age {
        | Some(n) => int(n)
        | None => string("N/A")
        }}
      </p>
      <button onClick={_ => setUser(_ => {name: "Bob", age: Some(30)})}>
        {string("Change User")}
      </button>
      <button onClick={_ => setUser(_ => {name: "Charlie", age: None})}>
        {string("Clear Age")}
      </button>
    </div>
  }
}

// Main component showcasing all edge cases
@jsx.component
let make = () => {
  <div>
    <h1>{string("🔬 Reactivity Edge Cases & Limitations")}</h1>
    <p>
      {string("Testing ReScript compilation + Solid reactivity interactions")}
    </p>
    <p>
      <strong>{string("⚠️ Look for values that don't update when they should!")}</strong>
    </p>
    <hr />
    <IIFEInJSX />
    <hr />
    <ComplexExpressionsLifted />
    <hr />
    <InlineConditionals />
    <hr />
    <PatternMatchingSignals />
    <hr />
    <ArrayOpsInJSX />
    <hr />
    <NestedReactiveContexts />
    <hr />
    <ObjectCreationWithSignals />
    <hr />
    <FunctionCallsWithSignals />
    <hr />
    <ClosureScoping />
    <hr />
    <MultipleSignalReads />
    <hr />
    <StringInterpolation />
    <hr />
    <OptionalChainingSignals />
  </div>
}
