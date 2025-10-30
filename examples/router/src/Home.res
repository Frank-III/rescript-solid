open Solid
module R = SolidRouter

@val external setTimeout: (unit => unit, int) => int = "setTimeout"

let loader = _prev => {
  Promise.make((resolve, _reject) => {
    let _ = setTimeout(() => resolve("Loaded from createAsync"), 400)
  })
}

@jsx.component
let make = () => {
  let data = R.Data.createAsyncSimple(loader)
  let navigate = R.useNavigate()
  <div>
    <h2> {string("Home")} </h2>
    <p>
      <SolidJSX.Show when_={data()} fallback_={string("Loading...")}>
        {text =>
          switch text {
          | Some(text) => string(text)
          | None => string("Loading...")
          }}
      </SolidJSX.Show>
    </p>
    <R.Link href_="/user/alice"> {string("Go to Alice")} </R.Link>
    <button onClick={_ => navigate->R.navigateToPath("/user/bob", ())}> {string("Go to Bob (navigate)")} </button>
  </div>
}
