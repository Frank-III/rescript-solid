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

let reverseItems = (items: array<'a>): array<'a> =>
  items->Array.reduce([], (acc, item) => Array.concat([item], acc))

let findSessionStatus = (items: array<OpencodeClient.sessionStatusItem>, sessionId: string): option<
  OpencodeClient.sessionStatus,
> =>
  items->Array.reduce(None, (found, item) =>
    switch found {
    | Some(_) => found
    | None =>
      if item.id == sessionId {
        Some(item.status)
      } else {
        None
      }
    }
  )

let countRunningSessions = (items: array<OpencodeClient.sessionStatusItem>): int =>
  items->Array.reduce(0, (count, item) =>
    switch item.status {
    | #running => count + 1
    | #idle => count
    }
  )

let countTrackedQueueRequests = (
  ~items: array<queueRequest>,
  ~sessionId: string,
  ~queue: OpencodeEvent.queueKind,
): int =>
  items->Array.reduce(0, (count, item) =>
    if item.queue == queue && item.sessionId == sessionId {
      count + 1
    } else {
      count
    }
  )

let trackedTodoCountForSession = (items: array<trackedTodo>, sessionId: string): int =>
  items
  ->Array.findMap(item =>
    if item.sessionId == sessionId {
      Some(item.todoCount)
    } else {
      None
    }
  )
  ->Option.getOr(0)

let trackedDiffFileCountForSession = (items: array<trackedDiff>, sessionId: string): int =>
  items
  ->Array.findMap(item =>
    if item.sessionId == sessionId {
      Some(item.diffFileCount)
    } else {
      None
    }
  )
  ->Option.getOr(0)

let renderTrackedPartFragment = (part: trackedPart): string =>
  switch part.text->String.trim {
  | "" =>
    if part.streamedChars > 0 {
      `[streaming ${part.streamedChars->Int.toString} chars]`
    } else {
      ""
    }
  | _ => part.text
  }

let combineTrackedPartText = (parts: array<trackedPart>): string =>
  parts->Array.reduce("", (combined, part) => {
    let fragment = part->renderTrackedPartFragment
    if fragment == "" {
      combined
    } else if combined == "" {
      fragment
    } else {
      `${combined}\n${fragment}`
    }
  })

let derive = (
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
): result => {
  let selected = sessions->Array.reduce(None, (found, item) =>
    switch found {
    | Some(_) => found
    | None =>
      if item.id == sessionId {
        Some(item)
      } else {
        None
      }
    }
  )

  let focusedMatch = switch focusedSession {
  | Some(session) if sessionId == "latest" || session.id == sessionId => Some(session)
  | _ => None
  }

  let hasSessionMetadata = selected->Option.isSome || focusedMatch->Option.isSome

  let displayedSession = switch selected {
  | Some(session) => Some(session)
  | None =>
    switch focusedMatch {
    | Some(session) => Some(session)
    | None =>
      if sessionId == "latest" {
        None
      } else {
        Some({id: sessionId, title: None, updatedAt: None})
      }
    }
  }

  let counterSessionId = if sessionId == "latest" {
    switch displayedSession {
    | Some(session) => session.id
    | None => sessionId
    }
  } else {
    sessionId
  }

  let pendingPermissionCount = countTrackedQueueRequests(
    ~items=trackedQueueRequests,
    ~sessionId=counterSessionId,
    ~queue=#permission,
  )
  let pendingQuestionCount = countTrackedQueueRequests(
    ~items=trackedQueueRequests,
    ~sessionId=counterSessionId,
    ~queue=#question,
  )
  let sessionMessages = trackedMessages->Array.filter(item => item.sessionId == counterSessionId)
  let sessionParts = trackedParts->Array.filter(item => item.sessionId == counterSessionId)
  let trackedTodoCount = trackedTodoCountForSession(trackedTodos, counterSessionId)
  let trackedDiffFileCount = trackedDiffFileCountForSession(trackedDiffs, counterSessionId)
  let messageCount = sessionMessages->Array.length
  let messagePartCount = sessionParts->Array.length
  let streamedCharCount = sessionParts->Array.reduce(0, (count, item) => count + item.streamedChars)
  let routeStatus = findSessionStatus(sessionStatuses, counterSessionId)
  let hasSessionActivity =
    routeStatus->Option.isSome ||
    pendingPermissionCount > 0 ||
    pendingQuestionCount > 0 ||
    trackedTodoCount > 0 ||
    trackedDiffFileCount > 0 ||
    messageCount > 0 ||
    messagePartCount > 0 ||
    streamedCharCount > 0

  let effectiveRouteStatus = switch routeStatus {
  | Some(status) => Some(status)
  | None =>
    if hasSessionActivity {
      Some(#running)
    } else {
      None
    }
  }

  let knownMessages = sessionMessages->Array.map(item => item.message)
  let mergedMessages = sessionParts->Array.reduce(knownMessages, (messages, part) => {
    let exists = messages->Array.some(message => message.id == part.messageId)
    if exists {
      messages
    } else {
      let inferredMessage: OpencodeEvent.messageSnapshot = {
        id: part.messageId,
        sessionId: part.sessionId,
        role: None,
      }
      Array.concat([inferredMessage], messages)
    }
  })

  let conversationRows =
    mergedMessages
    ->reverseItems
    ->Array.map(message => {
      let messageParts = sessionParts->Array.filter(part => part.messageId == message.id)->reverseItems
      let combinedText = messageParts->combineTrackedPartText
      let row: conversationRow = {
        message,
        text: switch combinedText->String.trim {
        | "" => "[awaiting streamed content]"
        | _ => combinedText
        },
        partCount: messageParts->Array.length,
      }
      row
    })
    ->Array.filter(row => row.partCount > 0 || row.message.role != None)

  let contextLines = [
    `Filter scope: ${sessionQueryText}`,
    `Known sessions: ${sessions->Array.length->Int.toString}`,
    `Running sessions: ${sessionStatuses->countRunningSessions->Int.toString}`,
    `Pending permissions: ${pendingPermissionCount->Int.toString}`,
    `Pending questions: ${pendingQuestionCount->Int.toString}`,
    `Todos tracked: ${trackedTodoCount->Int.toString}`,
    `Diff files tracked: ${trackedDiffFileCount->Int.toString}`,
    `Messages tracked: ${messageCount->Int.toString}`,
    `Message parts tracked: ${messagePartCount->Int.toString}`,
    `Streamed chars: ${streamedCharCount->Int.toString}`,
  ]

  {
    displayedSession,
    hasSessionMetadata,
    composerTargetSessionId: counterSessionId,
    pendingPermissionCount,
    pendingQuestionCount,
    trackedTodoCount,
    trackedDiffFileCount,
    messageCount,
    messagePartCount,
    streamedCharCount,
    routeStatus,
    effectiveRouteStatus,
    hasSessionActivity,
    conversationRows,
    contextLines,
  }
}
