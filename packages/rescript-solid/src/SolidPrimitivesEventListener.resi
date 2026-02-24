open Solid

type eventTarget
type event
type handlersMap<'event> = dict<'event => unit>
type eventListenerOptions = {
  capture?: bool,
  passive?: bool,
  once?: bool,
}

let handlers: array<(string, 'event => unit)> => handlersMap<'event>

@val
external window: eventTarget = "window"

@module("@solid-primitives/event-listener")
external makeEventListener: (
  'target,
  string,
  'event => unit,
  option<eventListenerOptions>,
) => unit => unit = "makeEventListener"

@module("@solid-primitives/event-listener")
external createEventListener: (
  ~target: 'target,
  ~type_: string,
  ~handler: 'event => unit,
  ~options: eventListenerOptions=?,
  unit,
) => unit = "createEventListener"

@module("@solid-primitives/event-listener")
external createEventSignal: (
  'target,
  string,
  option<eventListenerOptions>,
) => accessor<'event> = "createEventSignal"

@module("@solid-primitives/event-listener")
external createEventListenerMap: (
  'target,
  handlersMap<'event>,
  option<eventListenerOptions>,
) => unit = "createEventListenerMap"

module WindowEventListener: {
  type props = {
    onMousemove?: event => unit,
    onClick?: event => unit,
    onKeydown?: event => unit,
  }

  @module("@solid-primitives/event-listener")
  external make: Jsx.component<props> = "WindowEventListener"
}

module DocumentEventListener: {
  type props = {
    onSelectionchange?: event => unit,
    onVisibilitychange?: event => unit,
    onClick?: event => unit,
  }

  @module("@solid-primitives/event-listener")
  external make: Jsx.component<props> = "DocumentEventListener"
}
