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

let decode: JSON.t => t
let kindTag: t => eventKind
let kindTagToString: eventKind => string
let kind: t => string
let shouldRefresh: t => bool
let refreshPath: t => refreshPath
let refreshPathToString: refreshPath => string
let sessionId: t => option<string>
let sessionStatus: t => option<sessionStatusEvent>
let queueDeltaFromScoped: sessionScopedEvent => option<queueDelta>
let queueDelta: t => option<queueDelta>
let queueRequestPayloadFromScoped: (~event: sessionScopedEvent, ~queue: queueKind) => option<queueRequestPayload>
let queueRequestMutationFromScoped: sessionScopedEvent => option<queueRequestMutation>
let queueRequestMutation: t => option<queueRequestMutation>
let sessionDiffFromScoped: sessionScopedEvent => option<sessionDiffEvent>
let todoUpdatedFromScoped: sessionScopedEvent => option<todoUpdatedEvent>
let sessionDiff: t => option<sessionDiffEvent>
let todoUpdated: t => option<todoUpdatedEvent>
let activityDeltaFromScoped: sessionScopedEvent => option<activityDelta>
let activityDelta: t => option<activityDelta>
let messageMutationFromScoped: sessionScopedEvent => option<messageMutation>
let messageMutation: t => option<messageMutation>
let sessionDeleted: t => option<sessionDeletedEvent>
let properties: t => option<JSON.t>
let decodeKindTag: JSON.t => eventKind
let decodeKind: JSON.t => string
let decodeShouldRefresh: JSON.t => bool
let decodeRefreshPath: JSON.t => string
let decodeSessionId: JSON.t => option<string>
let decodeSessionStatusKind: JSON.t => option<string>
let decodeQueueDelta: JSON.t => option<queueDelta>
let decodeActivityDelta: JSON.t => option<activityDelta>
let decodeMessageMutation: JSON.t => option<messageMutation>
let decodeQueueRequestMutation: JSON.t => option<queueRequestMutation>
let decodeSessionDiffFileCount: JSON.t => option<int>
let decodeTodoCount: JSON.t => option<int>
