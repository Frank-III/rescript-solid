// Solid.js Control Flow Components
// ReScript-friendly modules exposing `make` for JSX usage

open Solid

module Show = {
  type props<'a> = {
    @as("when") when_: 'a,
    @as("fallback") fallback_?: element,
    children: 'a => element,
  }
  @module("solid-js")
  external make: Jsx.component<props<'a>> = "Show"
}

module ShowOption = {
  @jsx.component
  let make = (~when_: option<'a>, ~fallback: element=?, ~children, ()) => {
    <Show.make when_={when_} fallback_={fallback->Option.getOr(Jsx.null)}>
      {opt =>
        switch opt {
        | Some(value) => children(value)
        | None => Jsx.null
        }
      }
    </Show.make>
  }
}

let ppxDefer = (children: unit => element) => {
  let memo = createMemo(children)
  memo()
}

module For = {
  type props<'a> = {
    @as("each") each_: array<'a>,
    @as("fallback") fallback_?: element,
    children: ('a, accessor<int>) => element,
  }
  @module("solid-js")
  external make: Jsx.component<props<'a>> = "For"
}

module Index = {
  type props<'a> = {
    @as("each") each_: array<'a>,
    @as("fallback") fallback_?: element,
    children: (accessor<'a>, int) => element,
  }
  @module("solid-js")
  external make: Jsx.component<props<'a>> = "Index"
}

module Switch = {
  type props = {
    @as("fallback") fallback_?: element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "Switch"
}

module Match = {
  type props<'a> = {
    @as("when") when_: 'a,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props<'a>> = "Match"
}

module ErrorBoundary = {
  type props = {
    @as("fallback") fallback: (JsError.t, accessor<unit => unit>) => element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "ErrorBoundary"
}

module Suspense = {
  type props = {
    @as("fallback") fallback_?: element,
    children: element,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "Suspense"
}

module SuspenseList = {
  type props = {
    children: element,
    revealOrder: [#forwards | #backwards | #together],
    tail: option<[#collapsed | #hidden]>,
  }
  @module("solid-js")
  external make: Jsx.component<props> = "SuspenseList"
}

module Portal = {
  type props = {
    mount: option<Dom.element>,
    children: element,
  }
  @module("solid-js/web")
  external make: Jsx.component<props> = "Portal"
}

module Dynamic = {
  @module("solid-js/web")
  external make: Jsx.component<{..}> = "Dynamic"
}

// Scope (optional): helper you can use in apps to isolate roots
module Scope = {
  @jsx.component
  let make = (~children: unit => element, ()) => {
    createRoot(_dispose => children())
  }
}

module NoHydration = {
  type props = {children: element}
  @module("solid-js/web")
  external make: Jsx.component<props> = "NoHydration"
}
