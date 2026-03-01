open Solid

type t = {
  activeServer: accessor<string>,
  serverDraft: accessor<string>,
  setServerDraft: string => unit,
  applyServer: unit => unit,
  resetServer: unit => unit,
  refresh: unit => unit,
}

let use: unit => t

@react.component
let make: (~value: t, ~children: element) => element
