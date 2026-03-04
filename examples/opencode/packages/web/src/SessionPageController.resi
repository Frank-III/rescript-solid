type queueRequest = {
  queue: OpencodeEvent.queueKind,
  sessionId: string,
}

type trackedMessage = {
  sessionId: string,
  message: OpencodeEvent.messageSnapshot,
}

type trackedPart = {
  sessionId: string,
  messageId: string,
  streamedChars: int,
  text: string,
}

type trackedTodo = {
  sessionId: string,
  todoCount: int,
}

type trackedDiff = {
  sessionId: string,
  diffFileCount: int,
}

type conversationRow = {
  message: OpencodeEvent.messageSnapshot,
  text: string,
  partCount: int,
}

type result = {
  displayedSession: option<OpencodeClient.sessionSummary>,
  hasSessionMetadata: bool,
  composerTargetSessionId: string,
  pendingPermissionCount: int,
  pendingQuestionCount: int,
  trackedTodoCount: int,
  trackedDiffFileCount: int,
  messageCount: int,
  messagePartCount: int,
  streamedCharCount: int,
  routeStatus: option<OpencodeClient.sessionStatus>,
  effectiveRouteStatus: option<OpencodeClient.sessionStatus>,
  hasSessionActivity: bool,
  conversationRows: array<conversationRow>,
  contextLines: array<string>,
}

let derive: (
  ~sessionId: string,
  ~sessionQueryText: string,
  ~sessions: array<OpencodeClient.sessionSummary>,
  ~focusedSession: option<OpencodeClient.sessionSummary>,
  ~sessionStatuses: array<OpencodeClient.sessionStatusItem>,
  ~trackedQueueRequests: array<queueRequest>,
  ~trackedMessages: array<trackedMessage>,
  ~trackedParts: array<trackedPart>,
  ~trackedTodos: array<trackedTodo>,
  ~trackedDiffs: array<trackedDiff>,
) => result
