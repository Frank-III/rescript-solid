open Solid
module R = SolidRouter
module Home = Home
module User = User

@jsx.component
let make = () => {
  <R.Router>
    <R.Routes>
      <R.RouteEl path_="/" element_={<Home />} />
      <R.RouteEl path_="/user/:name" element_={<User />} />
    </R.Routes>
  </R.Router>
}
