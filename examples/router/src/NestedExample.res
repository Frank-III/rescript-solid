open Solid
module R = SolidRouter
module Switch = SolidJSX.Switch
module Match = SolidJSX.Match

// Example demonstrating nested routes
module UsersLayout = {
  @jsx.component
  let make = (~children) => {
    <div>
      <h2>{string("Users Section")}</h2>
      <nav>
        <R.Link href_="/users">{string("All Users")}</R.Link>
        {string(" | ")}
        <R.Link href_="/users/123">{string("User 123")}</R.Link>
        {string(" | ")}
        <R.Link href_="/users/456">{string("User 456")}</R.Link>
      </nav>
      <div>
        {children}
      </div>
    </div>
  }
}

module UsersList = {
  @jsx.component
  let make = () => {
    <div>
      <h3>{string("Users List")}</h3>
      <ul>
        <li>{string("User 1")}</li>
        <li>{string("User 2")}</li>
        <li>{string("User 3")}</li>
      </ul>
    </div>
  }
}

module UserDetail = {
  @jsx.component
  let make = () => {
    let params = R.useParams()
    let userId = createMemo(() => params->Dict.get("id")->Option.getOr("unknown"))
    
    <div>
      <h3>{string("User Detail")}</h3>
      <p>{string("User ID: " ++ userId())}</p>
    </div>
  }
}

module NotFound404 = {
  @jsx.component
  let make = () => {
    <div>
      <h2>{string("404 - Not Found")}</h2>
      <R.Link href_="/users">{string("Go to Users")}</R.Link>
    </div>
  }
}

// Example with nested routes
module NestedRoutesExample = {
  @jsx.component
  let make = () => {
    <R.Router>
      // Nested routes using RouteWrapper
      <R.RouteWrapper path_="/users">
        <R.Route path_="/" component_={UsersList.make} />
        <R.Route path_="/:id" component_={UserDetail.make} />
      </R.RouteWrapper>
      
      // Catch-all route
      <R.Route path_="*404" component_={NotFound404.make} />
    </R.Router>
  }
}

// Example with multiple paths for the same component
module LoginRegister = {
  @jsx.component
  let make = () => {
    let location = R.useLocation()
    let isLogin = createMemo(() => location.pathname == "/login")
    
    <div>
      <Switch.make>
        <Match.make when_={isLogin()}>
          <>
            <h2>{string("Login")}</h2>
            <form>
              <input type_="text" placeholder="Username" />
              <input type_="password" placeholder="Password" />
              <button type_="submit">{string("Login")}</button>
            </form>
            <p>
              {string("Don't have an account? ")}
              <R.Link href_="/register">{string("Register")}</R.Link>
            </p>
          </>
        </Match.make>
        <Match.make when_={!isLogin()}>
          <>
            <h2>{string("Register")}</h2>
            <form>
              <input type_="text" placeholder="Username" />
              <input type_="password" placeholder="Password" />
              <input type_="password" placeholder="Confirm Password" />
              <button type_="submit">{string("Register")}</button>
            </form>
            <p>
              {string("Already have an account? ")}
              <R.Link href_="/login">{string("Login")}</R.Link>
            </p>
          </>
        </Match.make>
      </Switch.make>
    </div>
  }
}

module HomeWithLinks = {
  @jsx.component
  let make = () => {
    <div>
      <h2>{string("Home")}</h2>
      <R.Link href_="/login">{string("Login")}</R.Link>
      {string(" | ")}
      <R.Link href_="/register">{string("Register")}</R.Link>
    </div>
  }
}

// Example with multi-path routes
module MultiPathExample = {
  @jsx.component
  let make = () => {
  <R.Router>
    <R.RouteMultiPath 
      path_={["login", "register"]} 
      component_={LoginRegister.make} 
    />
    <R.Route path_="/" component_={HomeWithLinks.make} />
  </R.Router>
  }
}

// Simplified example without preload for now
// (Preload requires more complex type setup that we can address later)
