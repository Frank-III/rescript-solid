open Solid

module Root = {
  type orientation = [#horizontal | #vertical]
  type activationMode = [#automatic | #manual]

  type props = {
    value?: string,
    defaultValue?: string,
    @as("onChange") onChange?: string => unit,
    orientation?: orientation,
    activationMode?: activationMode,
    className?: string,
    children: element,
  }

  @module("@kobalte/core/tabs")
  external make: Jsx.component<props> = "Root"
}

module List = {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/tabs")
  external make: Jsx.component<props> = "List"
}

module Trigger = {
  type props = {
    value: string,
    disabled?: bool,
    className?: string,
    children: element,
  }

  @module("@kobalte/core/tabs")
  external make: Jsx.component<props> = "Trigger"
}

module Content = {
  type props = {
    value: string,
    forceMount?: bool,
    className?: string,
    children: element,
  }

  @module("@kobalte/core/tabs")
  external make: Jsx.component<props> = "Content"
}

module Indicator = {
  type props = {
    className?: string,
    children?: element,
  }

  @module("@kobalte/core/tabs")
  external make: Jsx.component<props> = "Indicator"
}
