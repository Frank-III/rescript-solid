// Store and state management for Solid.js

// Store types
type store<'a> = 'a
type setStoreFunction<'a> = 'a => unit

// Create store
@module("solid-js/store")
external createStore: 'a => (store<'a>, setStoreFunction<'a>) = "createStore"

// Produce helper for immutable updates
@module("solid-js/store")
external produce: (store<'a> => unit) => store<'a> = "produce"

// Reconcile for efficient updates
@module("solid-js/store")
external reconcile: ('a, ~options: {..}=?, unit) => 'a = "reconcile"

// Unwrap store proxy
@module("solid-js/store")
external unwrap: store<'a> => 'a = "unwrap"

// Create mutable store
@module("solid-js/store")
external createMutable: 'a => store<'a> = "createMutable"

// Store setter patterns
module Setter = {
  // Direct value setter
  external setValue: 'a => 'a = "%identity"
  
  // Function setter
  external setFunction: (('a => 'a)) => ('a => 'a) = "%identity"
  
  // Path-based setter for nested updates
  @module("solid-js/store")
  external setPath: (array<string>, 'value) => unit = "setPath"
}

// Store utilities
module StoreUtils = {
  // Helper to create a store with initial value
  let make = initialValue => {
    createStore(initialValue)
  }
}

