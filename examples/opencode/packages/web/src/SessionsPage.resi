open Solid

@jsx.component
let make: (
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
) => Solid.element
