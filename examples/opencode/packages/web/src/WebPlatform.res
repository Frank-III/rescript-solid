type storage

let defaultServerStorageKey = "opencode.settings.dat:defaultServerUrl"

@val @scope("window")
external localStorageUnsafe: Nullable.t<storage> = "localStorage"

@send
external getItemUnsafe: (storage, string) => Nullable.t<string> = "getItem"

@send
external setItemUnsafe: (storage, string, string) => unit = "setItem"

@send
external removeItemUnsafe: (storage, string) => unit = "removeItem"

@val @scope("location")
external locationOrigin: string = "origin"

@val @scope("location")
external locationHostname: string = "hostname"

let getStorage = () => localStorageUnsafe->Nullable.toOption

let getDefaultServerUrl = () =>
  switch getStorage() {
  | None => None
  | Some(storage) =>
    try {
      switch storage->getItemUnsafe(defaultServerStorageKey)->Nullable.toOption {
      | Some(url) =>
        let normalized = url->String.trim
        if normalized == "" {
          None
        } else {
          Some(normalized)
        }
      | None => None
      }
    } catch {
    | _ => None
    }
  }

let setDefaultServerUrl = (value: string) => {
  let normalized = value->String.trim
  switch getStorage() {
  | None => ()
  | Some(storage) =>
    if normalized == "" {
      try storage->removeItemUnsafe(defaultServerStorageKey) catch {
      | _ => ()
      }
    } else {
      try storage->setItemUnsafe(defaultServerStorageKey, normalized) catch {
      | _ => ()
      }
    }
  }
}

let deriveDefaultServerUrl = () =>
  switch getDefaultServerUrl() {
  | Some(url) => url
  | _ =>
    if
      locationHostname->String.includes("opencode.ai")
      || locationHostname == "localhost"
      || locationHostname == "127.0.0.1"
    {
      "http://localhost:4096"
    } else {
      locationOrigin
    }
  }
