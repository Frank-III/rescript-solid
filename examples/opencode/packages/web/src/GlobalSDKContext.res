open Solid

type t = {
  client: accessor<OpencodeClient.t>,
}

let defaultClient = () => OpencodeClient.make(~serverUrl="", ())

let defaultValue: t = {
  client: defaultClient,
}

let context = createContext(defaultValue)

let use = () => useContext(context)

@jsx.component
let make = (~value: t, ~children: element) => {
  let providerComponent = ContextSupport.provider(context)
  providerComponent({value: value, children: children})
}
