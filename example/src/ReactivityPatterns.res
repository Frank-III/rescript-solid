// Examples of CORRECT reactive patterns in Solid.js with ReScript

open Solid

// ✅ CORRECT: Signal values accessed inside JSX
module CorrectSignalAccess = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    <div>
      <h3>{string("✅ Correct Signal Access")}</h3>
      <p>{string("Count: ")}{int(count())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ✅ CORRECT: Using createMemo for derived state
module CorrectDerivedState = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)
    let doubled = createMemo(() => count() * 2)
    let quadrupled = createMemo(() => doubled() * 2)

    <div>
      <h3>{string("✅ Correct Derived State with Memos")}</h3>
      <p>{string("Count: ")}{int(count())}</p>
      <p>{string("Doubled: ")}{int(doubled())}</p>
      <p>{string("Quadrupled: ")}{int(quadrupled())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ✅ CORRECT: Using createEffect for side effects
module CorrectEffect = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    createEffect(() => {
      Console.log("Count changed to: " ++ Int.toString(count()))
    })

    <div>
      <h3>{string("✅ Correct Effect Usage")}</h3>
      <p>{string("Count: ")}{int(count())}{string(" (check console)")}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ✅ CORRECT: Passing signals to child components correctly
module CorrectPropsUsage = {
  module Child = {
    @jsx.component
    let make = (~count: unit => int, ~onIncrement: unit => unit, ()) => {
      // ✅ Call the accessor inside JSX
      <div>
        <p>{string("Child count: ")}{int(count())}</p>
        <button onClick={_ => onIncrement()}>{string("Increment from Child")}</button>
      </div>
    }
  }

  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    <div>
      <h3>{string("✅ Correct Props Passing")}</h3>
      <Child count={count} onIncrement={() => setCount(prev => prev + 1)} />
    </div>
  }
}

// ✅ CORRECT: Array mapping with signals
module CorrectArrayMapping = {
  type todo = {id: int, text: string, completed: bool}

  @jsx.component
  let make = () => {
    let (todos, setTodos) = createSignal([
      {id: 1, text: "Learn ReScript", completed: false},
      {id: 2, text: "Learn Solid.js", completed: false},
    ])

    let toggleTodo = (id: int) => {
      setTodos(prevTodos =>
        prevTodos->Array.map(todo =>
          if todo.id === id {
            {...todo, completed: !todo.completed}
          } else {
            todo
          }
        )
      )
    }

    module For = SolidJSX.For

    <div>
      <h3>{string("✅ Correct Array Mapping")}</h3>
      <For each_={todos()}>
        {(todo, _i) =>
          <div>
            <input
              type_="checkbox"
              checked={todo.completed}
              onChange={_ => toggleTodo(todo.id)}
            />
            {string(todo.text)}
          </div>
        }
      </For>
    </div>
  }
}

// ✅ CORRECT: Using untrack when you want to break reactivity intentionally
module CorrectUntrack = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)
    let (lastEvenCount, setLastEvenCount) = createSignal(0)

    createEffect(() => {
      let currentCount = count()
      if mod(currentCount, 2) === 0 {
        // ✅ Use untrack to read lastEvenCount without creating a dependency
        let prev = untrack(() => lastEvenCount())
        Console.log("Previous even: " ++ Int.toString(prev) ++ ", Current even: " ++ Int.toString(currentCount))
        setLastEvenCount(_ => currentCount)
      }
    })

    <div>
      <h3>{string("✅ Correct Untrack Usage")}</h3>
      <p>{string("Count: ")}{int(count())}</p>
      <p>{string("Last Even Count: ")}{int(lastEvenCount())}</p>
      <button onClick={_ => setCount(prev => prev + 1)}>
        {string("Increment")}
      </button>
    </div>
  }
}

// ✅ CORRECT: Batch updates together
module CorrectBatch = {
  @jsx.component
  let make = () => {
    let (firstName, setFirstName) = createSignal("John")
    let (lastName, setLastName) = createSignal("Doe")

    let fullName = createMemo(() => firstName() ++ " " ++ lastName())

    createEffect(() => {
      Console.log("Full name changed to: " ++ fullName())
    })

    let updateName = () => {
      // ✅ Batch prevents multiple effect runs
      batch(() => {
        setFirstName(_ => "Jane")
        setLastName(_ => "Smith")
      })
    }

    <div>
      <h3>{string("✅ Correct Batch Usage")}</h3>
      <p>{string("Full Name: ")}{string(fullName())}</p>
      <button onClick={_ => updateName()}>{string("Change Name (batched)")}</button>
    </div>
  }
}

// ✅ CORRECT: Cleanup in effects
module CorrectCleanup = {
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    createEffect(() => {
      let interval = setInterval(() => {
        setCount(prev => prev + 1)
      }, 1000)

      // ✅ Cleanup the interval
      onCleanup(() => {
        clearInterval(interval)
      })
    })

    <div>
      <h3>{string("✅ Correct Cleanup in Effects")}</h3>
      <p>{string("Auto-incrementing count: ")}{int(count())}</p>
    </div>
  }
}

// Main component showcasing all patterns
@jsx.component
let make = () => {
  <div>
    <h1>{string("✅ Correct Reactive Patterns")}</h1>
    <p>{string("These examples demonstrate CORRECT usage of Solid.js reactivity")}</p>
    <hr />
    <CorrectSignalAccess />
    <hr />
    <CorrectDerivedState />
    <hr />
    <CorrectEffect />
    <hr />
    <CorrectPropsUsage />
    <hr />
    <CorrectArrayMapping />
    <hr />
    <CorrectUntrack />
    <hr />
    <CorrectBatch />
    <hr />
    <CorrectCleanup />
  </div>
}
