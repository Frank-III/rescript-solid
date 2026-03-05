// Core Solid.js bindings for ReScript with JSX preserve mode

// Re-export element type from Jsx module for compatibility
type element = Jsx.element
type component<'props> = Jsx.component<'props>
type componentLike<'props, 'return> = Jsx.componentLike<'props, 'return>

// JSX Runtime - These are needed for ReScript's JSX transform
// Even in preserve mode, ReScript needs these to exist
@module("@solidjs/h/jsx-runtime")
external jsx: (component<'props>, 'props) => element = "jsx"

@module("@solidjs/h/jsx-runtime")
external jsxs: (component<'props>, 'props) => element = "jsxs"

@module("@solidjs/h/jsx-runtime")
external jsxKeyed: (component<'props>, 'props, ~key: string=?, @ignore unit) => element = "jsx"

// Fragment: provide a value for typing; prefer preserve <> shorthand in output
type fragmentProps = {children?: element}
let jsxFragment: component<fragmentProps> = props => {
  props.children->Option.getOr(Jsx.null)
}

// Elements module for lowercase JSX elements
module Elements = {
  // Use SolidDOM.domProps to include Solid's extra allowances (class, classList, etc.)
  type props = SolidDOM.domProps

  @module("@solidjs/h/jsx-runtime")
  external jsx: (string, props) => element = "jsx"

  @module("@solidjs/h/jsx-runtime")
  external jsxs: (string, props) => element = "jsxs"

  @module("@solidjs/h/jsx-runtime")
  external jsxKeyed: (string, props, ~key: string=?, @ignore unit) => element = "jsx"

  @module("@solidjs/h/jsx-runtime")
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
external createSignalFromFn: (unit => 'a) => signal<'a> = "createSignal"

@module("solid-js")
external createSignalFromAsyncFn: (unit => promise<'a>) => signal<'a> = "createSignal"

@module("solid-js")
external createSignalWithOptions: ('a, ~options: {..}=?, unit) => signal<'a> = "createSignal"

@module("solid-js")
external createSignalFromFnWithInitial: ((unit => 'a), 'a) => signal<'a> = "createSignal"

@module("solid-js")
external createSignalFromAsyncFnWithInitial: ((unit => promise<'a>), 'a) => signal<'a> =
  "createSignal"

// Effects
@module("solid-js")
external createEffect: ((unit => 'next), ('next => unit)) => unit = "createEffect"

@module("solid-js")
external createEffectWithInitial: ((unit => 'next), ('next => unit), 'next) => unit = "createEffect"

@module("solid-js")
external createRenderEffect: ((unit => 'next), ('next => unit)) => unit = "createRenderEffect"

@module("solid-js")
external createTrackedEffect: (unit => unit) => unit = "createTrackedEffect"

@module("solid-js")
external createTrackEffect: (unit => unit) => unit = "createTrackedEffect"

// Memos
@module("solid-js")
external createMemo: (unit => 'a) => accessor<'a> = "createMemo"

@module("solid-js")
external createMemoAsync: (unit => promise<'a>) => accessor<'a> = "createMemo"

@module("solid-js")
external createMemoWithPrev: ((~prev: 'a=?) => 'a) => accessor<'a> = "createMemo"

@module("solid-js")
external createOptimistic: 'a => signal<'a> = "createOptimistic"

@module("solid-js")
external createOptimisticFromFn: (unit => 'a) => signal<'a> = "createOptimistic"

@module("solid-js")
external createOptimisticFromAsyncFn: (unit => promise<'a>) => signal<'a> = "createOptimistic"

@module("solid-js")
external createOptimisticFromFnWithInitial: ((unit => 'a), 'a) => signal<'a> = "createOptimistic"

@module("solid-js")
external createOptimisticFromAsyncFnWithInitial: ((unit => promise<'a>), 'a) => signal<'a> =
  "createOptimistic"

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
external onSettled: (unit => unit) => unit = "onSettled"

// Compatibility alias for 1.x naming
@module("solid-js")
external onMount: (unit => unit) => unit = "onSettled"

@module("solid-js")
external onCleanup: (unit => unit) => unit = "onCleanup"

@module("solid-js")
external onError: (JsError.t => unit) => unit = "onError"

// ReScript-friendly action builder:
// model generator steps explicitly so callers don't need JS function* syntax.
type actionStep<'result>

@module("./SolidActionBridge.mjs")
external doneStep: 'result => actionStep<'result> = "done"

@module("./SolidActionBridge.mjs")
external awaitStep: (promise<'value>, 'value => actionStep<'result>) => actionStep<'result> =
  "awaitPromise"

@module("./SolidActionBridge.mjs")
external action0: (unit => actionStep<'result>) => unit => promise<'result> = "actionFromStepper"

@module("./SolidActionBridge.mjs")
external action: ('arg => actionStep<'result>) => 'arg => promise<'result> = "actionFromStepper"

// Reactive utilities
@module("solid-js")
external batch: (unit => 'a) => 'a = "batch"

@module("solid-js")
external flush: unit => unit = "flush"

@module("solid-js")
external untrack: (unit => 'a) => 'a = "untrack"

@module("solid-js")
external isPending: (unit => 'a) => bool = "isPending"

@module("solid-js")
external latest: (unit => 'a) => 'a = "latest"

@module("solid-js")
external refresh: accessor<'a> => unit = "refresh"

@module("solid-js")
external storePath: 'a => 'a = "storePath"

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

// Helper functions for element creation
external array: array<element> => element = "%identity"
@val external null: element = "null"
external float: float => element = "%identity"
external int: int => element = "%identity"
external string: string => element = "%identity"
