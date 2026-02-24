type triggerCache<'key>

@module("@solid-primitives/trigger")
external createTrigger: unit => (unit => unit, unit => unit) = "createTrigger"

@module("@solid-primitives/trigger")
external createTriggerCache: unit => (
  'key => unit,
  'key => unit,
  unit => unit,
) = "createTriggerCache"
