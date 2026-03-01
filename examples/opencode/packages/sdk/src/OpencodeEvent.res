type refreshPath = [#none | #all | #projects | #sessions | #sessionStatuses | #activeSession]

type sessionScopedKind =
  | SessionDiff
  | TodoUpdated
  | MessageUpdated
  | MessageRemoved
  | MessagePartUpdated
  | MessagePartRemoved
  | MessagePartDelta
  | PermissionAsked
  | PermissionReplied
  | QuestionAsked
  | QuestionReplied
  | QuestionRejected

type sessionLifecycleEvent = {
  sessionId: option<string>,
  properties: JSON.t,
}

type sessionStatusKind =
  | Idle
  | Busy
  | Retry
  | Interrupted
  | ErrorStatus
  | UnknownStatus(string)

type sessionStatusEvent = {
  sessionId: string,
  status: sessionStatusKind,
  properties: JSON.t,
}

type sessionDeletedEvent = {
  sessionId: string,
  properties: JSON.t,
}

type queueKind = [#permission | #question]

type queueDelta = {
  sessionId: string,
  queue: queueKind,
  delta: int,
}

type queueRequestPayload = {
  queue: queueKind,
  sessionId: string,
  requestId: string,
}

type queueRequestMutation =
  | UpsertQueueRequest(queueRequestPayload)
  | RemoveQueueRequest(queueRequestPayload)

type activityMetric = [#messages | #parts | #deltaChars]

type activityDelta = {
  sessionId: string,
  metric: activityMetric,
  delta: int,
}

type messageRole =
  | UserRole
  | AssistantRole
  | ToolRole
  | SystemRole
  | UnknownMessageRole(string)

type partKind =
  | TextPart
  | ToolPart
  | FilePart
  | ReasoningPart
  | UnknownPartKind(string)

type todoStatus =
  | TodoOpen
  | TodoInProgress
  | TodoCompleted
  | TodoCancelled
  | UnknownTodoStatus(string)

type todoPriority =
  | PriorityHigh
  | PriorityMedium
  | PriorityLow
  | UnknownTodoPriority(string)

type messageSnapshot = {
  id: string,
  sessionId: string,
  role: option<messageRole>,
}

type partSnapshot = {
  id: string,
  sessionId: string,
  messageId: string,
  partType: option<partKind>,
}

type messageUpsertPayload = {
  message: messageSnapshot,
}

type messageRemovedPayload = {
  sessionId: string,
  messageId: string,
}

type partUpsertPayload = {
  part: partSnapshot,
}

type partRemovedPayload = {
  sessionId: option<string>,
  messageId: string,
  partId: string,
}

type partDeltaPayload = {
  sessionId: option<string>,
  messageId: string,
  partId: string,
  field: option<string>,
  deltaChars: int,
  deltaText: option<string>,
}

type messageMutation =
  | UpsertMessage(messageUpsertPayload)
  | RemoveMessage(messageRemovedPayload)
  | UpsertPart(partUpsertPayload)
  | RemovePart(partRemovedPayload)
  | AppendPartDelta(partDeltaPayload)

type fileDiff = {
  file: string,
  additions: option<float>,
  deletions: option<float>,
}

type todoItem = {
  id: string,
  content: string,
  status: todoStatus,
  priority: todoPriority,
}

type sessionDiffEvent = {
  sessionId: string,
  diff: array<fileDiff>,
}

type todoUpdatedEvent = {
  sessionId: string,
  todos: array<todoItem>,
}

type sessionScopedEvent = {
  kind: sessionScopedKind,
  sessionId: option<string>,
  properties: option<JSON.t>,
}

type projectUpdateEvent = {
  properties: JSON.t,
}

type unknownEvent = {
  type_: string,
  properties: option<JSON.t>,
}

type t =
  | GlobalDisposed
  | ServerConnected
  | ServerDisconnected
  | ServerInstanceDisposed
  | ProjectUpdated(projectUpdateEvent)
  | SessionCreated(sessionLifecycleEvent)
  | SessionUpdated(sessionLifecycleEvent)
  | SessionEnded(sessionLifecycleEvent)
  | SessionDeleted(sessionDeletedEvent)
  | SessionStatusChanged(sessionStatusEvent)
  | SessionScoped(sessionScopedEvent)
  | Unknown(unknownEvent)
  | InvalidPayload

type eventKind =
  | GlobalDisposedKind
  | ServerConnectedKind
  | ServerDisconnectedKind
  | ServerInstanceDisposedKind
  | ProjectUpdatedKind
  | SessionCreatedKind
  | SessionUpdatedKind
  | SessionEndedKind
  | SessionDeletedKind
  | SessionStatusChangedKind
  | SessionScopedKind(sessionScopedKind)
  | UnknownKind(string)
  | InvalidPayloadKind

let rec sessionIdFromPayload = (value: JSON.t): option<string> =>
  switch value {
  | Object(dict{"sessionID": JSON.String(sessionId)}) => Some(sessionId)
  | Object(dict{"sessionId": JSON.String(sessionId)}) => Some(sessionId)
  | Object(dict{"info": info}) => sessionIdFromPayload(info)
  | Object(dict{"session": session}) => sessionIdFromPayload(session)
  | _ => None
  }

let sessionIdFromSessionInfo = (value: JSON.t): option<string> =>
  switch value {
  | Object(dict{"info": JSON.Object(dict{"id": JSON.String(sessionId)})}) => Some(sessionId)
  | _ => None
  }

let sessionIdFromProperties = (properties: option<JSON.t>): option<string> =>
  switch properties {
  | Some(value) => sessionIdFromPayload(value)
  | None => None
  }

let rec messageIdFromPayload = (value: JSON.t): option<string> =>
  switch value {
  | Object(dict{"messageID": JSON.String(messageId)}) => Some(messageId)
  | Object(dict{"messageId": JSON.String(messageId)}) => Some(messageId)
  | Object(dict{"id": JSON.String(messageId)}) => Some(messageId)
  | Object(dict{"info": info}) => messageIdFromPayload(info)
  | Object(dict{"part": part}) => messageIdFromPayload(part)
  | _ => None
  }

let rec requestIdFromPayload = (value: JSON.t): option<string> =>
  switch value {
  | Object(dict{"requestID": JSON.String(requestId)}) => Some(requestId)
  | Object(dict{"requestId": JSON.String(requestId)}) => Some(requestId)
  | Object(dict{"id": JSON.String(requestId)}) => Some(requestId)
  | Object(dict{"info": info}) => requestIdFromPayload(info)
  | Object(dict{"request": request}) => requestIdFromPayload(request)
  | _ => None
  }

let rec partIdFromPayload = (value: JSON.t): option<string> =>
  switch value {
  | Object(dict{"partID": JSON.String(partId)}) => Some(partId)
  | Object(dict{"partId": JSON.String(partId)}) => Some(partId)
  | Object(dict{"id": JSON.String(partId)}) => Some(partId)
  | Object(dict{"part": part}) => partIdFromPayload(part)
  | _ => None
  }

let decodeMessageRoleString = (value: string): messageRole =>
  switch value {
  | "user" => UserRole
  | "assistant" => AssistantRole
  | "tool" => ToolRole
  | "system" => SystemRole
  | value => UnknownMessageRole(value)
  }

let decodePartKindString = (value: string): partKind =>
  switch value {
  | "text" => TextPart
  | "tool" => ToolPart
  | "file" => FilePart
  | "thinking" => ReasoningPart
  | "reasoning" => ReasoningPart
  | value => UnknownPartKind(value)
  }

let decodeTodoStatus = (value: string): todoStatus =>
  switch value {
  | "open" => TodoOpen
  | "in-progress" => TodoInProgress
  | "in_progress" => TodoInProgress
  | "completed" => TodoCompleted
  | "cancelled" => TodoCancelled
  | _ => UnknownTodoStatus(value)
  }

let decodeTodoPriority = (value: string): todoPriority =>
  switch value {
  | "high" => PriorityHigh
  | "medium" => PriorityMedium
  | "low" => PriorityLow
  | _ => UnknownTodoPriority(value)
  }

let decodeMessageSnapshot = (value: JSON.t): option<messageSnapshot> =>
  switch OpencodeEventDecoder.decodeMessageSnapshot(value) {
  | Some(snapshot) =>
    Some({
      id: snapshot.id,
      sessionId: snapshot.sessionId,
      role: snapshot.role->Option.map(decodeMessageRoleString),
    })
  | None => None
  }

let decodePartSnapshot = (value: JSON.t): option<partSnapshot> =>
  switch OpencodeEventDecoder.decodePartSnapshot(value) {
  | Some(snapshot) =>
    Some({
      id: snapshot.id,
      sessionId: snapshot.sessionId,
      messageId: snapshot.messageId,
      partType: snapshot.partType->Option.map(decodePartKindString),
    })
  | None => None
  }

let parseSessionStatusKind = (value: JSON.t): sessionStatusKind =>
  switch value {
  | JSON.String("idle") => Idle
  | JSON.String("busy") => Busy
  | JSON.String("retry") => Retry
  | JSON.String("interrupted") => Interrupted
  | JSON.String("error") => ErrorStatus
  | JSON.String(value) => UnknownStatus(value)
  | Object(dict{"type": JSON.String("idle")}) => Idle
  | Object(dict{"type": JSON.String("busy")}) => Busy
  | Object(dict{"type": JSON.String("retry")}) => Retry
  | Object(dict{"type": JSON.String("interrupted")}) => Interrupted
  | Object(dict{"type": JSON.String("error")}) => ErrorStatus
  | Object(dict{"type": JSON.String(value)}) => UnknownStatus(value)
  | _ => UnknownStatus("unknown")
  }

let sessionStatusKindToString = (status: sessionStatusKind): string =>
  switch status {
  | Idle => "idle"
  | Busy => "busy"
  | Retry => "retry"
  | Interrupted => "interrupted"
  | ErrorStatus => "error"
  | UnknownStatus(value) => value
  }

let decodeSessionStatusEvent = (properties: JSON.t): option<sessionStatusEvent> =>
  switch properties {
  | Object(dict{"sessionID": JSON.String(sessionId), "status": status}) =>
    Some({sessionId, status: parseSessionStatusKind(status), properties})
  | Object(dict{"sessionId": JSON.String(sessionId), "status": status}) =>
    Some({sessionId, status: parseSessionStatusKind(status), properties})
  | _ => None
  }

let decodeSessionDeletedEvent = (properties: JSON.t): option<sessionDeletedEvent> =>
  switch properties {
  | Object(dict{"info": JSON.Object(dict{"id": JSON.String(sessionId)})}) =>
    Some({sessionId, properties})
  | _ =>
    switch sessionIdFromPayload(properties) {
    | Some(sessionId) => Some({sessionId, properties})
    | None => None
    }
  }

let decodeSessionDiffEvent = (properties: JSON.t): option<sessionDiffEvent> =>
  switch OpencodeEventDecoder.decodeSessionDiffEvent(properties) {
  | Some(payload) =>
    Some({
      sessionId: payload.sessionId,
      diff:
        payload.diff->Array.map(item => {
          file: item.file,
          additions: item.additions,
          deletions: item.deletions,
        }),
    })
  | None => None
  }

let decodeTodoUpdatedEvent = (properties: JSON.t): option<todoUpdatedEvent> =>
  switch OpencodeEventDecoder.decodeTodoUpdatedEvent(properties) {
  | Some(payload) =>
    Some({
      sessionId: payload.sessionId,
      todos:
        payload.todos->Array.map(item => {
          id: item.id,
          content: item.content,
          status: item.status->decodeTodoStatus,
          priority: item.priority->decodeTodoPriority,
        }),
    })
  | None => None
  }

let decodeSessionScopedKind = (type_: string): option<sessionScopedKind> =>
  switch type_ {
  | "session.diff" => Some(SessionDiff)
  | "todo.updated" => Some(TodoUpdated)
  | "message.updated" => Some(MessageUpdated)
  | "message.removed" => Some(MessageRemoved)
  | "message.part.updated" => Some(MessagePartUpdated)
  | "message.part.removed" => Some(MessagePartRemoved)
  | "message.part.delta" => Some(MessagePartDelta)
  | "permission.asked" => Some(PermissionAsked)
  | "permission.replied" => Some(PermissionReplied)
  | "question.asked" => Some(QuestionAsked)
  | "question.replied" => Some(QuestionReplied)
  | "question.rejected" => Some(QuestionRejected)
  | _ => None
  }

let sessionScopedKindToString = (kind: sessionScopedKind): string =>
  switch kind {
  | SessionDiff => "session.diff"
  | TodoUpdated => "todo.updated"
  | MessageUpdated => "message.updated"
  | MessageRemoved => "message.removed"
  | MessagePartUpdated => "message.part.updated"
  | MessagePartRemoved => "message.part.removed"
  | MessagePartDelta => "message.part.delta"
  | PermissionAsked => "permission.asked"
  | PermissionReplied => "permission.replied"
  | QuestionAsked => "question.asked"
  | QuestionReplied => "question.replied"
  | QuestionRejected => "question.rejected"
  }

let decodeUnknownOrScoped = (~type_: string, ~properties: option<JSON.t>): t =>
  switch decodeSessionScopedKind(type_) {
  | Some(kind) =>
    SessionScoped({
      kind,
      sessionId: properties->sessionIdFromProperties,
      properties,
    })
  | None => Unknown({type_, properties})
  }

let decode = (value: JSON.t): t =>
  switch value {
  | Object(obj) =>
    switch obj {
    | dict{"type": JSON.String("global.disposed")} => GlobalDisposed
    | dict{"type": JSON.String("server.connected")} => ServerConnected
    | dict{"type": JSON.String("server.disconnected")} => ServerDisconnected
    | dict{"type": JSON.String("server.instance.disposed")} => ServerInstanceDisposed
    | dict{"type": JSON.String("project.updated"), "properties": properties} =>
      ProjectUpdated({properties: properties})
    | dict{"type": JSON.String("session.created"), "properties": properties} =>
      SessionCreated({sessionId: sessionIdFromSessionInfo(properties), properties})
    | dict{"type": JSON.String("session.updated"), "properties": properties} =>
      SessionUpdated({sessionId: sessionIdFromSessionInfo(properties), properties})
    | dict{"type": JSON.String("session.ended"), "properties": properties} =>
      SessionEnded({sessionId: sessionIdFromSessionInfo(properties), properties})
    | dict{"type": JSON.String("session.deleted"), "properties": properties} =>
      switch decodeSessionDeletedEvent(properties) {
      | Some(payload) => SessionDeleted(payload)
      | None => Unknown({type_: "session.deleted", properties: Some(properties)})
      }
    | dict{"type": JSON.String("session.status"), "properties": properties} =>
      switch decodeSessionStatusEvent(properties) {
      | Some(payload) => SessionStatusChanged(payload)
      | None => Unknown({type_: "session.status", properties: Some(properties)})
      }
    | dict{"type": JSON.String(type_), "properties": ?properties} =>
      decodeUnknownOrScoped(~type_, ~properties)
    | dict{"type": JSON.String(type_)} => decodeUnknownOrScoped(~type_, ~properties=None)
    | _ => InvalidPayload
    }
  | _ => InvalidPayload
  }

let kindTag = (event: t): eventKind =>
  switch event {
  | GlobalDisposed => GlobalDisposedKind
  | ServerConnected => ServerConnectedKind
  | ServerDisconnected => ServerDisconnectedKind
  | ServerInstanceDisposed => ServerInstanceDisposedKind
  | ProjectUpdated(_) => ProjectUpdatedKind
  | SessionCreated(_) => SessionCreatedKind
  | SessionUpdated(_) => SessionUpdatedKind
  | SessionEnded(_) => SessionEndedKind
  | SessionDeleted(_) => SessionDeletedKind
  | SessionStatusChanged(_) => SessionStatusChangedKind
  | SessionScoped({kind}) => SessionScopedKind(kind)
  | Unknown({type_}) => UnknownKind(type_)
  | InvalidPayload => InvalidPayloadKind
  }

let kindTagToString = (kindTag: eventKind): string =>
  switch kindTag {
  | GlobalDisposedKind => "global.disposed"
  | ServerConnectedKind => "server.connected"
  | ServerDisconnectedKind => "server.disconnected"
  | ServerInstanceDisposedKind => "server.instance.disposed"
  | ProjectUpdatedKind => "project.updated"
  | SessionCreatedKind => "session.created"
  | SessionUpdatedKind => "session.updated"
  | SessionEndedKind => "session.ended"
  | SessionDeletedKind => "session.deleted"
  | SessionStatusChangedKind => "session.status"
  | SessionScopedKind(kind) => kind->sessionScopedKindToString
  | UnknownKind(type_) => type_
  | InvalidPayloadKind => "invalid"
  }

let kind = (event: t): string =>
  event->kindTag->kindTagToString

let shouldRefresh = (event: t): bool =>
  switch event {
  | GlobalDisposed
  | ServerConnected
  | ServerDisconnected
  | ServerInstanceDisposed
  | ProjectUpdated(_)
  | SessionCreated(_)
  | SessionUpdated(_)
  | SessionEnded(_)
  | SessionDeleted(_)
  | SessionStatusChanged(_)
  | SessionScoped(_) => true
  | Unknown(_) | InvalidPayload => false
  }

let refreshPath = (event: t): refreshPath =>
  switch event {
  | GlobalDisposed | ServerConnected | ServerDisconnected | ServerInstanceDisposed => #all
  | ProjectUpdated(_) => #projects
  | SessionCreated(_) | SessionUpdated(_) | SessionEnded(_) | SessionDeleted(_) => #sessions
  | SessionStatusChanged(_) => #sessionStatuses
  | SessionScoped(_) => #activeSession
  | _ => #none
  }

let refreshPathToString = (path: refreshPath): string =>
  switch path {
  | #none => "none"
  | #all => "all"
  | #projects => "projects"
  | #sessions => "sessions"
  | #sessionStatuses => "session-statuses"
  | #activeSession => "active-session"
  }

let sessionId = (event: t): option<string> =>
  switch event {
  | SessionCreated({sessionId})
  | SessionUpdated({sessionId})
  | SessionEnded({sessionId}) => sessionId
  | SessionDeleted({sessionId}) => Some(sessionId)
  | SessionStatusChanged({sessionId}) => Some(sessionId)
  | SessionScoped({sessionId}) => sessionId
  | Unknown({properties}) => properties->sessionIdFromProperties
  | _ => None
  }

let sessionStatus = (event: t): option<sessionStatusEvent> =>
  switch event {
  | SessionStatusChanged(payload) => Some(payload)
  | _ => None
  }

let queueDeltaFromScoped = (event: sessionScopedEvent): option<queueDelta> =>
  switch (event.kind, event.sessionId) {
  | (PermissionAsked, Some(sessionId)) => Some({sessionId, queue: #permission, delta: 1})
  | (PermissionReplied, Some(sessionId)) => Some({sessionId, queue: #permission, delta: -1})
  | (QuestionAsked, Some(sessionId)) => Some({sessionId, queue: #question, delta: 1})
  | (QuestionReplied, Some(sessionId)) => Some({sessionId, queue: #question, delta: -1})
  | (QuestionRejected, Some(sessionId)) => Some({sessionId, queue: #question, delta: -1})
  | _ => None
  }

let queueDelta = (event: t): option<queueDelta> =>
  switch event {
  | SessionScoped(payload) => payload->queueDeltaFromScoped
  | _ => None
  }

let queueRequestPayloadFromScoped = (~event: sessionScopedEvent, ~queue: queueKind): option<queueRequestPayload> =>
  switch event.properties {
  | Some(properties) =>
    let decodedIds = OpencodeEventDecoder.decodeQueueRequestIds(properties)

    let decodedSessionId =
      switch event.sessionId {
      | Some(sessionId) => Some(sessionId)
      | None => decodedIds.sessionId
      }

    let sessionId =
      switch decodedSessionId {
      | Some(sessionId) => Some(sessionId)
      | None => properties->sessionIdFromPayload
      }

    let requestId =
      switch decodedIds.requestId {
      | Some(requestId) => Some(requestId)
      | None => properties->requestIdFromPayload
      }

    switch (
      sessionId,
      requestId,
    ) {
    | (Some(sessionId), Some(requestId)) => Some({queue, sessionId, requestId})
    | _ => None
    }
  | None => None
  }

let queueRequestMutationFromScoped = (event: sessionScopedEvent): option<queueRequestMutation> =>
  switch event.kind {
  | PermissionAsked =>
    switch queueRequestPayloadFromScoped(~event, ~queue=#permission) {
    | Some(payload) => Some(UpsertQueueRequest(payload))
    | None => None
    }
  | PermissionReplied =>
    switch queueRequestPayloadFromScoped(~event, ~queue=#permission) {
    | Some(payload) => Some(RemoveQueueRequest(payload))
    | None => None
    }
  | QuestionAsked =>
    switch queueRequestPayloadFromScoped(~event, ~queue=#question) {
    | Some(payload) => Some(UpsertQueueRequest(payload))
    | None => None
    }
  | QuestionReplied | QuestionRejected =>
    switch queueRequestPayloadFromScoped(~event, ~queue=#question) {
    | Some(payload) => Some(RemoveQueueRequest(payload))
    | None => None
    }
  | _ => None
  }

let queueRequestMutation = (event: t): option<queueRequestMutation> =>
  switch event {
  | SessionScoped(payload) => payload->queueRequestMutationFromScoped
  | _ => None
  }

let sessionDiffFromScoped = (event: sessionScopedEvent): option<sessionDiffEvent> =>
  switch (event.kind, event.properties) {
  | (SessionDiff, Some(properties)) => decodeSessionDiffEvent(properties)
  | _ => None
  }

let todoUpdatedFromScoped = (event: sessionScopedEvent): option<todoUpdatedEvent> =>
  switch (event.kind, event.properties) {
  | (TodoUpdated, Some(properties)) => decodeTodoUpdatedEvent(properties)
  | _ => None
  }

let sessionDiff = (event: t): option<sessionDiffEvent> =>
  switch event {
  | SessionScoped(payload) => payload->sessionDiffFromScoped
  | _ => None
  }

let todoUpdated = (event: t): option<todoUpdatedEvent> =>
  switch event {
  | SessionScoped(payload) => payload->todoUpdatedFromScoped
  | _ => None
  }

let rec deltaLengthFromPayload = (value: JSON.t): option<int> =>
  switch value {
  | Object(dict{"delta": JSON.String(text)}) => Some(text->String.length)
  | Object(dict{"delta": delta}) => deltaLengthFromPayload(delta)
  | Object(dict{"part": part}) => deltaLengthFromPayload(part)
  | Object(dict{"text": JSON.String(text)}) => Some(text->String.length)
  | _ => None
  }

let rec deltaTextFromPayload = (value: JSON.t): option<string> =>
  switch value {
  | Object(dict{"delta": JSON.String(text)}) =>
    if text == "" {
      None
    } else {
      Some(text)
    }
  | Object(dict{"delta": delta}) => deltaTextFromPayload(delta)
  | Object(dict{"part": part}) => deltaTextFromPayload(part)
  | Object(dict{"text": JSON.String(text)}) =>
    if text == "" {
      None
    } else {
      Some(text)
    }
  | _ => None
  }

let activityDeltaFromScoped = (event: sessionScopedEvent): option<activityDelta> =>
  switch (event.kind, event.sessionId) {
  | (MessageUpdated, Some(sessionId)) => Some({sessionId, metric: #messages, delta: 1})
  | (MessageRemoved, Some(sessionId)) => Some({sessionId, metric: #messages, delta: -1})
  | (MessagePartUpdated, Some(sessionId)) => Some({sessionId, metric: #parts, delta: 1})
  | (MessagePartRemoved, Some(sessionId)) => Some({sessionId, metric: #parts, delta: -1})
  | (MessagePartDelta, Some(sessionId)) => {
      let delta =
        switch event.properties {
        | Some(properties) => properties->deltaLengthFromPayload->Option.getOr(0)
        | None => 0
        }
      if delta > 0 {
        Some({sessionId, metric: #deltaChars, delta})
      } else {
        None
      }
    }
  | _ => None
  }

let activityDelta = (event: t): option<activityDelta> =>
  switch event {
  | SessionScoped(payload) => payload->activityDeltaFromScoped
  | _ => None
  }

let messageMutationFromScoped = (event: sessionScopedEvent): option<messageMutation> =>
  switch event.kind {
  | MessageUpdated =>
    switch event.properties {
    | Some(Object(dict{"info": info})) =>
      switch decodeMessageSnapshot(info) {
      | Some(message) => Some(UpsertMessage({message: message}))
      | None => None
      }
    | Some(properties) =>
      switch decodeMessageSnapshot(properties) {
      | Some(message) => Some(UpsertMessage({message: message}))
      | None => None
      }
    | _ => None
    }
  | MessageRemoved =>
    switch event.properties {
    | Some(properties) =>
      switch OpencodeEventDecoder.decodeMessageRemovedPayload(properties) {
      | Some(payload) => Some(RemoveMessage({sessionId: payload.sessionId, messageId: payload.messageId}))
      | None =>
        switch (event.sessionId, properties->messageIdFromPayload) {
        | (Some(sessionId), Some(messageId)) => Some(RemoveMessage({sessionId, messageId}))
        | _ => None
        }
      }
    | None => None
    }
  | MessagePartUpdated =>
    switch event.properties {
    | Some(Object(dict{"part": part})) =>
      switch decodePartSnapshot(part) {
      | Some(part) => Some(UpsertPart({part: part}))
      | None => None
      }
    | Some(properties) =>
      switch decodePartSnapshot(properties) {
      | Some(part) => Some(UpsertPart({part: part}))
      | None =>
        switch (event.sessionId, properties->messageIdFromPayload, properties->partIdFromPayload) {
        | (Some(sessionId), Some(messageId), Some(partId)) =>
          Some(
            UpsertPart({
              part: {
                id: partId,
                sessionId,
                messageId,
                partType: None,
              },
            }),
          )
        | _ => None
        }
      }
    | None => None
    }
  | MessagePartRemoved =>
    switch event.properties {
    | Some(properties) =>
      switch OpencodeEventDecoder.decodePartRemovedPayload(properties) {
      | Some(payload) => Some(RemovePart({sessionId: event.sessionId, messageId: payload.messageId, partId: payload.partId}))
      | None =>
        switch (properties->messageIdFromPayload, properties->partIdFromPayload) {
        | (Some(messageId), Some(partId)) =>
          Some(RemovePart({sessionId: event.sessionId, messageId, partId}))
        | _ => None
        }
      }
    | None => None
    }
  | MessagePartDelta =>
    switch event.properties {
    | Some(properties) =>
      let deltaChars = properties->deltaLengthFromPayload->Option.getOr(0)
      let deltaText = properties->deltaTextFromPayload
      if deltaChars <= 0 && deltaText->Option.isNone {
        None
      } else {
        switch OpencodeEventDecoder.decodePartDeltaPayload(properties) {
        | Some(payload) =>
          Some(
            AppendPartDelta({
              sessionId: event.sessionId,
              messageId: payload.messageId,
              partId: payload.partId,
              field: payload.field,
              deltaChars,
              deltaText,
            }),
          )
        | None =>
          switch (properties->messageIdFromPayload, properties->partIdFromPayload) {
          | (Some(messageId), Some(partId)) =>
            Some(
              AppendPartDelta({
                sessionId: event.sessionId,
                messageId,
                partId,
                field: None,
                deltaChars,
                deltaText,
              }),
            )
          | _ => None
          }
        }
      }
    | None => None
    }
  | _ => None
  }

let messageMutation = (event: t): option<messageMutation> =>
  switch event {
  | SessionScoped(payload) => payload->messageMutationFromScoped
  | _ => None
  }

let sessionDeleted = (event: t): option<sessionDeletedEvent> =>
  switch event {
  | SessionDeleted(payload) => Some(payload)
  | _ => None
  }

let properties = (event: t): option<JSON.t> =>
  switch event {
  | ProjectUpdated({properties})
  | SessionCreated({properties})
  | SessionUpdated({properties})
  | SessionEnded({properties}) => Some(properties)
  | SessionDeleted({properties}) => Some(properties)
  | SessionStatusChanged({properties}) => Some(properties)
  | SessionScoped({properties})
  | Unknown({properties}) => properties
  | _ => None
  }

let decodeKind = (value: JSON.t): string => value->decode->kind

let decodeKindTag = (value: JSON.t): eventKind => value->decode->kindTag

let decodeShouldRefresh = (value: JSON.t): bool => value->decode->shouldRefresh

let decodeRefreshPath = (value: JSON.t): string => value->decode->refreshPath->refreshPathToString

let decodeSessionId = (value: JSON.t): option<string> => value->decode->sessionId

let decodeSessionStatusKind = (value: JSON.t): option<string> =>
  switch value->decode->sessionStatus {
  | Some({status}) => Some(status->sessionStatusKindToString)
  | None => None
  }

let decodeQueueDelta = (value: JSON.t): option<queueDelta> => value->decode->queueDelta

let decodeActivityDelta = (value: JSON.t): option<activityDelta> => value->decode->activityDelta

let decodeMessageMutation = (value: JSON.t): option<messageMutation> => value->decode->messageMutation

let decodeQueueRequestMutation = (value: JSON.t): option<queueRequestMutation> =>
  value->decode->queueRequestMutation

let decodeSessionDiffFileCount = (value: JSON.t): option<int> =>
  switch value->decode->sessionDiff {
  | Some({diff}) => Some(diff->Array.length)
  | None => None
  }

let decodeTodoCount = (value: JSON.t): option<int> =>
  switch value->decode->todoUpdated {
  | Some({todos}) => Some(todos->Array.length)
  | None => None
  }
