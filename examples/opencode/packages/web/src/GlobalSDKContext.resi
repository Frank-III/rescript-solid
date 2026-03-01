open Solid

type t = {
  client: accessor<OpencodeClient.t>,
}

let use: unit => t

@react.component
let make: (~value: t, ~children: element) => element
