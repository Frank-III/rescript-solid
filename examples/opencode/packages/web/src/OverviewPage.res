open Solid

module For = SolidJSX.For
module R = SolidRouter

type projectRow = {
  label: string,
}

type statusLine = {
  className: string,
  text: string,
}

@jsx.component
let make = (
  ~activeServer: string,
  ~healthText: string,
  ~projectText: string,
  ~sessionCount: int,
  ~projectCount: int,
  ~lastEvent: string,
  ~runningSessionCount: int,
  ~projects: array<projectRow>,
  ~statusLine: statusLine,
) =>
  {
    ignore(healthText)
    ignore(projectText)
    ignore(sessionCount)
    ignore(projectCount)
    ignore(lastEvent)
    ignore(runningSessionCount)
    let displayedServer = if activeServer->String.includes("localhost") {
      "Local server"
    } else {
      activeServer
    }

  <section className="homePage">
    <div className="homeLogoWrap">
      <h1 className="homeLogo">{string("OpenCode")}</h1>
      <button className="homeServerPill" type_="button">
        <span
          className={if statusLine.className == "okText" {
            "homeServerDot ok"
          } else if statusLine.className == "errorText" {
            "homeServerDot error"
          } else {
            "homeServerDot"
          }}
        />
        {string(displayedServer)}
      </button>
    </div>

    {@show
    switch projects->Array.length > 0 {
    | true =>
      <div className="homeRecentBlock">
        <div className="homeRecentHeader">
          <h2>{string("Recent projects")}</h2>
          <R.Link href_="/workspace/session" inactiveClass_="homeRecentAction" activeClass_="homeRecentAction">
            {string("Open project")}
          </R.Link>
        </div>
        <ul className="homeRecentList">
          <For each_={projects} fallback_={<span></span>}>
            {(project, _index) =>
              <li className="homeRecentItem">
                <R.Link
                  href_="/workspace/session"
                  inactiveClass_="homeRecentPath"
                  activeClass_="homeRecentPath homeRecentPathActive">
                  {string(project.label)}
                </R.Link>
              </li>}
          </For>
        </ul>
      </div>
    | false =>
      <div className="homeEmptyState">
        <span className="homeEmptyIcon">{string("+")}</span>
        <h2>{string("No projects yet")}</h2>
        <p>{string("Open a directory to start a new session.")}</p>
        <R.Link href_="/workspace/session" inactiveClass_="homePrimaryAction" activeClass_="homePrimaryAction">
          {string("Open project")}
        </R.Link>
      </div>
    }}

    {@show switch statusLine.className == "errorText" {
    | true => <p className={statusLine.className}>{string(statusLine.text)}</p>
    | false => <span></span>
    }}
  </section>
  }
