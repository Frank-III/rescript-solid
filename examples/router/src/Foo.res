open Solid
module R = SolidRouter

module P = {
  type t = {"any": string}
}
module Params = R.MakeParams(P)

@jsx.component
let make = () => {
  let p = Params.useParams()
  <div>
    <h2> {string("Foo wildcard")} </h2>
    <p> {string(p["any"])} </p>
  </div>
}
