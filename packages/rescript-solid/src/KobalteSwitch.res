open Solid

module Root = {
  type props = {
    checked?: bool,
    defaultChecked?: bool,
    disabled?: bool,
    readOnly?: bool,
    required?: bool,
    value?: string,
    name?: string,
    @as("onChange") onChange?: bool => unit,
    className?: string,
    children: element,
  }
  @module("@kobalte/core/switch")
  external make: Jsx.component<props> = "Root"
}

module Input = {
  type props = {
    className?: string,
  }
  @module("@kobalte/core/switch")
  external make: Jsx.component<props> = "Input"
}

module Control = {
  type props = {
    className?: string,
    children?: element,
  }
  @module("@kobalte/core/switch")
  external make: Jsx.component<props> = "Control"
}

module Label = {
  type props = {
    className?: string,
    children: element,
  }
  @module("@kobalte/core/switch")
  external make: Jsx.component<props> = "Label"
}

module Thumb = {
  type props = {
    className?: string,
  }
  @module("@kobalte/core/switch")
  external make: Jsx.component<props> = "Thumb"
}

module Description = {
  type props = {
    className?: string,
    children: element,
  }
  @module("@kobalte/core/switch")
  external make: Jsx.component<props> = "Description"
}

module ErrorMessage = {
  type props = {
    className?: string,
    children: element,
  }
  @module("@kobalte/core/switch")
  external make: Jsx.component<props> = "ErrorMessage"
}
