type observedEvent = {
  kind: OpencodeEvent.eventKind,
  refreshPath: OpencodeEvent.refreshPath,
  sessionId: option<string>,
}

type handlers = {
  refreshAll: unit => unit,
  refreshProjects: unit => unit,
  refreshSessions: unit => unit,
  refreshStatuses: unit => unit,
  applySessionDeleted: OpencodeEvent.sessionDeletedEvent => unit,
  applySessionStatusChanged: OpencodeEvent.sessionStatusEvent => unit,
  applySessionScoped: OpencodeEvent.sessionScopedEvent => unit,
  refreshSessionById: string => unit,
  activeSessionId: unit => option<string>,
  onObservedEvent: observedEvent => unit,
}

let apply: (~event: OpencodeEvent.t, ~handlers: handlers) => unit
