open Solid

type childrenProps = { children: element }

module Router = {
  @module("@solidjs/router")
  external make: Jsx.component<childrenProps> = "Router"
}

module Routes = {
  @module("@solidjs/router")
  external make: Jsx.component<childrenProps> = "Routes"
}

module Route = {
  // Support common pattern: <Route path="/" component={Home} />
  type props = {
    @as("path") path_: string,
    @as("component") component_: Jsx.component<unit>,
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
    @as("actionBase") actionBase_?: string,
    @as("explicitLinks") explicitLinks_?: bool,
    @as("preload") preload_?: bool,
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
