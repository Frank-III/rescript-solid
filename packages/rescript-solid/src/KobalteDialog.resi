open Solid

module Root: {
  type props = {
    @as("open") open_?: bool,
    defaultOpen?: bool,
    @as("onOpenChange") onOpenChange?: bool => unit,
    modal?: bool,
    preventScroll?: bool,
    forceMount?: bool,
    children: element,
  }

  @module("@kobalte/core/dialog")
  external make: Jsx.component<props> = "Root"
}

module Trigger: {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/dialog")
  external make: Jsx.component<props> = "Trigger"
}

module Portal: {
  type props = {children: element}

  @module("@kobalte/core/dialog")
  external make: Jsx.component<props> = "Portal"
}

module Overlay: {
  type props = {
    className?: string,
    children?: element,
  }

  @module("@kobalte/core/dialog")
  external make: Jsx.component<props> = "Overlay"
}

module Content: {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/dialog")
  external make: Jsx.component<props> = "Content"
}

module Title: {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/dialog")
  external make: Jsx.component<props> = "Title"
}

module Description: {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/dialog")
  external make: Jsx.component<props> = "Description"
}

module CloseButton: {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/dialog")
  external make: Jsx.component<props> = "CloseButton"
}
