open Solid
module Show = SolidJSX.Show
module ErrorBoundary = SolidJSX.ErrorBoundary
module Portal = SolidJSX.Portal

module Thrower = {
  @jsx.component
  let make = (~shouldThrow: bool, ()) => {
    if shouldThrow { JsError.throwWithMessage("Boom!") };
    <div> {string("All good")} </div>
  }
}

@val external setTimeout: (unit => unit, int) => int = "setTimeout"

@jsx.component
let make = () => {
  // Fake network with resource + Show
  let fetchGreeting = () => {
    Promise.make((resolve, _reject) => { let _ = setTimeout(() => resolve("Hello from network"), 600) })
  }
  let (greeting, _actions) = createResource(fetchGreeting)
  
  <div>
    <h3> {string("Resource + Show")} </h3>
    <Show when_={greeting()} fallback_={string("Loading...")}>
      {value => switch value { | Some(text) => <div> {string(text)} </div> | None => string("") }}
    </Show>
    
    <hr />
    <h3> {string("Portal")} </h3>
    {switch Document.getElementById("portal-root") {
     | Some(mount) => <Portal mount={Some(mount)}><div> {string("I am in a portal")} </div></Portal>
     | None => <div> {string("No portal root")} </div>
    }}

    <hr />
    <h3> {string("Memo + Effect")} </h3>
    {
      let (n, setN) = createSignal(1)
      let doubled = createMemo(() => n() * 2)
      createEffect(() => Console.log("n=" ++ Belt.Int.toString(n()) ++ ", doubled=" ++ Belt.Int.toString(doubled())))
      <div>
        <button onClick={_ => setN(prev => prev + 1)}> {string("Inc")} </button>
        <div>
          {string("n=")}{int(n())}{string(", doubled=")}{int(doubled())}
        </div>
      </div>
    }

    <hr />
    <h3> {string("ErrorBoundary")} </h3>
    {
      let (shouldThrow, setShouldThrow) = createSignal(false)
      <div>
        <button onClick={_ => setShouldThrow(prev => !prev)}> {string("Toggle Error")} </button>
        <ErrorBoundary fallback={(e, _reset) => <div> {string("Error: " ++ JsError.message(e))} </div>}>
          <Thrower shouldThrow={shouldThrow()} />
        </ErrorBoundary>
      </div>
    }
  </div>
}

