open Solid

@get external getInputValue: {..} => string = "value"

@jsx.component
let make = (
  ~directoryDraft: string,
  ~searchDraft: string,
  ~limitDraft: string,
  ~onDirectoryDraftChange: string => unit,
  ~onSearchDraftChange: string => unit,
  ~onLimitDraftChange: string => unit,
  ~onApplyFilters: unit => unit,
  ~onClearFilters: unit => unit,
  ~activeQueryText: string,
  ~eventsList: element,
) =>
  <section className="panel sessionsPanel">
    <h2>{string("Sessions")}</h2>
    <div className="queryGrid">
      <label>
        <span>{string("Directory")}</span>
        <input
          id="sessions-directory-filter"
          type_="text"
          value={directoryDraft}
          onInput={event => {
            let value = event->JsxEvent.Form.target->getInputValue
            onDirectoryDraftChange(value)
          }}
          placeholder="workspace"
        />
      </label>
      <label>
        <span>{string("Search")}</span>
        <input
          id="sessions-search-filter"
          type_="text"
          value={searchDraft}
          onInput={event => {
            let value = event->JsxEvent.Form.target->getInputValue
            onSearchDraftChange(value)
          }}
          placeholder="title text"
        />
      </label>
      <label>
        <span>{string("Limit")}</span>
        <input
          id="sessions-limit-filter"
          type_="number"
          value={limitDraft}
          onInput={event => {
            let value = event->JsxEvent.Form.target->getInputValue
            onLimitDraftChange(value)
          }}
          placeholder="25"
          min="1"
        />
      </label>
    </div>
    <div className="queryActions">
      <button id="sessions-apply-filters-btn" className="refreshBtn" onClick={_ => onApplyFilters()}>
        {string("Apply filters")}
      </button>
      <button id="sessions-clear-filters-btn" className="ghostBtn" onClick={_ => onClearFilters()}>
        {string("Clear")}
      </button>
      <span className="streamMeta">{string(`Active query: ${activeQueryText}`)}</span>
    </div>

    {eventsList}
  </section>
