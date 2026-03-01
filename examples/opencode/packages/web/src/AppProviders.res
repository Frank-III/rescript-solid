open Solid

let appBaseProviders = (~children: element) =>
  <section className="baseProviders">{children}</section>

let appShellProviders = (~children: element) =>
  <section className="shellProviders">{children}</section>

let sessionProviders = (~children: element) =>
  <section className="sessionProviders">{children}</section>

let routerRoot = (~children: element) => appShellProviders(~children)

let serverGate = (~server: accessor<string>, ~children: element) =>
  if server() == "" {
    <section className="panel">
      <p className="errorText">{string("No active server configured")}</p>
    </section>
  } else {
    children
  }
