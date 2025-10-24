open Solid
module R = SolidRouter

@val external setTimeout: (unit => unit, int) => int = "setTimeout"

@jsx.component
let make = () => {
  let loader = _prev => {
    Promise.make((resolve, _reject) => { let _ = setTimeout(() => resolve("Loaded from createAsync"), 400) })
  }
  let data = R.Data.createAsyncSimple(loader)
  let navigate = R.useNavigate()
  <div>
    <h2>{string("Home")}</h2>
    <p>{switch data() { | Some(text) => string(text) | None => string("Loading...") }}</p>
    <R.Link href_="/user/alice">{string("Go to Alice")}</R.Link>
    <button onClick={_ => navigate("/user/bob")}>{string("Go to Bob (navigate)")}</button>
  </div>
}
