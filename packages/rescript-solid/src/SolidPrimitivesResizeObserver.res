open Solid

type element
type domRectReadOnly
type resizeObserverEntry
type resizeObserverController

type resizeObserverOptions = {
  box?: string,
}

type size = {
  width: float,
  height: float,
}

type nullableSize = {
  width: Nullable.t<float>,
  height: Nullable.t<float>,
}

@module("@solid-primitives/resize-observer")
external makeResizeObserver: (
  (domRectReadOnly, element, resizeObserverEntry) => unit,
  option<resizeObserverOptions>,
) => resizeObserverController = "makeResizeObserver"

@send
external observe: (resizeObserverController, element) => unit = "observe"

@send
external unobserve: (resizeObserverController, element) => unit = "unobserve"

@module("@solid-primitives/resize-observer")
external createResizeObserver: (
  ~target: 'target,
  ~onResize: (domRectReadOnly, element, resizeObserverEntry) => unit,
  ~options: resizeObserverOptions=?,
  unit,
) => unit = "createResizeObserver"

@module("@solid-primitives/resize-observer")
external getWindowSize: unit => size = "getWindowSize"

@module("@solid-primitives/resize-observer")
external createWindowSize: unit => size = "createWindowSize"

@module("@solid-primitives/resize-observer")
external useWindowSize: unit => size = "useWindowSize"

@module("@solid-primitives/resize-observer")
external getElementSize: option<element> => nullableSize = "getElementSize"

@module("@solid-primitives/resize-observer")
external createElementSizeFromElement: element => size = "createElementSize"

@module("@solid-primitives/resize-observer")
external createElementSizeFromMaybe: accessor<option<element>> => nullableSize =
  "createElementSize"
