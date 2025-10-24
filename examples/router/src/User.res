open Solid
module R = SolidRouter

module P = { type t = {"name": string} }
module TypedParams = R.MakeParams(P)

@jsx.component
let make = () => {
  let params = TypedParams.useParams()
  let name = params["name"]
  <div>
    <h2>{string("User: ")}{string(name)}</h2>
  </div>
}
