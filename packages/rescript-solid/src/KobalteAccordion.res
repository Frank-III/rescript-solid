open Solid

module Root = {
  type props = {
    value?: string,
    defaultValue?: string,
    @as("onChange") onChange?: string => unit,
    multiple?: bool,
    collapsible?: bool,
    className?: string,
    children: element,
  }

  @module("@kobalte/core/accordion")
  external make: Jsx.component<props> = "Root"
}

module Item = {
  type props = {
    value: string,
    disabled?: bool,
    className?: string,
    children: element,
  }

  @module("@kobalte/core/accordion")
  external make: Jsx.component<props> = "Item"
}

module Header = {
  type props = {className?: string, children: element}

  @module("@kobalte/core/accordion")
  external make: Jsx.component<props> = "Header"
}

module Trigger = {
  type props = {className?: string, children: element}

  @module("@kobalte/core/accordion")
  external make: Jsx.component<props> = "Trigger"
}

module Content = {
  type props = {className?: string, children: element}

  @module("@kobalte/core/accordion")
  external make: Jsx.component<props> = "Content"
}
