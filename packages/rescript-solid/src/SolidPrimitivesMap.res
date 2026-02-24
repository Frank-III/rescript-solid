type reactiveMap<'key, 'value>

@new
@module("@solid-primitives/map")
external makeReactiveMap: unit => reactiveMap<'key, 'value> = "ReactiveMap"

@new
@module("@solid-primitives/map")
external makeReactiveMapFromArray: array<('key, 'value)> => reactiveMap<'key, 'value> = "ReactiveMap"

@send
external set: (reactiveMap<'key, 'value>, 'key, 'value) => reactiveMap<'key, 'value> = "set"

@send
external has: (reactiveMap<'key, 'value>, 'key) => bool = "has"

@send
external delete: (reactiveMap<'key, 'value>, 'key) => bool = "delete"

@send
external clear: reactiveMap<'key, 'value> => unit = "clear"

@get
external size: reactiveMap<'key, 'value> => int = "size"
