open Solid

module R = SolidRouter

type displayedSession = {
  id: string,
  subtitle: string,
}

type mobileSessionTab =
  | Main
  | Side

type mediaQueryList

@val @scope("window")
external matchMediaUnsafe: string => mediaQueryList = "matchMedia"

@send
external mediaMatches: mediaQueryList => bool = "matches"

@send
external mediaAddEventListener: (mediaQueryList, string, unit => unit) => unit = "addEventListener"

@send
external mediaRemoveEventListener: (mediaQueryList, string, unit => unit) => unit = "removeEventListener"

@jsx.component
let make = (
  ~workspaceDirectory: string,
  ~sessionRouteId: string,
  ~statusText: string,
  ~displayedSession: option<displayedSession>,
  ~hasSessionMetadata: bool,
  ~hasSessionActivity: bool,
  ~conversationPanel: element,
  ~composerRegion: element,
  ~sidePanel: element,
  ~backHref: string,
) => {
  let (isMobileLayout, setIsMobileLayout) = createSignal(false)
  let (activeMobileTab, setActiveMobileTab) = createSignal(Main)
  ignore(hasSessionMetadata)
  ignore(hasSessionActivity)

  onMount(() => {
    let mediaQuery = matchMediaUnsafe("(max-width: 960px)")
    let syncMobileLayout = () => {
      let isMobile = mediaQuery->mediaMatches
      setIsMobileLayout(_ => isMobile)
      if !isMobile {
        setActiveMobileTab(_ => Main)
      }
    }

    syncMobileLayout()
    mediaQuery->mediaAddEventListener("change", syncMobileLayout)
    onCleanup(() => mediaQuery->mediaRemoveEventListener("change", syncMobileLayout))
  })

  let statusClass = switch statusText {
  | "running" => "sessionStatusPill running"
  | "idle" => "sessionStatusPill"
  | _ => ""
  }

  let headerStatusElement = switch displayedSession {
  | Some(session) => <p className="sessionTopSubtitle">{string(session.subtitle)}</p>
  | None => <span></span>
  }

  let sessionMainStack =
    <div className="sessionMainStack">
      {conversationPanel}
      {composerRegion}
    </div>

  let sessionBodyElement = switch isMobileLayout() {
  | true =>
    <div className="sessionMobileLayout">
      <div className="sessionMobileTabs">
        <button
          type_="button"
          className={if activeMobileTab() == Main {"sessionMobileTabBtn active"} else {"sessionMobileTabBtn"}}
          onClick={_ => setActiveMobileTab(_ => Main)}>
          {string("Session")}
        </button>
        <button
          type_="button"
          className={if activeMobileTab() == Side {"sessionMobileTabBtn active"} else {"sessionMobileTabBtn"}}
          onClick={_ => setActiveMobileTab(_ => Side)}>
          {string("Side Panel")}
        </button>
      </div>
      <div className="sessionBody">
        {switch activeMobileTab() {
        | Main => sessionMainStack
        | Side => sidePanel
        }}
      </div>
    </div>
  | false =>
    <div className="sessionBody">
      {sessionMainStack}
      {sidePanel}
    </div>
  }

  <section className="sessionView">
    <header className="sessionTopBar">
      <div className="sessionTopMain">
        <div className="sessionTopTitleRow">
          <h2>{string(workspaceDirectory)}</h2>
          {@show switch statusClass != "" {
          | true => <span className={statusClass}>{string(statusText)}</span>
          | false => <span></span>
          }}
        </div>
        <p className="sessionTopSubtitle">
          {string(if sessionRouteId == "latest" {"new session"} else {`session/${sessionRouteId}`})}
        </p>
        {headerStatusElement}
      </div>

      <R.Link href_={backHref} inactiveClass_="inlineLink sessionBackLink" activeClass_="inlineLink sessionBackLink">
        {string("Back")}
      </R.Link>
    </header>

    {sessionBodyElement}
  </section>
}
