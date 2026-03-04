open Solid

module For = SolidJSX.For

type sessionInfo = {
  id: string,
  title: string,
  updatedAt: string,
  status: string,
}

type projectRow = {
  name: string,
  path: string,
}

type reviewMode =
  | Unified
  | Split

type reviewRow = {
  id: int,
  text: string,
}

type sideTab =
  | ReviewTab
  | FilesTab

@jsx.component
let make = (
  ~serverLookupError: option<string>,
  ~recentEvents: array<string>,
  ~sessionInfo: option<sessionInfo>,
  ~contextLines: array<string>,
  ~projectRows: array<projectRow>,
) => {
  ignore(sessionInfo)
  ignore(contextLines)
  let (reviewMode, setReviewMode) = createSignal(Unified)
  let (reviewCollapsed, setReviewCollapsed) = createSignal(false)
  let (activeTab, setActiveTab) = createSignal(ReviewTab)
  let reviewRows =
    recentEvents
    ->Array.mapWithIndex((line, index) => {
      let number = index + 1
      ({
        id: number,
        text: line,
      }: reviewRow)
    })

  let reviewContent = switch reviewCollapsed() {
  | true => <p className="loadingText">{string("Review rows collapsed. Expand to inspect changes.")}</p>
  | false =>
    switch reviewRows->Array.length > 0 {
    | true =>
      <ul className="reviewEventList">
        <For each_={reviewRows} fallback_={<li className="reviewEventRow">{string("No activity yet")}</li>}>
          {(row, _index) =>
            <li className="reviewEventRow">
              <span className="reviewEventLineNo">{string(row.id->Int.toString)}</span>
              <span className="reviewEventText">{string(row.text)}</span>
            </li>}
        </For>
      </ul>
    | false =>
      <p className="loadingText">
        {string("No activity yet. Events appear here after the next stream update.")}
      </p>
    }
  }

  let filesContent = switch projectRows->Array.length > 0 {
  | true =>
    <ul className="sideProjectList">
      <For each_={projectRows} fallback_={<li className="sideProjectRow">{string("No files yet")}</li>}>
        {(row, _index) =>
          <li className="sideProjectRow">
            <span className="eventKind">{string(row.name)}</span>
            <span className="sessionMeta">{string(row.path)}</span>
          </li>}
      </For>
    </ul>
  | false =>
    <p className="loadingText">
      {string("No files available for this session yet.")}
    </p>
  }

  <aside className="sessionSideRail">
    <section
      className={if reviewMode() == Split {
        "sideCard reviewPane split"
      } else {
        "sideCard reviewPane unified"
      }}>
      <header className="reviewPaneHeader">
        <div className="reviewPaneTabs">
          <button
            className={if activeTab() == ReviewTab {"reviewTabBtn active"} else {"reviewTabBtn"}}
            type_="button"
            onClick={_ => setActiveTab(_ => ReviewTab)}>
            {string("Review")}
          </button>
          <button
            className={if activeTab() == FilesTab {"reviewTabBtn active"} else {"reviewTabBtn"}}
            type_="button"
            onClick={_ => setActiveTab(_ => FilesTab)}>
            {string("Files")}
          </button>
        </div>
        <span className="badge">
          {string(
            switch activeTab() {
            | ReviewTab => recentEvents->Array.length->Int.toString
            | FilesTab => projectRows->Array.length->Int.toString
            },
          )}
        </span>
      </header>

      {@show switch activeTab() {
      | ReviewTab =>
        <div className="reviewPaneControls">
          <p className="sessionRoute">{string("Session changes")}</p>
          <div className="reviewPaneControlActions">
            <button
              className={if reviewMode() == Unified {"reviewModeBtn active"} else {"reviewModeBtn"}}
              type_="button"
              onClick={_ => setReviewMode(_ => Unified)}>
              {string("Unified")}
            </button>
            <button
              className={if reviewMode() == Split {"reviewModeBtn active"} else {"reviewModeBtn"}}
              type_="button"
              onClick={_ => setReviewMode(_ => Split)}>
              {string("Split")}
            </button>
            <button
              className="reviewModeBtn"
              type_="button"
              onClick={_ => setReviewCollapsed(prev => !prev)}>
              {string(if reviewCollapsed() {"Expand all"} else {"Collapse all"})}
            </button>
          </div>
        </div>
      | FilesTab =>
        <p className="sessionRoute">{string("Session files and workspace paths")}</p>
      }}

      {@show switch serverLookupError {
      | Some(error) => <p className="errorText">{string(`Server lookup failed: ${error}`)}</p>
      | None => <span></span>
      }}
      {switch activeTab() {
      | ReviewTab => reviewContent
      | FilesTab => filesContent
      }}
    </section>
  </aside>
}