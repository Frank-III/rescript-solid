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
  let make: (
    ~when_: option<'a>,
    ~fallback: element=?,
    ~children: 'a => element,
    unit,
  ) => element
}

let ppxDefer: (unit => element) => element

module For: {
  type rawProps<'a> = {
    @as("each") each_: array<'a>,
    @as("fallback") fallback_?: element,
    @as("keyed") keyed_?: bool,
    children: (accessor<'a>, accessor<int>) => element,
  }

  module RawFor: {
    @module("solid-js")
    external make: Jsx.component<rawProps<'a>> = "For"
  }

  @jsx.component
  let make: (
    ~each_: array<'a>,
    ~fallback_: element=?,
    ~keyed_: bool=?,
    ~children: ('a, accessor<int>) => element,
    unit,
  ) => element
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

module Errored: {
  type props = {
    @as("fallback") fallback: (JsError.t, unit => unit) => element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "Errored"
}

module ErrorBoundary: {
  type props = {
    @as("fallback") fallback: (JsError.t, unit => unit) => element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "Errored"
}

module Loading: {
  type props = {
    @as("fallback") fallback_?: element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "Loading"
}

module Suspense: {
  type props = {
    @as("fallback") fallback_?: element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "Loading"
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
    mount: Dom.element,
    children: element,
  }
  @module("@solidjs/web")
  external make: Jsx.component<props> = "Portal"
}

module Dynamic: {
  @module("@solidjs/web")
  external make: Jsx.component<{..}> = "Dynamic"
}

module Scope: {
  @jsx.component
  let make: (~children: unit => element, unit) => element
}

module NoHydration: {
  type props = {children: element}
  @module("@solidjs/web")
  external make: Jsx.component<props> = "NoHydration"
}
