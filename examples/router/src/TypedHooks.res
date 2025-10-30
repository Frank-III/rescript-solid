// Example demonstrating the improved type-safe router hooks
open Solid
module R = SolidRouter

// Window binding for confirm dialog
module Window = {
  @val @scope("window")
  external confirm: string => bool = "confirm"
}

module TypedHooksDemo = {
  @jsx.component
  let make = () => {
    // useLocation now returns a properly typed location object
    let location = R.useLocation()
    
    // useIsRouting returns an accessor
    let isRouting = R.useIsRouting()
    
    // useParams returns a typed dict
    let params = R.useParams()
    
    // useSearchParams with typed dict
    let (searchParams, setSearchParams) = R.useSearchParams()
    
    // useNavigate returns a function that can be used with options
    let navigate = R.useNavigate()
    
    // useCurrentMatches returns properly typed route matches
    let getCurrentMatches = R.useCurrentMatches()
    
    // useMatch with optional matchFilters
    let matchHome = R.useMatch(() => "/", ())
    let matchUser = R.useMatch(() => "/user/:id", 
      ~matchFilters=Dict.fromArray([
        ("id", R.Regex(%re("/^\d+$/"))),
      ]), 
      ()
    )
    
    <div>
      <h2>{string("Router Hooks Demo")}</h2>
      
      <section>
        <h3>{string("Location")}</h3>
        <ul>
          <li>{string("Pathname: " ++ location.pathname)}</li>
          <li>{string("Search: " ++ location.search)}</li>
          <li>{string("Hash: " ++ location.hash)}</li>
          <li>{string("Key: " ++ location.key)}</li>
        </ul>
      </section>
      
      <section>
        <h3>{string("Routing Status")}</h3>
        <p>{string("Is routing: " ++ (isRouting() ? "Yes" : "No"))}</p>
      </section>
      
      <section>
        <h3>{string("Params")}</h3>
        <ul>
          {params
            ->Dict.toArray
            ->Array.map(((key, value)) => 
              <li key={key}>{string(key ++ ": " ++ value)}</li>
            )
            ->array}
        </ul>
      </section>
      
      <section>
        <h3>{string("Search Params")}</h3>
        <ul>
          {searchParams
            ->Dict.toArray
            ->Array.map(((key, value)) => 
              <li key={key}>{string(key ++ ": " ++ value)}</li>
            )
            ->array}
        </ul>
        <button onClick={_ => {
          let newParams = Dict.fromArray([("test", "value")])
          setSearchParams(newParams)
        }}>
          {string("Set Test Param")}
        </button>
      </section>
      
      <section>
        <h3>{string("Navigation")}</h3>
        <button onClick={_ => {
          // Navigate with options
          navigate->R.navigateToPath("/", ~options={replace: true}, ())
        }}>
          {string("Go Home (replace)")}
        </button>
        <button onClick={_ => {
          // Navigate back
          navigate->R.navigateByDelta(-1)
        }}>
          {string("Go Back")}
        </button>
      </section>
      
      <section>
        <h3>{string("Route Matches")}</h3>
        <p>{string("Home match: " ++ (matchHome() != None ? "Yes" : "No"))}</p>
        <p>{string("User match: " ++ (matchUser() != None ? "Yes" : "No"))}</p>
        
        <h4>{string("Current Matches:")}</h4>
        <ul>
          {getCurrentMatches()
            ->Array.map(match => 
              <li key={match.route.originalPath}>
                {string("Path: " ++ match.path ++ ", Pattern: " ++ match.route.pattern)}
              </li>
            )
            ->array}
        </ul>
      </section>
    </div>
  }
}

// Example using useBeforeLeave hook
module NavigationGuard = {
  @jsx.component
  let make = () => {
    let (isDirty, setIsDirty) = createSignal(false)
    
    // Type-safe beforeLeave handler
    R.useBeforeLeave((e: R.beforeLeaveEventArgs) => {
      if isDirty() {
        if !Window.confirm("You have unsaved changes. Are you sure you want to leave?") {
          e.preventDefault()
        }
      }
    })
    
    <div>
      <h3>{string("Navigation Guard Example")}</h3>
      <label>
        <input 
          type_="checkbox"
          checked={isDirty()}
          onChange={_ => setIsDirty(prev => !prev)}
        />
        {string(" Simulate unsaved changes")}
      </label>
      <p>{string(isDirty() ? "Try navigating away - you'll be prompted!" : "Navigation is unrestricted")}</p>
    </div>
  }
}

// Note: Form actions require special handling with form elements
// For now, actions are best used with useAction hook for programmatic submission