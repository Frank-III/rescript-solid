let _ = S.enableJson()

type fileDiff = {
  file: string,
  additions: option<float>,
  deletions: option<float>,
}

type todoItem = {
  id: string,
  content: string,
  status: string,
  priority: string,
}

type sessionDiffEvent = {
  sessionId: string,
  diff: array<fileDiff>,
}

type todoUpdatedEvent = {
  sessionId: string,
  todos: array<todoItem>,
}

type messageSnapshot = {
  id: string,
  sessionId: string,
  role: option<string>,
}

type partSnapshot = {
  id: string,
  sessionId: string,
  messageId: string,
  partType: option<string>,
}

type messageRemovedPayload = {
  sessionId: string,
  messageId: string,
}

type partRemovedPayload = {
  messageId: string,
  partId: string,
}

type partDeltaPayload = {
  messageId: string,
  partId: string,
  field: option<string>,
}

type queueRequestIds = {
  sessionId: option<string>,
  requestId: option<string>,
}

type sessionScopedIds = {
  sessionId: option<string>,
  sessionID: option<string>,
}

type messageScopedIds = {
  messageId: option<string>,
  messageID: option<string>,
}

type partScopedIds = {
  partId: option<string>,
  partID: option<string>,
}

let parse = (value: JSON.t, schema: S.t<'a>): option<'a> =>
  try {
    Some(S.parseOrThrow(value, schema))
  } catch {
  | S.Error(_) => None
  | _ => None
  }

let fromEitherSessionId = (~sessionId: option<string>, ~sessionID: option<string>): option<string> =>
  switch sessionId {
  | Some(sessionId) => Some(sessionId)
  | None => sessionID
  }

let fromEitherMessageId = (~messageId: option<string>, ~messageID: option<string>): option<string> =>
  switch messageId {
  | Some(messageId) => Some(messageId)
  | None => messageID
  }

let fromEitherPartId = (~partId: option<string>, ~partID: option<string>): option<string> =>
  switch partId {
  | Some(partId) => Some(partId)
  | None => partID
  }

let fromEitherRequestId = (
  ~requestId: option<string>,
  ~requestID: option<string>,
  ~id: option<string>,
): option<string> =>
  switch requestId {
  | Some(requestId) => Some(requestId)
  | None =>
    switch requestID {
    | Some(requestID) => Some(requestID)
    | None => id
    }
  }

let decodeFileDiff = (value: JSON.t): option<fileDiff> =>
  switch value {
  | Object(dict{"file": JSON.String(file), "additions": ?additions, "deletions": ?deletions}) => {
      let additions =
        switch additions {
        | Some(JSON.Number(count)) => Some(count)
        | _ => None
        }
      let deletions =
        switch deletions {
        | Some(JSON.Number(count)) => Some(count)
        | _ => None
        }
      Some({file, additions, deletions})
    }
  | _ => None
  }

type sessionDiffRaw = {
  sessionId: option<string>,
  sessionID: option<string>,
  diff: array<JSON.t>,
}

let sessionDiffRawSchema: S.t<sessionDiffRaw> =
  S.object(s => {
    sessionId: s.field("sessionId", S.option(S.string)),
    sessionID: s.field("sessionID", S.option(S.string)),
    diff: s.field("diff", S.array(S.json)),
  })

let decodeSessionDiffEvent = (value: JSON.t): option<sessionDiffEvent> =>
  switch parse(value, sessionDiffRawSchema) {
  | Some(payload) =>
    switch fromEitherSessionId(~sessionId=payload.sessionId, ~sessionID=payload.sessionID) {
    | Some(sessionId) => Some({sessionId, diff: payload.diff->Array.filterMap(decodeFileDiff)})
    | None => None
    }
  | None => None
  }

let todoItemSchema: S.t<todoItem> =
  S.object(s => {
    id: s.field("id", S.string),
    content: s.field("content", S.string),
    status: s.field("status", S.string),
    priority: s.field("priority", S.string),
  })

type todoUpdatedRaw = {
  sessionId: option<string>,
  sessionID: option<string>,
  todos: array<JSON.t>,
}

let todoUpdatedRawSchema: S.t<todoUpdatedRaw> =
  S.object(s => {
    sessionId: s.field("sessionId", S.option(S.string)),
    sessionID: s.field("sessionID", S.option(S.string)),
    todos: s.field("todos", S.array(S.json)),
  })

let decodeTodoUpdatedEvent = (value: JSON.t): option<todoUpdatedEvent> =>
  switch parse(value, todoUpdatedRawSchema) {
  | Some(payload) =>
    switch fromEitherSessionId(~sessionId=payload.sessionId, ~sessionID=payload.sessionID) {
    | Some(sessionId) =>
      Some({sessionId, todos: payload.todos->Array.filterMap(item => parse(item, todoItemSchema))})
    | None => None
    }
  | None => None
  }

type messageSnapshotRaw = {
  id: string,
  sessionId: option<string>,
  sessionID: option<string>,
  role: option<string>,
}

let messageSnapshotRawSchema: S.t<messageSnapshotRaw> =
  S.object(s => {
    id: s.field("id", S.string),
    sessionId: s.field("sessionId", S.option(S.string)),
    sessionID: s.field("sessionID", S.option(S.string)),
    role: s.field("role", S.option(S.string)),
  })

let decodeMessageSnapshot = (value: JSON.t): option<messageSnapshot> =>
  switch parse(value, messageSnapshotRawSchema) {
  | Some(payload) =>
    switch fromEitherSessionId(~sessionId=payload.sessionId, ~sessionID=payload.sessionID) {
    | Some(sessionId) => Some({id: payload.id, sessionId, role: payload.role})
    | None => None
    }
  | None => None
  }

type partSnapshotRaw = {
  id: string,
  sessionId: option<string>,
  sessionID: option<string>,
  messageId: option<string>,
  messageID: option<string>,
  partType: option<string>,
}

let partSnapshotRawSchema: S.t<partSnapshotRaw> =
  S.object(s => {
    id: s.field("id", S.string),
    sessionId: s.field("sessionId", S.option(S.string)),
    sessionID: s.field("sessionID", S.option(S.string)),
    messageId: s.field("messageId", S.option(S.string)),
    messageID: s.field("messageID", S.option(S.string)),
    partType: s.field("type", S.option(S.string)),
  })

let decodePartSnapshot = (value: JSON.t): option<partSnapshot> =>
  switch parse(value, partSnapshotRawSchema) {
  | Some(payload) =>
    switch (
      fromEitherSessionId(~sessionId=payload.sessionId, ~sessionID=payload.sessionID),
      fromEitherMessageId(~messageId=payload.messageId, ~messageID=payload.messageID),
    ) {
    | (Some(sessionId), Some(messageId)) =>
      Some({id: payload.id, sessionId, messageId, partType: payload.partType})
    | _ => None
    }
  | None => None
  }

let sessionScopedIdsSchema: S.t<sessionScopedIds> =
  S.object(s => {
    sessionId: s.field("sessionId", S.option(S.string)),
    sessionID: s.field("sessionID", S.option(S.string)),
  })

let messageScopedIdsSchema: S.t<messageScopedIds> =
  S.object(s => {
    messageId: s.field("messageId", S.option(S.string)),
    messageID: s.field("messageID", S.option(S.string)),
  })

let partScopedIdsSchema: S.t<partScopedIds> =
  S.object(s => {
    partId: s.field("partId", S.option(S.string)),
    partID: s.field("partID", S.option(S.string)),
  })

let decodeMessageRemovedPayload = (value: JSON.t): option<messageRemovedPayload> =>
  switch (parse(value, sessionScopedIdsSchema), parse(value, messageScopedIdsSchema)) {
  | (Some(sessionPayload), Some(messagePayload)) =>
    switch (
      fromEitherSessionId(~sessionId=sessionPayload.sessionId, ~sessionID=sessionPayload.sessionID),
      fromEitherMessageId(~messageId=messagePayload.messageId, ~messageID=messagePayload.messageID),
    ) {
    | (Some(sessionId), Some(messageId)) => Some({sessionId, messageId})
    | _ => None
    }
  | _ => None
  }

let decodePartRemovedPayload = (value: JSON.t): option<partRemovedPayload> =>
  switch (parse(value, messageScopedIdsSchema), parse(value, partScopedIdsSchema)) {
  | (Some(messagePayload), Some(partPayload)) =>
    switch (
      fromEitherMessageId(~messageId=messagePayload.messageId, ~messageID=messagePayload.messageID),
      fromEitherPartId(~partId=partPayload.partId, ~partID=partPayload.partID),
    ) {
    | (Some(messageId), Some(partId)) => Some({messageId, partId})
    | _ => None
    }
  | _ => None
  }

type partDeltaRaw = {
  messageId: option<string>,
  messageID: option<string>,
  partId: option<string>,
  partID: option<string>,
  field: option<string>,
}

let partDeltaRawSchema: S.t<partDeltaRaw> =
  S.object(s => {
    messageId: s.field("messageId", S.option(S.string)),
    messageID: s.field("messageID", S.option(S.string)),
    partId: s.field("partId", S.option(S.string)),
    partID: s.field("partID", S.option(S.string)),
    field: s.field("field", S.option(S.string)),
  })

let decodePartDeltaPayload = (value: JSON.t): option<partDeltaPayload> =>
  switch parse(value, partDeltaRawSchema) {
  | Some(payload) =>
    switch (
      fromEitherMessageId(~messageId=payload.messageId, ~messageID=payload.messageID),
      fromEitherPartId(~partId=payload.partId, ~partID=payload.partID),
    ) {
    | (Some(messageId), Some(partId)) => Some({messageId, partId, field: payload.field})
    | _ => None
    }
  | None => None
  }

type queueRequestRaw = {
  sessionId: option<string>,
  sessionID: option<string>,
  requestId: option<string>,
  requestID: option<string>,
  id: option<string>,
  info: option<JSON.t>,
  request: option<JSON.t>,
  session: option<JSON.t>,
}

let queueRequestRawSchema: S.t<queueRequestRaw> =
  S.object(s => {
    sessionId: s.field("sessionId", S.option(S.string)),
    sessionID: s.field("sessionID", S.option(S.string)),
    requestId: s.field("requestId", S.option(S.string)),
    requestID: s.field("requestID", S.option(S.string)),
    id: s.field("id", S.option(S.string)),
    info: s.field("info", S.option(S.json)),
    request: s.field("request", S.option(S.json)),
    session: s.field("session", S.option(S.json)),
  })

let mergeQueueRequestIds = (primary: queueRequestIds, fallback: queueRequestIds): queueRequestIds => {
  sessionId:
    switch primary.sessionId {
    | Some(sessionId) => Some(sessionId)
    | None => fallback.sessionId
    },
  requestId:
    switch primary.requestId {
    | Some(requestId) => Some(requestId)
    | None => fallback.requestId
    },
}

let rec decodeQueueRequestIds = (value: JSON.t): queueRequestIds =>
  switch parse(value, queueRequestRawSchema) {
  | Some(payload) => {
      let direct = {
        sessionId: fromEitherSessionId(~sessionId=payload.sessionId, ~sessionID=payload.sessionID),
        requestId:
          fromEitherRequestId(
            ~requestId=payload.requestId,
            ~requestID=payload.requestID,
            ~id=payload.id,
          ),
      }

      let fromInfo =
        switch payload.info {
        | Some(info) => decodeQueueRequestIds(info)
        | None => {sessionId: None, requestId: None}
        }

      let fromRequest =
        switch payload.request {
        | Some(request) => decodeQueueRequestIds(request)
        | None => {sessionId: None, requestId: None}
        }

      let fromSession =
        switch payload.session {
        | Some(session) => decodeQueueRequestIds(session)
        | None => {sessionId: None, requestId: None}
        }

      direct
      ->mergeQueueRequestIds(fromInfo)
      ->mergeQueueRequestIds(fromRequest)
      ->mergeQueueRequestIds(fromSession)
    }
  | None => {sessionId: None, requestId: None}
  }
