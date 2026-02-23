open Solid
module R = SolidRouter
module ShowOption = SolidJSX.ShowOption
module Show = SolidJSX.Show
module For = SolidJSX.For

type loadState =
  | Loading
  | Loaded(string)

@val external setTimeout: (unit => unit, int) => int = "setTimeout"

let loader = _prev => {
  Promise.make((resolve, _reject) => {
    let _ = setTimeout(() => resolve("Loaded from createAsync"), 400)
  })
}

@jsx.component
let make = () => {
  let data = R.Data.createAsyncSimple(loader)
  let (count, setCount) = createSignal(0)
  let (step, setStep) = createSignal(1)
  let (showDetails, setShowDetails) = createSignal(true)
  let (items, setItems) = createSignal(["Alpha", "Beta", "Gamma"])
  let (nextId, setNextId) = createSignal(1)
  let location = R.useLocation()

  let isEven = () => count() % 2 == 0
  let parityLabel = () => if isEven() { "even" } else { "odd" }
  let maybeMessage = () => if count() % 3 == 0 { Some("Multiple of 3") } else { None }
  let status = () => if count() == 0 { "zero" } else if count() <= 5 { "low" } else { "high" }
  let loadState = () => if isEven() { Loaded("Even count ready") } else { Loading }

  let addItem = _ => {
    let id = nextId()
    setNextId(_ => id + 1)
    setItems(prev => Array.concat(prev, ["Item " ++ id->Int.toString]))
  }

  let clearItems = _ => setItems(_ => [])

  let scoped = () => <p>{string("Scoped count: ")}{string(count()->Int.toString)}</p>

  <div>
    <h2>{string("Complex Reactivity")}</h2>
    <p>{string("Path: ")}{string(location.pathname)}</p>

    <section>
      <h3>{string("Async")}</h3>
      <ShowOption when_={data()} fallback={<p>{string("Loading...")}</p>}>
        {text => <p>{string(text)}</p>}
      </ShowOption>
    </section>

    <section>
      <h3>{string("Counters")}</h3>
      <p>{string("Count: ")}{string(count()->Int.toString)}</p>
      <p>{string("Step: ")}{string(step()->Int.toString)}</p>
      <button onClick={_ => setCount(prev => prev + step())}>{string("Increment")}</button>
      <button onClick={_ => setCount(prev => prev - step())}>{string("Decrement")}</button>
      <button onClick={_ => setCount(_ => 0)}>{string("Reset")}</button>
      <button onClick={_ => setStep(prev => prev + 1)}>{string("Step +1")}</button>
      <button onClick={_ => setStep(prev => if prev > 1 { prev - 1 } else { prev })}>
        {string("Step -1")}
      </button>
    </section>

    <section>
      <h3>{string("Derived")}</h3>
      <p>{string("Doubled: ")}{string((count() * 2)->Int.toString)}</p>
      <p>{string("Parity: ")}{string(parityLabel())}</p>
      <p>{string("Status: ")}{string(status())}</p>

      {@show
      switch status() {
      | "zero" => <p>{string("Start state")}</p>
      | "low" => <p>{string("Counting")}</p>
      | _ => <p>{string("High count")}</p>
      }}

      {@show
      switch loadState() {
      | Loaded(message) => <p>{string(message)}</p>
      | _ => <p>{string("Waiting for even count")}</p>
      }}

      {@show
      switch maybeMessage() {
      | Some(msg) => <p>{string(msg)}</p>
      | None => <p>{string("No multiple of 3 yet")}</p>
      }}
    </section>

    <section>
      <h3>{string("List")}</h3>
      <p>{string("Items: ")}{string(items()->Array.length->Int.toString)}</p>
      <button onClick={addItem}>{string("Add item")}</button>
      <button onClick={clearItems}>{string("Clear")}</button>
      <ul>
        <For each_={items()}>
          {(item, index) =>
            <li>
              {string(index()->Int.toString)}
              {string(": ")}
              {string(item)}
            </li>
          }
        </For>
      </ul>
    </section>

    <section>
      <h3>{string("Scoped")}</h3>
      <button onClick={_ => setShowDetails(prev => !prev)}>
        {string(showDetails() ? "Hide details" : "Show details")}
      </button>
      <Show when_={showDetails()}>
        {_ =>
          <div>
            <p>{string("Details visible")}</p>
            {scoped()}
          </div>
        }
      </Show>
    </section>
  </div>
}
