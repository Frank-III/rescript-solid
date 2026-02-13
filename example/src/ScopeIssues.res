// 🔴 CRITICAL SCOPE ISSUES: IIFE, Suspense, ErrorBoundary, Context, Lifecycle
//
// In Solid.js (JavaScript), you can use {(() => {})()} to create local scopes
// But in ReScript, these get LIFTED to component creation scope!
//
// This breaks: Suspense boundaries, ErrorBoundary, Context, Lifecycle hooks

open Solid

// 🔴 ISSUE 1: IIFE gets executed at component creation, not render
module IIFELiftingIssue = {
  @jsx.component
  let make = () => {
    let (outer, setOuter) = createSignal(0)

    // ❌ This IIFE executes at component creation!
    let iifResult = {
      Console.log("IIFE executing at component creation!")
      (() => {
        let (local, setLocal) = createSignal(0)
        <button onClick={_ => setLocal(prev => prev + 1)}>
          {string("Local: ")}
          {int(local())}
        </button>
      })()
    }

    <div>
      <h3>{string("🔴 IIFE Lifting Issue")}</h3>
      <p>{string("Outer: ")}{int(outer())}</p>
      <p>{string("IIFE result:")}</p>
      {iifResult}
      <button onClick={_ => setOuter(prev => prev + 1)}>
        {string("Inc Outer (IIFE doesn't recreate)")}
      </button>
      <p>
        <strong>
          {string("❌ Check console - IIFE runs ONCE at component creation!")}
        </strong>
      </p>
    </div>
  }
}

// 🔴 ISSUE 2: Suspense - createResource outside boundary
module SuspenseIssue = {
  @val external setTimeout: (unit => unit, int) => int = "setTimeout"

  let fetchData = () => {
    Console.log("Fetching...")
    Promise.make((resolve, _) => {
      let _ = setTimeout(() => resolve("Data!"), 2000)
    })
  }

  module Suspense = SolidJSX.Suspense

  // ❌ BROKEN: Resource created at component scope
  module Broken = {
    @jsx.component
    let make = () => {
      Console.log("Component created - resource creating now!")
      let (data, _) = createResource(fetchData) // ❌ Outside Suspense!

      <div>
        <h4>{string("❌ Broken")}</h4>
        <Suspense fallback_={string("Loading...")}>
          <div>
            {switch data() {
            | Some(d) => string(d)
            | None => string("No data")
            }}
          </div>
        </Suspense>
        <p>
          <strong>{string("Suspense fallback probably won't show!")}</strong>
        </p>
      </div>
    }
  }

  // ✅ WORKAROUND: Component inside Suspense
  module DataComponent = {
    @jsx.component
    let make = () => {
      Console.log("DataComponent created - resource inside Suspense!")
      let (data, _) = createResource(fetchData)

      switch data() {
      | Some(d) => <div>{string(d)}</div>
      | None => <div>{string("Loading in component...")}</div>
      }
    }
  }

  module Fixed = {
    @jsx.component
    let make = () => {
      <div>
        <h4>{string("✅ Fixed: Separate component")}</h4>
        <Suspense fallback_={string("Loading...")}>
          <DataComponent />
        </Suspense>
      </div>
    }
  }

  @jsx.component
  let make = () => {
    <div>
      <h3>{string("🔴 Suspense Boundary")}</h3>
      <Broken />
      <hr />
      <Fixed />
    </div>
  }
}

// 🔴 ISSUE 3: Cannot use IIFE for local scopes like JS Solid
module NoLocalScopes = {
  @jsx.component
  let make = () => {
    <div>
      <h3>{string("🔴 No Local Scopes in JSX")}</h3>
      <p>{string("In JS Solid, you can:")}</p>
      <pre>
        {string(
          "{(() => {\n  const [count, setCount] = createSignal(0);\n  return <button>{count()}</button>;\n})()}",
        )}
      </pre>
      <p>
        <strong>{string("❌ In ReScript, this runs at component creation!")}</strong>
      </p>
      <p>{string("✅ Solution: Use separate components")}</p>
    </div>
  }
}

// 🔴 ISSUE 4: Lifecycle hooks in wrong scope
module LifecycleIssue = {
  @val external setInterval: (unit => unit, int) => int = "setInterval"
  @val external clearInterval: int => unit = "clearInterval"

  // ✅ CORRECT: Lifecycle at component level
  @jsx.component
  let make = () => {
    let (count, setCount) = createSignal(0)

    onMount(() => {
      Console.log("Mounted!")
    })

    createEffect(() => {
      let interval = setInterval(() => {
        setCount(prev => prev + 1)
      }, 1000)

      onCleanup(() => {
        Console.log("Cleanup!")
        clearInterval(interval)
      })
    })

    <div>
      <h3>{string("🔴 Lifecycle Hooks")}</h3>
      <p>{string("Count: ")}{int(count())}</p>
      <p>
        <strong>{string("✅ onMount/onCleanup must be at component top level")}</strong>
      </p>
      <p>{string("Check console for lifecycle logs")}</p>
    </div>
  }
}

// Main Summary
@jsx.component
let make = () => {
  <div>
    <h1>{string("🔴 CRITICAL: IIFE & Scope Issues")}</h1>
    <div
      style={{
        padding: "20px",
        backgroundColor: "#fff5f5",
        border: "2px solid #fc8181",
        borderRadius: "8px",
        marginBottom: "20px",
      }}>
      <h2>{string("⚠️ KEY LIMITATION")}</h2>
      <p>
        <strong>
          {string("In JavaScript Solid, you can use {(() => {})()  } for local scopes.")}
        </strong>
      </p>
      <p>
        <strong>
          {string("In ReScript, IIFEs and block expressions are LIFTED to component creation!")}
        </strong>
      </p>
      <h3>{string("This breaks:")}</h3>
      <ul>
        <li>{string("✘ Local signal scopes")}</li>
        <li>{string("✘ Suspense boundaries (createResource outside)")}</li>
        <li>{string("✘ ErrorBoundary (errors thrown outside)")}</li>
        <li>{string("✘ Context providers")}</li>
        <li>{string("✘ Lifecycle hooks")}</li>
      </ul>
      <h3>{string("✅ Solution:")}</h3>
      <p>
        <strong>{string("Use separate components instead of IIFEs/blocks!")}</strong>
      </p>
    </div>
    <hr />
    <IIFELiftingIssue />
    <hr />
    <SuspenseIssue />
    <hr />
    <NoLocalScopes />
    <hr />
    <LifecycleIssue />
    <hr />
    <div>
      <h2>{string("📋 Summary")}</h2>
      <p>{string("ReScript compilation model differences:")}</p>
      <ol>
        <li>{string("Block expressions {} evaluated at component creation")}</li>
        <li>{string("IIFEs (() => {})() executed at component creation")}</li>
        <li>{string("Pattern matching lifted to component scope")}</li>
      </ol>
      <p>
        <strong>
          {string("Always use separate components for scoping, not IIFEs!")}
        </strong>
      </p>
    </div>
  </div>
}
