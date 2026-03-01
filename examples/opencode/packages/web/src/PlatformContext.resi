open Solid

type t = {
  platform: string,
  version: option<string>,
  openLink: string => unit,
  back: unit => unit,
  forward: unit => unit,
  restart: unit => unit,
  getDefaultServerUrl: unit => option<string>,
  setDefaultServerUrl: string => unit,
}

let web: (~version: string=?, unit) => t
let use: unit => t

@react.component
let make: (~value: t, ~children: element) => element
