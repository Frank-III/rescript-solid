open Solid
module R = SolidRouter
module Home = Home
module User = User

module Root = {
  @jsx.component
  let make = (~children) => {
    let isRouting = R.useIsRouting()
    <div classList={Dict.fromArray([("grey-out", isRouting())])}>
      <h1> {string("Demo: Router")} </h1>
      <nav>
        <R.Link href_="/"> {string("Home")} </R.Link>
        <R.Link href_="/user/alice"> {string("Alice")} </R.Link>
        <R.Link href_="/stories"> {string("Stories (no id)")} </R.Link>
        <R.Link href_="/stories/123"> {string("Stories 123")} </R.Link>
        <R.Link href_="/foo/a/b"> {string("Foo */*")} </R.Link>
        <R.Link href_="/missing"> {string("404")} </R.Link>
      </nav>
      {children}
    </div>
  }
}

@jsx.component
let make = () => {
  <Root>
    <R.RouterRoot>
      <R.RouteEl path_="/" element_={<Home />} />
      <R.RouteEl path_="/user/:name" element_={<User />} />
      <R.RouteEl path_="/stories/:id?" element_={<Stories />} />
      <R.RouteEl path_="foo/*any" element_={<Foo />} />
      <R.RouteEl path_="*404" element_={<NotFound />} />
    </R.RouterRoot>
  </Root>
}
