open Solid

module Root: {
  type props = {
    value?: string,
    defaultValue?: string,
    @as("onChange") onChange?: string => unit,
    placeholder?: string,
    multiple?: bool,
    disabled?: bool,
    className?: string,
    children: element,
  }

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "Root"
}

module Trigger: {
  type props = {className?: string, children: element}

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "Trigger"
}

module Value: {
  type props = {
    className?: string,
    children?: element,
  }

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "Value"
}

module Icon: {
  type props = {
    className?: string,
    children?: element,
  }

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "Icon"
}

module Portal: {
  type props = {children: element}

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "Portal"
}

module Content: {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "Content"
}

module Listbox: {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "Listbox"
}

module Item: {
  type props = {
    item: string,
    className?: string,
    children: element,
  }

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "Item"
}

module ItemLabel: {
  type props = {
    className?: string,
    children: element,
  }

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "ItemLabel"
}

module ItemIndicator: {
  type props = {
    className?: string,
    children?: element,
  }

  @module("@kobalte/core/select")
  external make: Jsx.component<props> = "ItemIndicator"
}
