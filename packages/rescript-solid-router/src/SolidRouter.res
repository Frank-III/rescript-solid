open Solid

type childrenProps = {children: element}

// Main Router component with full props support
module Router = {
  type props = {
    children: element,
    @as("root") root_?: Jsx.component<childrenProps>,
    @as("base") base_?: string,
    @as("actionBase") actionBase_?: string,
    @as("explicitLinks") explicitLinks_?: bool,
    @as("preload") preload_?: bool,
    @as("url") url_?: string,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props> = "Router"
}

// Types for Route component
type matchFilter = 
  | Array(array<string>) // enum values like ["mom", "dad"]
  | Regex(RegExp.t) // regex pattern
  | Fn(string => bool) // custom validation function

type matchFilters = dict<matchFilter>

// Preload function types
type intent = [#initial | #navigate | #native | #preload]

type location = {
  pathname: string,
  search: string,
  hash: string,
  query: dict<string>,
  state: option<JSON.t>,
  key: string,
}

type preloadArgs<'params> = {
  params: 'params,
  location: location,
  intent: intent,
}

type preloadFunction<'params, 'return> = preloadArgs<'params> => 'return

// Main Route component for common use
module Route = {
  type props<'props> = {
    @as("path") path_: string,
    @as("component") component_: Jsx.component<'props>,
    children?: element,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props<'props>> = "Route"
}

// Advanced Route component with all features
module RouteAdvanced = {
  type pathType
  external pathFromString: string => pathType = "%identity"
  external pathFromArray: array<string> => pathType = "%identity"
  
  type props<'params, 'preloadReturn> = {
    @as("path") path_?: pathType, // Can be string, array<string>, or undefined
    @as("component") component_?: Jsx.componentLike<'params, element>,
    children?: element, // For nested routes
    @as("matchFilters") matchFilters_?: matchFilters,
    @as("preload") preload_?: preloadFunction<'params, 'preloadReturn>,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props<'params, 'preloadReturn>> = "Route"
}

// Route for nested routes without path (wrapper routes)
module RouteWrapper = {
  type props = {
    @as("path") path_: string,
    children: element,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props> = "Route"
}

// Route with multiple paths
module RouteMultiPath = {
  type props<'props> = {
    @as("path") path_: array<string>,
    @as("component") component_: Jsx.component<'props>,
    children?: element,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props<'props>> = "Route"
}

module HashRouter = {
  type props = {
    children: element,
    @as("actionBase") actionBase_?: string,
    @as("explicitLinks") explicitLinks_?: bool,
    @as("preload") preload_?: bool,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props> = "HashRouter"
}

module MemoryRouter = {
  type props = {
    children: element,
    @as("actionBase") actionBase_?: string,
    @as("explicitLinks") explicitLinks_?: bool,
    @as("preload") preload_?: bool,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props> = "MemoryRouter"
}

// Components
module Link = {
  // Subset of AnchorProps
  type props = {
    @as("href") href_: string,
    @as("replace") replace_?: bool,
    @as("noScroll") noScroll_?: bool,
    @as("inactiveClass") inactiveClass_?: string,
    @as("activeClass") activeClass_?: string,
    @as("end") end_?: bool,
    children: element,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props> = "A"
}

module Navigate = {
  type props<'state> = {
    @as("href") href_: string,
    state?: 'state,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props<'state>> = "Navigate"
}

// Types for navigation primitives
type params = dict<string>

type pathMatch = {
  params: params,
  path: string,
}

type routeDescription = {
  key: JSON.t,
  originalPath: string,
  pattern: string,
}

type routeMatch = {
  params: params,
  path: string,
  route: routeDescription,
}

type navigateOptions = {
  replace?: bool,
  state?: JSON.t,
  scroll?: bool,
}

type beforeLeaveEventArgs = {
  from: location,
  @as("to") to_: string,
  options: option<navigateOptions>,
  preventDefault: unit => unit,
  defaultPrevented: bool,
  retry: (bool => unit),
}

// Primitives with proper types
@module("@solidjs/router")
external useLocation: unit => location = "useLocation"

@module("@solidjs/router")
external useIsRouting: unit => unit => bool = "useIsRouting"

@module("@solidjs/router")
external useMatch: (unit => string, ~matchFilters: matchFilters=?, unit) => unit => option<pathMatch> = "useMatch"

@module("@solidjs/router")
external useCurrentMatches: unit => unit => array<routeMatch> = "useCurrentMatches"

@module("@solidjs/router")
external usePreloadRoute: unit => string => unit = "usePreloadRoute"

@module("@solidjs/router")
external useBeforeLeave: (beforeLeaveEventArgs => unit) => unit = "useBeforeLeave"

// Data APIs
module Data = {
  // createAsync / createAsyncStore
  type asyncOptions<'a> = {
    @as("name") name_?: string,
    @as("initialValue") initialValue_?: 'a,
    @as("deferStream") deferStream_?: bool,
  }

