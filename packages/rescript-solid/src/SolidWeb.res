// Solid.js Web-specific bindings

open Solid

// Render functions
@module("solid-js/web")
external render: (unit => element, Dom.element) => (unit => unit) = "render"

@module("solid-js/web")
external hydrate: (unit => element, Dom.element) => (unit => unit) = "hydrate"

@module("solid-js/web")
external renderToString: (unit => element) => string = "renderToString"

@module("solid-js/web")
external renderToStringAsync: (unit => element) => promise<string> = "renderToStringAsync"

@module("solid-js/web")
external renderToStream: (unit => element) => {..} = "renderToStream"

// isServer check
@module("solid-js/web")
external isServer: bool = "isServer"

