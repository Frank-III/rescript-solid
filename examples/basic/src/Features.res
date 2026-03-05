open Solid
module Show = SolidJSX.Show
module Loading = SolidJSX.Loading
module ErrorBoundary = SolidJSX.ErrorBoundary

module Thrower = {
  @jsx.component
  let make = (~shouldThrow: bool, ()) => {
    if shouldThrow {
      JsError.throwWithMessage("Boom!")
    }
    <div> {string("All good")} </div>
  }
}

@val external setTimeout: (unit => unit, int) => int = "setTimeout"

@jsx.component
let make = () => {
  // Fake network with async memo + Loading + isPending
  let fetchGreeting = () => {
    Promise.make((resolve, _reject) => {
      let _ = setTimeout(() => resolve("Hello from network"), 600)
    })
  }
  let greeting = createMemoAsync(fetchGreeting)
  let refreshing = () => isPending(() => greeting())

  <div>
    <h3> {string("Loading + isPending")} </h3>
    <button onClick={_ => refresh(greeting)}> {string("Refresh Greeting")} </button>
    <Show when_={refreshing()} fallback_={Jsx.null}>
      {_ => <div> {string("Refreshing...")} </div>}
    </Show>
    <Loading fallback_={string("Loading...")}>
      <div> {string(greeting())} </div>
    </Loading>

    <hr />
    <h3> {string("Memo + Effect")} </h3>
    {
      let (n, setN) = createSignal(1)
      let doubled = createMemo(() => n() * 2)
      createTrackEffect(() =>
        Console.log("n=" ++ Int.toString(n()) ++ ", doubled=" ++ Int.toString(doubled()))
      )
      <div>
        <button onClick={_ => setN(prev => prev + 1)}> {string("Inc")} </button>
        <div>
          {string("n=")}
          {int(n())}
          {string(", doubled=")}
          {int(doubled())}
        </div>
      </div>
    }

    <hr />
    <h3> {string("ErrorBoundary")} </h3>
    {
      let (shouldThrow, setShouldThrow) = createSignal(false)
      <div>
        <button onClick={_ => setShouldThrow(prev => !prev)}> {string("Toggle Error")} </button>
        <ErrorBoundary
          fallback={(e, _reset) => <div> {string("Error: " ++ JsError.message(e))} </div>}
        >
          <Thrower shouldThrow={shouldThrow()} />
        </ErrorBoundary>
      </div>
    }
  </div>
}
