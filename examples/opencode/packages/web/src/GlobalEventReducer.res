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

let apply = (~event: OpencodeEvent.t, ~handlers: handlers): unit => {
  let kind = OpencodeEvent.kindTag(event)
  let refreshPath = OpencodeEvent.refreshPath(event)
  let sessionId = OpencodeEvent.sessionId(event)

  handlers.onObservedEvent({kind, refreshPath, sessionId})

  switch event {
  | GlobalDisposed | ServerConnected | ServerDisconnected | ServerInstanceDisposed =>
    handlers.refreshAll()
  | ProjectUpdated(_) => handlers.refreshProjects()
  | SessionCreated(_) | SessionUpdated(_) | SessionEnded(_) => {
      handlers.refreshSessions()
      handlers.refreshStatuses()
    }
  | SessionDeleted(payload) => handlers.applySessionDeleted(payload)
  | SessionStatusChanged(payload) => handlers.applySessionStatusChanged(payload)
  | SessionScoped(payload) => {
      handlers.applySessionScoped(payload)
      handlers.refreshStatuses()
      switch (payload.sessionId, handlers.activeSessionId()) {
      | (Some(targetSessionId), Some(activeSessionId)) if targetSessionId == activeSessionId =>
        handlers.refreshSessionById(targetSessionId)
      | _ => ()
      }
    }
  | Unknown({type_}) if type_ == "session.deleted" => {
      handlers.refreshSessions()
      handlers.refreshStatuses()
    }
  | Unknown({type_}) if type_ == "session.status" => handlers.refreshStatuses()
  | Unknown(_) | InvalidPayload => ()
  }
}
