// Core Solid.js bindings for ReScript with JSX preserve mode

// Re-export element type from Jsx module for compatibility
type element = Jsx.element
type component<'props> = Jsx.component<'props>
type componentLike<'props, 'return> = Jsx.componentLike<'props, 'return>

// JSX Runtime - These are needed for ReScript's JSX transform
// Even in preserve mode, ReScript needs these to exist
@module("solid-js/h")
external jsx: (component<'props>, 'props) => element = "jsx"

@module("solid-js/h")
external jsxs: (component<'props>, 'props) => element = "jsxs"

@module("solid-js/h")
external jsxKeyed: (component<'props>, 'props, ~key: string=?, @ignore unit) => element = "jsx"

@module("solid-js/h")
external jsxsKeyed: (component<'props>, 'props, ~key: string=?, @ignore unit) => element = "jsxs"

// Fragment support - bind to Solid's Fragment for proper JSX preserve mode
type fragmentProps = {children?: element}

@module("solid-js")
external jsxFragment: component<fragmentProps> = "Fragment"

// Elements module for lowercase JSX elements
module Elements = {
  // Use SolidDOM.domProps to include Solid's extra allowances (class, classList, etc.)
  type props = SolidDOM.domProps

  @module("solid-js/h")
  external jsx: (string, props) => element = "jsx"

  @module("solid-js/h")
  external jsxs: (string, props) => element = "jsxs"

  @module("solid-js/h")
  external jsxKeyed: (string, props, ~key: string=?, @ignore unit) => element = "jsx"

  @module("solid-js/h")
  external jsxsKeyed: (string, props, ~key: string=?, @ignore unit) => element = "jsxs"

  // Required identity used by the transform to disambiguate lower-case elements
  external someElement: element => option<element> = "%identity"
}

// Core Solid.js primitives

// Signals
type accessor<'a> = unit => 'a
type setter<'a> = ('a => 'a) => unit
type signal<'a> = (accessor<'a>, setter<'a>)

@module("solid-js")
external createSignal: 'a => signal<'a> = "createSignal"

@module("solid-js")
external createSignalWithOptions: ('a, ~options: {..}=?, unit) => signal<'a> = "createSignal"

// Effects
@module("solid-js")
external createEffect: (unit => unit) => unit = "createEffect"

@module("solid-js")
external createEffectWithValue: (unit => 'a) => 'a = "createEffect"

// Memos
@module("solid-js")
external createMemo: (unit => 'a) => accessor<'a> = "createMemo"

@module("solid-js")
external createMemoWithPrev: ((~prev: 'a=?) => 'a) => accessor<'a> = "createMemo"

// Resources
type resource<'a> = accessor<option<'a>>
type resourceActions<'a> = {"mutate": option<'a> => unit, "refetch": unit => promise<'a>}

@module("solid-js")
external createResource: (unit => promise<'a>) => (resource<'a>, resourceActions<'a>) =
  "createResource"

@module("solid-js")
external createResourceWithSource: (
  accessor<'source>,
  ('source, ~prevValue: 'a=?, unit) => promise<'a>,
) => (resource<'a>, resourceActions<'a>) = "createResource"

// Context
type context<'a>

@module("solid-js")
external createContext: 'a => context<'a> = "createContext"

@module("solid-js")
external useContext: context<'a> => 'a = "useContext"

// Component lifecycle
@module("solid-js")
external onMount: (unit => unit) => unit = "onMount"

@module("solid-js")
external onCleanup: (unit => unit) => unit = "onCleanup"

@module("solid-js")
external onError: (JsError.t => unit) => unit = "onError"

// Reactive utilities
@module("solid-js")
external batch: (unit => 'a) => 'a = "batch"

@module("solid-js")
external untrack: (unit => 'a) => 'a = "untrack"

@module("solid-js")
external on: (accessor<'a>, ('a, 'a, 'b) => 'b) => 'b => 'b = "on"

@module("solid-js")
external createRoot: ((unit => unit) => 'a) => 'a = "createRoot"

// Helper utilities
@module("solid-js")
external createUniqueId: unit => string = "createUniqueId"

// children utility: unwrap children into an accessor
@module("solid-js")
external children: (unit => 'a) => accessor<'a> = "children"

@module("solid-js")
external mergeProps: ('a, 'b) => 'c = "mergeProps"

@module("solid-js")
external splitProps: ('props, array<string>) => ('a, 'b) = "splitProps"

// DEV mode check
@module("solid-js")
external \"DEV": {..} = "DEV"

// Helper functions for element creation (eager)
external array: array<element> => element = "%identity"
@val external null: element = "null"
external float: float => element = "%identity"
external int: int => element = "%identity"
external string: string => element = "%identity"
external promise: promise<element> => element = "%identity"

// Lazy/deferred helpers for reactive content
// In Solid, {() => value} creates reactive text that re-renders when signals change
// These tell ReScript that a function returning X is a valid element
external lazy: (unit => element) => element = "%identity"
external lazyString: (unit => string) => element = "%identity"
external lazyInt: (unit => int) => element = "%identity"
external lazyFloat: (unit => float) => element = "%identity"
external lazyArray: (unit => array<element>) => element = "%identity"
external lazyOption: (unit => option<element>) => element = "%identity"
