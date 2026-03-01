open Solid

type t = {
  activeServer: accessor<string>,
  serverDraft: accessor<string>,
  setServerDraft: string => unit,
  applyServer: unit => unit,
  resetServer: unit => unit,
  refresh: unit => unit,
}

let emptyValue: t = {
  activeServer: () => "",
  serverDraft: () => "",
  setServerDraft: _ => (),
  applyServer: () => (),
  resetServer: () => (),
  refresh: () => (),
}

let context = createContext(emptyValue)

let use = () => useContext(context)

@jsx.component
let make = (~value: t, ~children: element) => {
  let providerComponent = ContextSupport.provider(context)
  providerComponent({value: value, children: children})
}
