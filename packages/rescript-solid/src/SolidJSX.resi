open Solid

module Show: {
  type props<'a> = {
    @as("when") when_: 'a,
    @as("fallback") fallback_?: element,
    children: 'a => element,
  }
  @module("solid-js")
  external make: Jsx.component<props<'a>> = "Show"
}

module ShowOption: {
  @jsx.component
  let make: (~when_: option<'a>, ~fallback: element=?, ~children: 'a => element, unit) => element
}

let ppxDefer: (unit => element) => element

module For: {
  type props<'a> = {
    @as("each") each_: array<'a>,
    @as("fallback") fallback_?: element,
    children: ('a, accessor<int>) => element,
  }
  @module("solid-js")
  external make: Jsx.component<props<'a>> = "For"
}

module Index: {
  type props<'a> = {
    @as("each") each_: array<'a>,
    @as("fallback") fallback_?: element,
    children: (accessor<'a>, int) => element,
  }
  @module("solid-js")
  external make: Jsx.component<props<'a>> = "Index"
}

module Switch: {
  type props = {
    @as("fallback") fallback_?: element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "Switch"
}

module Match: {
  type props<'a> = {
    @as("when") when_: 'a,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props<'a>> = "Match"
}

module ErrorBoundary: {
  type props = {
    @as("fallback") fallback: (JsError.t, accessor<unit => unit>) => element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "ErrorBoundary"
}

module Suspense: {
  type props = {
    @as("fallback") fallback_?: element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "Suspense"
}

module SuspenseList: {
  type props = {
    children: element,
    revealOrder: [#forwards | #backwards | #together],
    tail: option<[#collapsed | #hidden]>,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "SuspenseList"
}

module Portal: {
  type props = {
    mount: option<Dom.element>,
    children: element,
  }
  @module("solid-js/web")
  external make: Jsx.component<props> = "Portal"
}

module Dynamic: {
  @module("solid-js/web")
  external make: Jsx.component<{..}> = "Dynamic"
}

module Scope: {
  @jsx.component
  let make: (~children: unit => element, unit) => element
}

module NoHydration: {
  type props = {children: element}
  @module("solid-js/web")
  external make: Jsx.component<props> = "NoHydration"
}
