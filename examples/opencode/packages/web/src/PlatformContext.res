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

@val @scope("window")
external openWindow: (string, string) => unit = "open"

type history

@val @scope("window")
external getHistory: history = "history"

@send
external historyBack: history => unit = "back"

@send
external historyForward: history => unit = "forward"

type location

@val @scope("window")
external getLocation: location = "location"

@send
external reloadPage: location => unit = "reload"

let defaultValue: t = {
  platform: "web",
  version: None,
  openLink: _ => (),
  back: () => (),
  forward: () => (),
  restart: () => (),
  getDefaultServerUrl: () => None,
  setDefaultServerUrl: _ => (),
}

let context = createContext(defaultValue)

let web = (~version: option<string>=?, ()): t => {
  let history = getHistory
  let location = getLocation

  {
    platform: "web",
    version,
    openLink: url => openWindow(url, "_blank"),
    back: () => history->historyBack,
    forward: () => history->historyForward,
    restart: () => location->reloadPage,
    getDefaultServerUrl: () => WebPlatform.getDefaultServerUrl(),
    setDefaultServerUrl: value => WebPlatform.setDefaultServerUrl(value),
  }
}

let use = () => useContext(context)

@jsx.component
let make = (~value: t, ~children: element) => {
  let providerComponent = ContextSupport.provider(context)
  providerComponent({value: value, children: children})
}
