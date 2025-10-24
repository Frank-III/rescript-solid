open Solid

type childrenProps = { children: element }

module Router = {
  @module("@solidjs/router")
  external make: Jsx.component<childrenProps> = "Router"
}

/* Note: Recent router versions do not export <Routes>; keep only <Router> and <Route>. */

module Route = {
  // Support common pattern: <Route path="/" component={Home} />
  type props = {
    @as("path") path_: string,
    @as("component") component_: Jsx.componentLike<unit, element>,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props> = "Route"
}

module RouteEl = {
  // Alternative: <Route path="/" element={<Home />} />
  type props = {
    @as("path") path_: string,
    @as("element") element_: element,
  }
  @module("@solidjs/router")
  external make: Jsx.component<props> = "Route"
}

// Routers
module RouterRoot = {
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

// Primitives
@module("@solidjs/router")
external useLocation: unit => {..} = "useLocation"

@module("@solidjs/router")
external useIsRouting: unit => (unit => bool) = "useIsRouting"

@module("@solidjs/router")
external useMatch: (unit => string, {..}) => (unit => option<{..}>) = "useMatch"

@module("@solidjs/router")
external useCurrentMatches: unit => (unit => array<{..}>) = "useCurrentMatches"

@module("@solidjs/router")
external usePreloadRoute: unit => (string => unit) = "usePreloadRoute"

@module("@solidjs/router")
external useBeforeLeave: (({..}) => unit) => unit = "useBeforeLeave"

// Data APIs
module Data = {
  // createAsync / createAsyncStore
  type asyncOptions<'a> = {
    @as("name") name_?: string,
    @as("initialValue") initialValue_?: 'a,
    @as("deferStream") deferStream_?: bool,
  }

  @module("@solidjs/router")
  external createAsync: ((option<'a> => promise<'a>), asyncOptions<'a>) => (unit => option<'a>) = "createAsync"

  @module("@solidjs/router")
  external createAsyncSimple: (option<'a> => promise<'a>) => (unit => option<'a>) = "createAsync"

  @module("@solidjs/router")
  external createAsyncStore: ((option<'a> => promise<'a>), asyncOptions<'a>) => (unit => option<'a>) = "createAsyncStore"

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
  external action: (('a => promise<'u>), ~name: string=?, unit) => action<'a, 'u> = "action"

  @module("@solidjs/router")
  external useAction: action<'a, 'u> => ('a => promise<'u>) = "useAction"

  @module("@solidjs/router")
  external useSubmission: action<'a, 'u> => {..} = "useSubmission"

  @module("@solidjs/router")
  external useSubmissions: action<'a, 'u> => array<{..}> = "useSubmissions"
}

// Module functions (advanced): build typed helpers without runtime cost
module MakeParams = (P: { type t }) => {
  @module("@solidjs/router")
  external useParams: unit => P.t = "useParams"
}

module MakeSearchParams = (S: { type t }) => {
  @module("@solidjs/router")
  external useSearchParams: unit => (S.t, S.t => unit) = "useSearchParams"
}

module MakeAction = (A: { type input; type output }) => {
  type t
  @module("@solidjs/router")
  external action: (A.input => promise<A.output>, ~name: string=?, unit) => t = "action"
  @module("@solidjs/router")
  external useAction: t => (A.input => promise<A.output>) = "useAction"
  @module("@solidjs/router")
  external useSubmission: t => {..} = "useSubmission"
  @module("@solidjs/router")
  external useSubmissions: t => array<{..}> = "useSubmissions"
}

// Note: We intentionally avoid a MakeAsync functor; Data.createAsync infers types from the loader.

module A = {
  type props = { @as("href") href_: string, children: element }
  @module("@solidjs/router")
  external make: Jsx.component<props> = "A"
}

@module("@solidjs/router")
external useNavigate: unit => (string => unit) = "useNavigate"

type params = dict<string>
@module("@solidjs/router")
external useParams: unit => params = "useParams"

type searchParams = dict<string>
@module("@solidjs/router")
external useSearchParams: unit => (searchParams, searchParams => unit) = "useSearchParams"
