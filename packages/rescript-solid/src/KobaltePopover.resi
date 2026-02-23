open Solid

module Root: {
  type props = {
    @as("open") open_?: bool,
    defaultOpen?: bool,
    @as("onOpenChange") onOpenChange?: bool => unit,
    id?: string,
    modal?: bool,
    preventScroll?: bool,
    forceMount?: bool,
    placement?: string,
    gutter?: int,
    flip?: bool,
    shift?: bool,
    slide?: bool,
    overlap?: bool,
    sameWidth?: bool,
    fitViewport?: bool,
    hideWhenDetached?: bool,
    detachedPadding?: int,
    arrowPadding?: int,
    anchorRef?: accessor<Dom.element>,
    className?: string,
    children: element,
  }

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "Root"
}

module Trigger: {
  type props = {className?: string, children: element}

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "Trigger"
}

module Anchor: {
  type props = {className?: string, children?: element}

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "Anchor"
}

module Portal: {
  type props = {children: element}

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "Portal"
}

module Content: {
  type props = {className?: string, children: element}

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "Content"
}

module Arrow: {
  type props = {className?: string}

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "Arrow"
}

module Title: {
  type props = {className?: string, children: element}

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "Title"
}

module Description: {
  type props = {className?: string, children: element}

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "Description"
}

module CloseButton: {
  type props = {className?: string, children: element}

  @module("@kobalte/core/popover")
  external make: Jsx.component<props> = "CloseButton"
}
