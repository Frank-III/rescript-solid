open Solid
module Show = SolidJSX.Show
module For = SolidJSX.For

@jsx.component
let make = () => {
  let (showCounter, setShowCounter) = createSignal(true)
  let (items, _setItems) = createSignal(["Apple", "Banana", "Orange"])
  createEffect(() => Console.log("Counter visibility changed: " ++ (showCounter() ? "visible" : "hidden")))
  <div>
    <h1>{string("ReScript + Solid.js Example")}</h1>
    <div>
      <button onClick={_ => setShowCounter(prev => !prev)}>{string(showCounter() ? "Hide Counter" : "Show Counter")}</button>
    </div>
    <Show when_={showCounter()} fallback_={string("Counter is hidden")}>
      {_ => <Counter initialCount=10 />}
    </Show>
    <hr />
    <h2>{string("List Example")}</h2>
    <For each_={items()} fallback_={null}>{(item, _i) => <div>{string(item)}</div>}</For>
  </div>
}