  @module("@solidjs/router")
  external createAsync: (option<'a> => promise<'a>, asyncOptions<'a>) => unit => option<'a> =
    "createAsync"

  @module("@solidjs/router")
  external createAsyncSimple: (option<'a> => promise<'a>) => unit => option<'a> = "createAsync"

  @module("@solidjs/router")
  external createAsyncStore: (option<'a> => promise<'a>, asyncOptions<'a>) => unit => option<'a> =
    "createAsyncStore"

  // query / cache / revalidate
  @module("@solidjs/router")
  external query: (('fn, string)) => 'cached = "query"

  @module("@solidjs/router")
  external revalidateAll: unit => promise<unit> = "revalidate"

  @module("@solidjs/router")
  external revalidateKey: string => promise<unit> = "revalidate"

  @module("@solidjs/router")
  external revalidateKeys: array<string> => promise<unit> = "revalidate"

  // cache is alias of query
  @module("@solidjs/router")
  external cache: (('fn, string)) => 'cached = "cache"

  // Actions (light wrappers)
  type action<'a, 'u>

  @module("@solidjs/router")
  external action: ('a => promise<'u>, ~name: string=?, unit) => action<'a, 'u> = "action"

  @module("@solidjs/router")
  external useAction: action<'a, 'u> => 'a => promise<'u> = "useAction"

  type submission<'input, 'result> = {
    input: 'input,
    result?: 'result,
    pending: bool,
    url: string,
    clear: unit => unit,
    retry: unit => unit,
  }

  @module("@solidjs/router")
  external useSubmission: action<'a, 'u> => submission<'a, 'u> = "useSubmission"

  @module("@solidjs/router")
  external useSubmissions: action<'a, 'u> => array<submission<'a, 'u>> = "useSubmissions"
}

// Module functions (advanced): build typed helpers without runtime cost
module MakeParams = (
  P: {
    type t
  },
) => {
  @module("@solidjs/router")
  external useParams: unit => P.t = "useParams"
}

module MakeSearchParams = (
  S: {
    type t
  },
) => {
  @module("@solidjs/router")
  external useSearchParams: unit => (S.t, S.t => unit) = "useSearchParams"
}

module MakeAction = (
  A: {
    type input
    type output
  },
) => {
  type t
  @module("@solidjs/router")
  external action: (A.input => promise<A.output>, ~name: string=?, unit) => t = "action"
  @module("@solidjs/router")
  external useAction: t => A.input => promise<A.output> = "useAction"
  @module("@solidjs/router")
  external useSubmission: t => Data.submission<A.input, A.output> = "useSubmission"
  @module("@solidjs/router")
  external useSubmissions: t => array<Data.submission<A.input, A.output>> = "useSubmissions"
}

// Note: We intentionally avoid a MakeAsync functor; Data.createAsync infers types from the loader.

module A = {
  type props = {@as("href") href_: string, children: element}
  @module("@solidjs/router")
  external make: Jsx.component<props> = "A"
}

// Navigate function can be called with string or number
type navigateFn
@send external navigateToPath: (navigateFn, string, ~options: navigateOptions=?, unit) => unit = "call"
@send external navigateByDelta: (navigateFn, int) => unit = "call"

@module("@solidjs/router")
external useNavigate: unit => navigateFn = "useNavigate"

@module("@solidjs/router")
external useParams: unit => params = "useParams"

type searchParams = dict<string>
@module("@solidjs/router")
external useSearchParams: unit => (searchParams, searchParams => unit) = "useSearchParams"
