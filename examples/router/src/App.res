open Solid
module R = SolidRouter
module Home = Home
module User = User
module ComplexReactivity = ComplexReactivity
module BindingsAudit = BindingsAudit

// Root layout component
let rootLayout = (props: SolidRouter.childrenProps) => {
  let isRouting = R.useIsRouting()
  <div classList={Dict.fromArray([("grey-out", isRouting())])}>
    <h1> {string("Demo: Router")} </h1>
    <nav>
      <R.Link href_="/"> {string("Home")} </R.Link>
      <R.Link href_="/user/alice"> {string("Alice")} </R.Link>
      <R.Link href_="/stories"> {string("Stories (no id)")} </R.Link>
      <R.Link href_="/stories/123"> {string("Stories 123")} </R.Link>
      <R.Link href_="/complex"> {string("Complex Reactivity")} </R.Link>
      <R.Link href_="/bindings"> {string("Bindings Audit")} </R.Link>
      <R.Link href_="/foo/a/b"> {string("Foo */*")} </R.Link>
      <R.Link href_="/missing"> {string("404")} </R.Link>
    </nav>
    {props.children}
  </div>
}

@jsx.component
let make = () => {
  // Use Router with root prop as per SolidJS Router documentation
  <R.Router root_={rootLayout}>
    <R.Route path_="/" component_={Home.make} />
    <R.Route path_="/user/:name" component_={User.make} />
    <R.Route path_="/stories/:id?" component_={Stories.make} />
    <R.Route path_="/complex" component_={ComplexReactivity.make} />
    <R.Route path_="/bindings" component_={BindingsAudit.make} />
    <R.Route path_="foo/*any" component_={Foo.make} />
    <R.Route path_="*404" component_={NotFound.make} />
  </R.Router>
}
