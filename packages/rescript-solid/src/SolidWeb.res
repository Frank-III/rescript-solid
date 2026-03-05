// Solid.js Web-specific bindings

open Solid

// Render functions
@module("@solidjs/web")
external render: (unit => element, Dom.element) => (unit => unit) = "render"

@module("@solidjs/web")
external hydrate: (unit => element, Dom.element) => (unit => unit) = "hydrate"

@module("@solidjs/web")
external renderToString: (unit => element) => string = "renderToString"

@module("@solidjs/web")
external renderToStringAsync: (unit => element) => promise<string> = "renderToStringAsync"

@module("@solidjs/web")
external renderToStream: (unit => element) => {..} = "renderToStream"

// isServer check
@module("@solidjs/web")
external isServer: bool = "isServer"

