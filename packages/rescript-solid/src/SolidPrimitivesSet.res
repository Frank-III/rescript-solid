type reactiveSet<'value>
type reactiveWeakSet<'value>

@new
@module("@solid-primitives/set")
external makeReactiveSet: unit => reactiveSet<'value> = "ReactiveSet"

@new
@module("@solid-primitives/set")
external makeReactiveSetFromArray: array<'value> => reactiveSet<'value> = "ReactiveSet"

@send
external add: (reactiveSet<'value>, 'value) => reactiveSet<'value> = "add"

@send
external delete: (reactiveSet<'value>, 'value) => bool = "delete"

@send
external has: (reactiveSet<'value>, 'value) => bool = "has"

@send
external clear: reactiveSet<'value> => unit = "clear"

@get
external size: reactiveSet<'value> => int = "size"

@new
@module("@solid-primitives/set")
external makeReactiveWeakSet: unit => reactiveWeakSet<'value> = "ReactiveWeakSet"

@send
external addWeak: (reactiveWeakSet<'value>, 'value) => reactiveWeakSet<'value> = "add"

@send
external deleteWeak: (reactiveWeakSet<'value>, 'value) => bool = "delete"

@send
external hasWeak: (reactiveWeakSet<'value>, 'value) => bool = "has"
