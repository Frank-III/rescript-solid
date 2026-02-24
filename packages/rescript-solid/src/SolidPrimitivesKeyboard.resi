open Solid

type keyboardEvent
type keyboardEventOrNull

type keyHoldOptions = {
  preventDefault?: bool,
}

type shortcutOptions = {
  preventDefault?: bool,
  requireReset?: bool,
}

@module("@solid-primitives/keyboard")
external useKeyDownEvent: unit => accessor<keyboardEventOrNull> = "useKeyDownEvent"

@module("@solid-primitives/keyboard")
external useKeyDownList: unit => accessor<array<string>> = "useKeyDownList"

@module("@solid-primitives/keyboard")
external useCurrentlyHeldKey: unit => accessor<option<string>> = "useCurrentlyHeldKey"

@module("@solid-primitives/keyboard")
external useKeyDownSequence: unit => accessor<array<array<string>>> = "useKeyDownSequence"

@module("@solid-primitives/keyboard")
external createKeyHold: (string, option<keyHoldOptions>) => accessor<bool> = "createKeyHold"

@module("@solid-primitives/keyboard")
external createShortcut: (
  array<string>,
  keyboardEventOrNull => unit,
  option<shortcutOptions>,
) => unit = "createShortcut"
