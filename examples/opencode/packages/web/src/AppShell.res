open Solid

module R = SolidRouter
module For = SolidJSX.For

type sidebarSessionItem = {
  id: string,
  href: string,
  isRunning: bool,
}

@jsx.component
let make = (
  ~children: element,
  ~serverStatusPanel: element,
  ~sidebarSessions: array<sidebarSessionItem>,
  ~onBack: unit => unit,
  ~onForward: unit => unit,
  ~onReload: unit => unit,
  ~onOpenUpstream: unit => unit,
) =>
  {
    ignore(serverStatusPanel)
    ignore(onBack)
    ignore(onForward)
    ignore(onReload)
    let activeSessionLabel = "New session"
    let sidebarMeta = if sidebarSessions->Array.length > 0 {
      `${sidebarSessions->Array.length->Int.toString} recent`
    } else {
      ""
    }

  <main className="appFrame">
    <header className="titlebar">
      <div className="titlebarWindow">
        <span className="winDot red" />
        <span className="winDot yellow" />
        <span className="winDot green" />
      </div>
      <div className="titlebarCenter">
        <span className="titlebarBrand">{string("OpenCode")}</span>
        <input className="titlebarSearch" type_="text" placeholder="Search" />
      </div>
      <div className="titlebarActions">
        <span className="titlePill" />
        <span className="titlePill" />
        <span className="titlePill" />
      </div>
    </header>

    <div className="appShell">
      <aside className="sidebarShell">
        <nav className="sidebarIconRail">
          <R.Link href_="/" inactiveClass_="iconNavItem" activeClass_="iconNavItem active">
            <span className="railDot railDotOrange" />
          </R.Link>
          <R.Link href_="/sessions" inactiveClass_="iconNavItem" activeClass_="iconNavItem active">
            <span className="railDot railDotBlue" />
          </R.Link>
          <R.Link href_="/workspace/session" inactiveClass_="iconNavItem" activeClass_="iconNavItem active">
            <span className="railDot railDotGreen" />
          </R.Link>

          <button className="iconNavItem railAuxBtn" onClick={_ => onOpenUpstream()}>
            <span className="railDot railDotNeutral" />
          </button>
        </nav>

        <section className="sidebarPanel">
          <header className="sidebarPanelHeader">
            <div>
              <h3 className="sidebarSessionTitle">{string(activeSessionLabel)}</h3>
              {@show switch sidebarMeta != "" {
              | true => <p className="sidebarPanelMeta">{string(sidebarMeta)}</p>
              | false => <span></span>
              }}
            </div>
          </header>

          <ul className="sidebarSessionList">
            <For each_={sidebarSessions} fallback_={<li className="sidebarSessionEmpty">{string("No sessions yet")}</li>}>
              {(session, _index) =>
                <li>
                  <R.Link
                    href_={session.href}
                    inactiveClass_="sidebarSessionItem"
                    activeClass_="sidebarSessionItem active">
                    <span
                      className={if session.isRunning {
                        "sidebarStatusDot running"
                      } else {
                        "sidebarStatusDot"
                      }}
                    />
                    <span className="sidebarSessionText">{string(session.id)}</span>
                  </R.Link>
                </li>}
            </For>
          </ul>
        </section>
      </aside>

      <section className="workspaceViewport">
        <div className="routeViewport">{children}</div>
      </section>
    </div>
  </main>
  }
