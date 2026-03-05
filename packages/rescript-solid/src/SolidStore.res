// Store and state management for Solid.js

// Store types
type store<'a> = 'a
type setStoreFunction<'a> = 'a => unit

// Create store
@module("solid-js")
external createStore: 'a => (store<'a>, setStoreFunction<'a>) = "createStore"

@module("solid-js")
external createStoreFromFn: ((unit => 'a), ~initialValue: 'a=?, unit) => (store<'a>, setStoreFunction<'a>) =
  "createStore"

@module("solid-js")
external createOptimisticStore: 'a => (store<'a>, setStoreFunction<'a>) = "createOptimisticStore"

@module("solid-js")
external createOptimisticStoreFromFn: (
  (unit => 'a),
  ~initialValue: 'a=?,
  unit,
) => (store<'a>, setStoreFunction<'a>) = "createOptimisticStore"

// Produce helper for immutable updates
@module("solid-js")
external produce: (store<'a> => unit) => store<'a> = "produce"

// Reconcile for efficient updates
@module("solid-js")
external reconcile: ('a, ~options: {..}=?, unit) => 'a = "reconcile"

// Unwrap store proxy
@module("solid-js")
external unwrap: store<'a> => 'a = "unwrap"

// Create mutable store
@module("solid-js")
external createMutable: 'a => store<'a> = "createMutable"

// Store setter patterns
module Setter = {
  // Direct value setter
  external setValue: 'a => 'a = "%identity"
  
  // Function setter
  external setFunction: (('a => 'a)) => ('a => 'a) = "%identity"
  
  // Path-based setter for nested updates
  @module("solid-js")
  external setPath: (array<string>, 'value) => unit = "setPath"
}

// Store utilities
module StoreUtils = {
  // Helper to create a store with initial value
  let make = initialValue => {
    createStore(initialValue)
  }
}
