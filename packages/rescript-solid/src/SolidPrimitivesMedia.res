open Solid

type mediaQueryList
type mediaQueryEvent

type size = {
  width: float,
  height: float,
}

@module("@solid-primitives/media")
external makeMediaQueryListener: (
  string,
  mediaQueryEvent => unit,
) => unit => unit = "makeMediaQueryListener"

@module("@solid-primitives/media")
external createMediaQuery: (string, option<bool>) => accessor<bool> = "createMediaQuery"

@module("@solid-primitives/media")
external createPrefersDark: option<bool> => accessor<bool> = "createPrefersDark"

@module("@solid-primitives/media")
external usePrefersDark: unit => accessor<bool> = "usePrefersDark"
