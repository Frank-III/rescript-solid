open Solid
module R = SolidRouter

module P = { type t = { "id": option<string> } }
module Params = R.MakeParams(P)

@jsx.component
let make = () => {
  let p = Params.useParams()
  <div>
    <h2>{string("Stories")}</h2>
    <p>{string("id=")}{string(Option.getOr(p["id"], "none"))}</p>
  </div>
}
