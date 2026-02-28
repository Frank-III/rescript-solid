open Solid

module R = SolidRouter
module EventReducer = GlobalEventReducer

@get external getInputValue: {..} => string = "value"
@get external getKeyboardKey: JsxEvent.Keyboard.t => string = "key"
@get external getKeyboardShiftKey: JsxEvent.Keyboard.t => bool = "shiftKey"
@send external preventDefault: JsxEvent.Keyboard.t => unit = "preventDefault"
@val external browserStorage: option<{..}> = "window.localStorage"
@send external storageGetItem: ({..}, string) => Nullable.t<string> = "getItem"
@send external storageSetItem: ({..}, string, string) => unit = "setItem"
@send external storageRemoveItem: ({..}, string) => unit = "removeItem"

type fetchState =
  | Loading
  | Ready
  | Failed(string)

type trackedQueueRequest = {
  queue: OpencodeEvent.queueKind,
  sessionId: string,
  requestId: string,
}

type trackedMessage = {
  sessionId: string,
  message: OpencodeEvent.messageSnapshot,
}

type trackedPart = {
  sessionId: string,
  messageId: string,
  part: OpencodeEvent.partSnapshot,
  streamedChars: int,
  text: string,
}

type trackedTodoState = {
  sessionId: string,
  todos: array<OpencodeEvent.todoItem>,
}

type trackedDiffState = {
  sessionId: string,
  diff: array<OpencodeEvent.fileDiff>,
}

type conversationRow = {
  message: OpencodeEvent.messageSnapshot,
  text: string,
  partCount: int,
}

let renderProject = (project: option<OpencodeClient.project>): string =>
  switch project {
  | None => "No active project returned by /project/current"
  | Some(project) => {
      let id = project.id->Option.getOr("unknown-id")
      let name = project.name->Option.getOr("unnamed")
      let path = project.path->Option.getOr("unknown-path")
      `${name} (${id}) at ${path}`
    }
  }

let renderProjectLabel = (project: OpencodeClient.project): string => {
  let name = project.name->Option.getOr("unnamed")
  let path = project.path->Option.getOr("unknown-path")
  `${name} - ${path}`
}

let renderSessionSubtitle = (session: OpencodeClient.sessionSummary): string => {
  let title = session.title->Option.getOr("(untitled)")
  let updatedAt = session.updatedAt->Option.getOr("unknown-updated-time")
  `${title} - ${updatedAt}`
}

let renderSessionStatus = (status: option<OpencodeClient.sessionStatus>): string =>
  switch status {
  | Some(#running) => "running"
  | Some(#idle) => "idle"
  | None => "unknown"
  }

let renderMessageRole = (role: option<OpencodeEvent.messageRole>): string =>
  switch role {
  | Some(OpencodeEvent.UserRole) => "User"
  | Some(OpencodeEvent.AssistantRole) => "Assistant"
  | Some(OpencodeEvent.ToolRole) => "Tool"
  | Some(OpencodeEvent.SystemRole) => "System"
  | Some(OpencodeEvent.UnknownMessageRole(value)) => value
  | None => "Message"
  }

let messageRoleClass = (role: option<OpencodeEvent.messageRole>): string =>
  switch role {
  | Some(OpencodeEvent.UserRole) => "chatUser"
  | Some(OpencodeEvent.AssistantRole) => "chatAssistant"
  | Some(OpencodeEvent.ToolRole) => "chatTool"
  | Some(OpencodeEvent.SystemRole) => "chatSystem"
  | Some(OpencodeEvent.UnknownMessageRole(_))
  | None => "chatUnknown"
  }

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

let reverseItems = (items: array<'a>): array<'a> =>
  items->Array.reduce([], (acc, item) => Array.concat([item], acc))

let countRunningSessions = (items: array<OpencodeClient.sessionStatusItem>): int =>
  items->Array.reduce(0, (count, item) =>
    switch item.status {
    | #running => count + 1
    | #idle => count
    }
  )

let findSessionStatus = (
  items: array<OpencodeClient.sessionStatusItem>,
  sessionId: string,
): option<OpencodeClient.sessionStatus> =>
  items->Array.reduce(None, (found, item) =>
    switch found {
    | Some(_) => found
    | None => if item.id == sessionId {Some(item.status)} else {None}
    }
  )

let countTrackedQueueRequests = (
  ~items: array<trackedQueueRequest>,
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

let upsertTrackedQueueRequest = (
  ~items: array<trackedQueueRequest>,
  ~queue: OpencodeEvent.queueKind,
  ~sessionId: string,
  ~requestId: string,
): array<trackedQueueRequest> => {
  let exists =
    items->Array.some(item =>
      item.queue == queue && item.sessionId == sessionId && item.requestId == requestId
    )
  if exists {
    items
  } else {
    [{queue, sessionId, requestId}, ...items]
  }
}

let removeTrackedQueueRequest = (
  ~items: array<trackedQueueRequest>,
  ~queue: OpencodeEvent.queueKind,
  ~sessionId: string,
  ~requestId: string,
): array<trackedQueueRequest> =>
  items->Array.filter(item => !(item.queue == queue && item.sessionId == sessionId && item.requestId == requestId))

let upsertTrackedTodoState = (
  ~items: array<trackedTodoState>,
  ~sessionId: string,
  ~todos: array<OpencodeEvent.todoItem>,
): array<trackedTodoState> => {
  let remaining = items->Array.filter(item => item.sessionId != sessionId)
  [{sessionId, todos}, ...remaining]
}

let upsertTrackedDiffState = (
  ~items: array<trackedDiffState>,
  ~sessionId: string,
  ~diff: array<OpencodeEvent.fileDiff>,
): array<trackedDiffState> => {
  let remaining = items->Array.filter(item => item.sessionId != sessionId)
  [{sessionId, diff}, ...remaining]
}

let trackedTodoCountForSession = (items: array<trackedTodoState>, sessionId: string): int =>
  items
  ->Array.findMap(item => if item.sessionId == sessionId {Some(item.todos->Array.length)} else {None})
  ->Option.getOr(0)

let trackedDiffFileCountForSession = (items: array<trackedDiffState>, sessionId: string): int =>
  items
  ->Array.findMap(item => if item.sessionId == sessionId {Some(item.diff->Array.length)} else {None})
  ->Option.getOr(0)

let upsertTrackedMessage = (
  ~items: array<trackedMessage>,
  ~message: OpencodeEvent.messageSnapshot,
): array<trackedMessage> => {
  let exists =
    items->Array.some(item => item.sessionId == message.sessionId && item.message.id == message.id)
  if exists {
    items->Array.map(item =>
      if item.sessionId == message.sessionId && item.message.id == message.id {
        {sessionId: message.sessionId, message}
      } else {
        item
      }
    )
  } else {
    [{sessionId: message.sessionId, message}, ...items]
  }
}

let removeTrackedMessage = (
  ~items: array<trackedMessage>,
  ~sessionId: string,
  ~messageId: string,
): array<trackedMessage> =>
  items->Array.filter(item => !(item.sessionId == sessionId && item.message.id == messageId))

let upsertTrackedPart = (
  ~items: array<trackedPart>,
  ~part: OpencodeEvent.partSnapshot,
): array<trackedPart> => {
  let exists =
    items->Array.some(item =>
      item.sessionId == part.sessionId
      && item.messageId == part.messageId
      && item.part.id == part.id
    )
  if exists {
    items->Array.map(item =>
      if item.sessionId == part.sessionId && item.messageId == part.messageId && item.part.id == part.id {
        {...item, part}
      } else {
        item
      }
    )
  } else {
    [{sessionId: part.sessionId, messageId: part.messageId, part, streamedChars: 0, text: ""}, ...items]
  }
}

let removeTrackedPart = (
  ~items: array<trackedPart>,
  ~sessionId: option<string>,
  ~messageId: string,
  ~partId: string,
): array<trackedPart> =>
  items->Array.filter(part =>
    switch sessionId {
    | Some(requiredSessionId) =>
      !(part.sessionId == requiredSessionId && part.messageId == messageId && part.part.id == partId)
    | None => !(part.messageId == messageId && part.part.id == partId)
    }
  )

let appendTrackedPartDelta = (
  ~items: array<trackedPart>,
  ~sessionId: option<string>,
  ~messageId: string,
  ~partId: string,
  ~deltaChars: int,
  ~deltaText: option<string>,
): array<trackedPart> => {
  let appendedText = deltaText->Option.getOr("")
  let hasAppendedText = appendedText != ""

  if deltaChars <= 0 && !hasAppendedText {
    items
  } else {
    let hasMatch =
      items->Array.some(part =>
        switch sessionId {
        | Some(requiredSessionId) =>
          part.sessionId == requiredSessionId && part.messageId == messageId && part.part.id == partId
        | None => part.messageId == messageId && part.part.id == partId
        }
      )

    if hasMatch {
      items->Array.map(part =>
        switch sessionId {
        | Some(requiredSessionId) if
            part.sessionId == requiredSessionId && part.messageId == messageId && part.part.id == partId =>
          {
            ...part,
            streamedChars: part.streamedChars + deltaChars,
            text: if hasAppendedText {`${part.text}${appendedText}`} else {part.text},
          }
        | None if part.messageId == messageId && part.part.id == partId =>
          {
            ...part,
            streamedChars: part.streamedChars + deltaChars,
            text: if hasAppendedText {`${part.text}${appendedText}`} else {part.text},
          }
        | _ => part
        }
      )
    } else {
      switch sessionId {
      | Some(foundSessionId) =>
        [{
          sessionId: foundSessionId,
          messageId,
          part: {
            id: partId,
            sessionId: foundSessionId,
            messageId,
            partType: None,
          },
          streamedChars: deltaChars,
          text: appendedText,
        }, ...items]
      | None => items
      }
    }
  }
}

let sessionStatusFromEventKind = (
  status: OpencodeEvent.sessionStatusKind,
): OpencodeClient.sessionStatus =>
  switch status {
  | OpencodeEvent.Idle => #idle
  | OpencodeEvent.Busy
  | OpencodeEvent.Retry
  | OpencodeEvent.Interrupted
  | OpencodeEvent.ErrorStatus
  | OpencodeEvent.UnknownStatus(_) => #running
  }

let normalizeQueryText = (value: string): option<string> => {
  let trimmed = value->String.trim
  if trimmed == "" {
    None
  } else {
    Some(trimmed)
  }
}

let normalizeQueryLimit = (value: string): option<int> =>
  switch value->String.trim->Int.fromString {
  | Some(limit) if limit > 0 => Some(limit)
  | _ => None
  }

let buildSessionQuery = (
  ~directoryText: string,
  ~searchText: string,
  ~limitText: string,
): option<OpencodeClient.sessionQuery> => {
  let directory = normalizeQueryText(directoryText)
  let search = normalizeQueryText(searchText)
  let limit = normalizeQueryLimit(limitText)

  if directory == None && search == None && limit == None {
    None
  } else {
    Some({directory, search, limit})
  }
}

let renderSessionQuery = (query: option<OpencodeClient.sessionQuery>): string =>
  switch query {
  | None => "No filters"
  | Some({directory, search, limit}) => {
      let directoryText = directory->Option.getOr("any-dir")
      let searchText = search->Option.getOr("any-text")
      let limitText =
        switch limit {
        | Some(value) => value->Int.toString
        | None => "default"
        }
      `dir=${directoryText}, search=${searchText}, limit=${limitText}`
    }
  }

let routeDirectoryForSessions = (query: option<OpencodeClient.sessionQuery>): string =>
  switch query {
  | Some({directory: Some(directory)}) => directory
  | _ => "workspace"
  }

let composerModelStorageKey = "opencode.settings.dat:composerModelOverride"
let customModelSentinel = "__custom__"

let modelPresetOptions = [
  ("anthropic/claude-sonnet-4-5", "Claude Sonnet 4.5"),
  ("anthropic/claude-opus-4-1", "Claude Opus 4.1"),
  ("openai/gpt-5", "GPT-5"),
  ("openai/gpt-5-mini", "GPT-5 Mini"),
  ("openai/gpt-5.3-codex", "GPT-5.3 Codex"),
]

let isKnownModelPreset = (value: string): bool =>
  modelPresetOptions->Array.some(((presetValue, _)) => presetValue == value)

let getStoredComposerModel = (): option<string> =>
  try {
    switch browserStorage {
    | Some(storage) =>
      storage->storageGetItem(composerModelStorageKey)->Nullable.toOption->Option.flatMap(normalizeQueryText)
    | None => None
    }
  } catch {
  | _ => None
  }

let setStoredComposerModel = (value: string): unit =>
  try {
    switch browserStorage {
    | Some(storage) =>
      switch value->normalizeQueryText {
      | Some(trimmed) => storage->storageSetItem(composerModelStorageKey, trimmed)
      | None => storage->storageRemoveItem(composerModelStorageKey)
      }
    | None => ()
    }
  } catch {
  | _ => ()
  }

let rememberFirstError = (firstError: ref<option<string>>, message: string) =>
  if firstError.contents->Option.isNone {
    firstError.contents = Some(message)
  }

let syncRequestState = (setState: setter<fetchState>, firstError: option<string>) =>
  switch firstError {
  | Some(message) => setState(_ => Failed(message))
  | None => setState(_ => Ready)
  }

let renderObservedEvent = (event: EventReducer.observedEvent): string => {
  let sessionSuffix =
    switch event.sessionId {
    | Some(sessionId) => ` [${sessionId}]`
    | None => ""
    }
  `${event.kind->OpencodeEvent.kindTagToString}${sessionSuffix} -> ${event.refreshPath->OpencodeEvent.refreshPathToString}`
}

@jsx.component
let make = (~defaultServer: string) => {
  let platformValue = PlatformContext.web()

  let fallbackServer =
    switch platformValue.getDefaultServerUrl() {
    | Some(value) =>
      switch value->String.trim {
      | "" => "http://localhost:4096"
      | trimmed => trimmed
      }
    | None => "http://localhost:4096"
    }

  let initialServer =
    switch defaultServer->String.trim {
    | "" => fallbackServer
    | value => value
    }

  let (activeServer, setActiveServer) = createSignal(initialServer)
  let (serverDraft, setServerDraft) = createSignal(initialServer)
  let (healthText, setHealthText) = createSignal("Loading /global/health ...")
  let (projectText, setProjectText) = createSignal("Loading /project/current ...")
  let (projects, setProjects) = createSignal([])
  let (sessions, setSessions) = createSignal([])
  let (sessionStatuses, setSessionStatuses) = createSignal([])
  let (sessionDirectoryDraft, setSessionDirectoryDraft) = createSignal("")
  let (sessionSearchDraft, setSessionSearchDraft) = createSignal("")
  let (sessionLimitDraft, setSessionLimitDraft) = createSignal("")
  let (sessionQuery, setSessionQuery) = createSignal((None: option<OpencodeClient.sessionQuery>))
  let (focusedSessionId, setFocusedSessionId) = createSignal((None: option<string>))
  let (focusedSession, setFocusedSession) = createSignal((None: option<OpencodeClient.sessionSummary>))
  let (focusedSessionError, setFocusedSessionError) = createSignal((None: option<string>))
  let (trackedQueueRequests, setTrackedQueueRequests) = createSignal(([]: array<trackedQueueRequest>))
  let (trackedTodos, setTrackedTodos) = createSignal(([]: array<trackedTodoState>))
  let (trackedDiffs, setTrackedDiffs) = createSignal(([]: array<trackedDiffState>))
  let (trackedMessages, setTrackedMessages) = createSignal(([]: array<trackedMessage>))
  let (trackedParts, setTrackedParts) = createSignal(([]: array<trackedPart>))
  let (recentEvents, setRecentEvents) = createSignal(([]: array<EventReducer.observedEvent>))
  let (composerDraft, setComposerDraft) = createSignal("")
  let initialComposerModel = getStoredComposerModel()->Option.getOr("")
  let (composerModelDraft, setComposerModelDraft) = createSignal(initialComposerModel)
  let (composerCustomModelEnabled, setComposerCustomModelEnabled) =
    createSignal(
      switch initialComposerModel->normalizeQueryText {
      | Some(value) => !isKnownModelPreset(value)
      | None => false
      },
    )
  let (composerError, setComposerError) = createSignal((None: option<string>))
  let (isComposerSending, setIsComposerSending) = createSignal(false)
  let (streamStatus, setStreamStatus) = createSignal("disconnected")
  let (streamError, setStreamError) = createSignal((None: option<string>))
  let (streamEventCount, setStreamEventCount) = createSignal(0)
  let (streamLastEventKind, setStreamLastEventKind) = createSignal((None: option<string>))
  let (state, setState) = createSignal(Loading)
  let client = createMemo(() => OpencodeClient.make(~serverUrl=activeServer(), ()))

  let loadHealthData = async (~firstError: ref<option<string>>) => {
    let sdk = client()
    switch await OpencodeClient.health(sdk) {
    | Ok(health) => {
        let versionSuffix =
          switch health.version {
          | Some(version) => ` (version ${version})`
          | None => ""
          }
        setHealthText(_ => `${health.status}${versionSuffix}`)
      }
    | Error(error) => {
        rememberFirstError(firstError, OpencodeClient.errorToString(error))
        setHealthText(_ => "Unavailable")
      }
    }
  }

  let loadProjectData = async (~firstError: ref<option<string>>) => {
    let sdk = client()

    switch await OpencodeClient.projectCurrent(sdk) {
    | Ok(project) => setProjectText(_ => renderProject(project))
    | Error(error) => {
        rememberFirstError(firstError, OpencodeClient.errorToString(error))
        setProjectText(_ => "Unavailable")
      }
    }

    switch await OpencodeClient.projects(sdk) {
    | Ok(items) => setProjects(_ => items)
    | Error(error) => {
        rememberFirstError(firstError, OpencodeClient.errorToString(error))
        setProjects(_ => [])
      }
    }
  }

  let loadSessionListData = async (
    ~query: option<OpencodeClient.sessionQuery>,
    ~firstError: ref<option<string>>,
  ) => {
    let sdk = client()

    switch await OpencodeClient.sessions(sdk, ~query=?query, ()) {
    | Ok(items) => setSessions(_ => items)
    | Error(error) => {
        rememberFirstError(firstError, OpencodeClient.errorToString(error))
        setSessions(_ => [])
      }
    }
  }

  let loadSessionStatusData = async (
    ~query: option<OpencodeClient.sessionQuery>,
    ~firstError: ref<option<string>>,
  ) => {
    let sdk = client()

    switch await OpencodeClient.sessionStatuses(sdk, ~query=?query, ()) {
    | Ok(items) => setSessionStatuses(_ => items)
    | Error(error) => {
        rememberFirstError(firstError, OpencodeClient.errorToString(error))
        setSessionStatuses(_ => [])
      }
    }
  }

  let loadSessionData = async (
    ~query: option<OpencodeClient.sessionQuery>,
    ~firstError: ref<option<string>>,
  ) => {
    await loadSessionListData(~query, ~firstError)
    await loadSessionStatusData(~query, ~firstError)
  }

  createEffect(() => {
    setStoredComposerModel(composerModelDraft())
  })

  let hydrateSessionConversationById = async (~sessionId: string) => {
    let sdk = client()
    switch await OpencodeClient.sessionMessages(sdk, ~sessionId) {
    | Ok(messages) => {
        let hydratedMessages =
          messages->Array.map(message => {
            let snapshot: OpencodeEvent.messageSnapshot = {
              id: message.id,
              sessionId: message.sessionId,
              role: message.role,
            }
            {
              sessionId: message.sessionId,
              message: snapshot,
            }
          })

        let hydratedParts =
          messages
          ->Array.reduce([], (partsAcc, message) =>
            message.parts->Array.reduce(partsAcc, (innerAcc, part) => {
              let snapshot: OpencodeEvent.partSnapshot = {
                id: part.id,
                sessionId: part.sessionId,
                messageId: part.messageId,
                partType: part.partType,
              }
              innerAcc->Array.concat([{
                sessionId: part.sessionId,
                messageId: part.messageId,
                part: snapshot,
                streamedChars: part.text->String.length,
                text: part.text,
              }])
            })
          )

        setTrackedMessages(items => {
          let sessionItems = items->Array.filter(item => item.sessionId == sessionId)
          let remaining = items->Array.filter(item => item.sessionId != sessionId)
          let mergedSessionItems =
            hydratedMessages->Array.reduce(sessionItems, (acc, hydrated) =>
              upsertTrackedMessage(~items=acc, ~message=hydrated.message)
            )
          Array.concat(mergedSessionItems, remaining)
        })

        setTrackedParts(items => {
          let sessionItems = items->Array.filter(item => item.sessionId == sessionId)
          let remaining = items->Array.filter(item => item.sessionId != sessionId)
          let mergedSessionItems =
            hydratedParts->Array.reduce(sessionItems, (acc, hydratedPart) => {
              let withPart = upsertTrackedPart(~items=acc, ~part=hydratedPart.part)
              withPart->Array.map(item =>
                if item.sessionId == hydratedPart.sessionId && item.messageId == hydratedPart.messageId && item.part.id == hydratedPart.part.id {
                  {
                    ...item,
                    streamedChars: hydratedPart.streamedChars,
                    text: if hydratedPart.text != "" {hydratedPart.text} else {item.text},
                  }
                } else {
                  item
                }
              )
            })
          Array.concat(mergedSessionItems, remaining)
        })
      }
    | Error(_) => ()
    }
  }

  let loadFocusedSessionById = async (~sessionId: string) => {
    let sdk = client()
    switch await OpencodeClient.sessionById(sdk, ~sessionId) {
    | Ok(found) => {
        setFocusedSession(_ => found)
        setFocusedSessionError(_ => None)
        let _ = await hydrateSessionConversationById(~sessionId)
      }
    | Error(error) => {
        setFocusedSession(_ => None)
        setFocusedSessionError(_ => Some(OpencodeClient.errorToString(error)))
      }
    }
  }

  let appendObservedEvent = (event: EventReducer.observedEvent) =>
    setRecentEvents(events => {
      let capped = [event, ...events]
      let seen = ref(0)
      capped->Array.filter(_ => {
        let keep = seen.contents < 60
        seen.contents = seen.contents + 1
        keep
      })
    })

  let applySessionStatusChanged = (payload: OpencodeEvent.sessionStatusEvent) => {
    let nextStatus = payload.status->sessionStatusFromEventKind
    let nextItem: OpencodeClient.sessionStatusItem = {
      id: payload.sessionId,
      status: nextStatus,
    }

    setSessionStatuses(items => {
      let hasExisting = items->Array.some(item => item.id == payload.sessionId)
      let updated =
        items->Array.map(item =>
          if item.id == payload.sessionId {
            nextItem
          } else {
            item
          }
        )

      if hasExisting {
        updated
      } else {
        [nextItem, ...updated]
      }
    })
  }

  let applySessionDeleted = (payload: OpencodeEvent.sessionDeletedEvent) => {
    setSessions(items => items->Array.filter(item => item.id != payload.sessionId))
    setSessionStatuses(items => items->Array.filter(item => item.id != payload.sessionId))
    setTrackedQueueRequests(items => items->Array.filter(item => item.sessionId != payload.sessionId))
    setTrackedTodos(items => items->Array.filter(item => item.sessionId != payload.sessionId))
    setTrackedDiffs(items => items->Array.filter(item => item.sessionId != payload.sessionId))
    setTrackedMessages(items => items->Array.filter(item => item.sessionId != payload.sessionId))
    setTrackedParts(items => items->Array.filter(item => item.sessionId != payload.sessionId))

    switch focusedSessionId() {
    | Some(activeSessionId) if activeSessionId == payload.sessionId => {
        setFocusedSession(_ => None)
        setFocusedSessionError(_ => None)
      }
    | _ => ()
    }
  }

  let applySessionScoped = (payload: OpencodeEvent.sessionScopedEvent) =>
    {
      switch payload->OpencodeEvent.queueRequestMutationFromScoped {
      | Some(OpencodeEvent.UpsertQueueRequest({queue, sessionId, requestId})) =>
        setTrackedQueueRequests(items => upsertTrackedQueueRequest(~items, ~queue, ~sessionId, ~requestId))
      | Some(OpencodeEvent.RemoveQueueRequest({queue, sessionId, requestId})) =>
        setTrackedQueueRequests(items =>
          removeTrackedQueueRequest(~items, ~queue, ~sessionId, ~requestId)
        )
      | None => ()
      }

      switch payload->OpencodeEvent.todoUpdatedFromScoped {
      | Some({sessionId, todos}) =>
        setTrackedTodos(items => upsertTrackedTodoState(~items, ~sessionId, ~todos))
      | None => ()
      }

      switch payload->OpencodeEvent.sessionDiffFromScoped {
      | Some({sessionId, diff}) =>
        setTrackedDiffs(items => upsertTrackedDiffState(~items, ~sessionId, ~diff))
      | None => ()
      }

      switch payload->OpencodeEvent.messageMutationFromScoped {
      | Some(OpencodeEvent.UpsertMessage({message})) =>
        setTrackedMessages(items => upsertTrackedMessage(~items, ~message))
      | Some(OpencodeEvent.RemoveMessage({sessionId, messageId})) => {
          setTrackedMessages(items => removeTrackedMessage(~items, ~sessionId, ~messageId))
          setTrackedParts(items => items->Array.filter(part => !(part.sessionId == sessionId && part.messageId == messageId)))
        }
      | Some(OpencodeEvent.UpsertPart({part})) => {
          let inferredMessage: OpencodeEvent.messageSnapshot = {
            id: part.messageId,
            sessionId: part.sessionId,
            role: None,
          }
          setTrackedMessages(items => upsertTrackedMessage(~items, ~message=inferredMessage))
          setTrackedParts(items => upsertTrackedPart(~items, ~part))
        }
      | Some(OpencodeEvent.RemovePart({sessionId, messageId, partId})) =>
        setTrackedParts(items => removeTrackedPart(~items, ~sessionId, ~messageId, ~partId))
      | Some(OpencodeEvent.AppendPartDelta({sessionId, messageId, partId, field: _, deltaChars, deltaText})) =>
        setTrackedParts(items =>
          appendTrackedPartDelta(
            ~items,
            ~sessionId,
            ~messageId,
            ~partId,
            ~deltaChars,
            ~deltaText,
          )
        )
      | None => ()
      }
    }

  let refreshData = async (~query: option<OpencodeClient.sessionQuery>) => {
    setState(_ => Loading)
    let firstError = ref(None)

    await loadHealthData(~firstError)
    await loadProjectData(~firstError)
    await loadSessionData(~query, ~firstError)

    syncRequestState(setState, firstError.contents)
  }

  let refreshProjectSlice = async () => {
    let firstError = ref(None)
    await loadProjectData(~firstError)
    syncRequestState(setState, firstError.contents)
  }

  let refreshSessionSlice = async (~query: option<OpencodeClient.sessionQuery>) => {
    let firstError = ref(None)
    await loadSessionData(~query, ~firstError)
    syncRequestState(setState, firstError.contents)
  }

  let refreshSessionListSlice = async (~query: option<OpencodeClient.sessionQuery>) => {
    let firstError = ref(None)
    await loadSessionListData(~query, ~firstError)
    syncRequestState(setState, firstError.contents)
  }

  let refreshSessionStatusesSlice = async (~query: option<OpencodeClient.sessionQuery>) => {
    let firstError = ref(None)
    await loadSessionStatusData(~query, ~firstError)
    syncRequestState(setState, firstError.contents)
  }

  let applyGlobalEvent = (event: OpencodeEvent.t) =>
    EventReducer.apply(
      ~event,
      ~handlers={
        refreshAll: () => {
          let _ = refreshData(~query=sessionQuery())
          ()
        },
        refreshProjects: () => {
          let _ = refreshProjectSlice()
          ()
        },
        refreshSessions: () => {
          let _ = refreshSessionListSlice(~query=sessionQuery())
          ()
        },
        refreshStatuses: () => {
          let _ = refreshSessionStatusesSlice(~query=sessionQuery())
          ()
        },
        applySessionDeleted,
        applySessionStatusChanged,
        applySessionScoped,
        refreshSessionById: sessionId => {
          let _ = loadFocusedSessionById(~sessionId)
          ()
        },
        activeSessionId: () => focusedSessionId(),
        onObservedEvent: appendObservedEvent,
      },
    )

  let applyServer = () => {
    let nextServer = serverDraft()->String.trim
    let resolvedServer = if nextServer == "" {initialServer} else {nextServer}
    setActiveServer(_ => resolvedServer)
    setServerDraft(_ => resolvedServer)
    platformValue.setDefaultServerUrl(resolvedServer)
    let _ = refreshData(~query=sessionQuery())
    ()
  }

  let resetServer = () => {
    setServerDraft(_ => initialServer)
    setActiveServer(_ => initialServer)
    platformValue.setDefaultServerUrl(initialServer)
    let _ = refreshData(~query=sessionQuery())
    ()
  }

  let refreshFromContext = () => {
    let _ = refreshData(~query=sessionQuery())
    ()
  }

  let applySessionFilters = () => {
    let nextQuery =
      buildSessionQuery(
        ~directoryText=sessionDirectoryDraft(),
        ~searchText=sessionSearchDraft(),
        ~limitText=sessionLimitDraft(),
      )
    setSessionQuery(_ => nextQuery)
    let _ = refreshSessionSlice(~query=nextQuery)
    ()
  }

  let clearSessionFilters = () => {
    setSessionDirectoryDraft(_ => "")
    setSessionSearchDraft(_ => "")
    setSessionLimitDraft(_ => "")
    setSessionQuery(_ => None)
    let _ = refreshSessionSlice(~query=None)
    ()
  }

  let serverValue: ServerContext.t = {
    activeServer,
    serverDraft,
    setServerDraft: value => setServerDraft(_ => value),
    applyServer,
    resetServer,
    refresh: refreshFromContext,
  }

  let sdkValue: GlobalSDKContext.t = {
    client,
  }

  onMount(() => {
    let _ = refreshData(~query=sessionQuery())
    ()
  })

  let rootLayout = (props: R.childrenProps) => {
    let isRouting = R.useIsRouting()
    let location = R.useLocation()
    let server = serverValue

    AppProviders.routerRoot(
      ~children=<main className="page">
      <header className="hero">
        <h1>{string("OpenCode Web Reimplement (ReScript)")}</h1>
        <p>{string("Client SDK against the existing OpenCode server")}</p>
      </header>

      <nav className="navBar">
        <R.Link href_="/" inactiveClass_="navItem" activeClass_="navItem active">
          {string("Overview")}
        </R.Link>
        <R.Link href_="/sessions" inactiveClass_="navItem" activeClass_="navItem active">
          {string("Sessions")}
        </R.Link>
        <R.Link href_="/workspace/session" inactiveClass_="navItem" activeClass_="navItem active">
          {string("Workspace")}
        </R.Link>
      </nav>

      <div className="actionBar">
        <button className="ghostBtn" onClick={_ => platformValue.back()}>{string("Back")}</button>
        <button className="ghostBtn" onClick={_ => platformValue.forward()}>{string("Forward")}</button>
        <button className="ghostBtn" onClick={_ => platformValue.restart()}>{string("Reload")}</button>
        <button className="ghostBtn" onClick={_ => platformValue.openLink("https://github.com/anomalyco/opencode")}>
          {string("Open Upstream")}
        </button>
      </div>

      <section className="panel statusPanel">
        <div className="statusLine">
          <h2>{string("Server")}</h2>
          <span className={if isRouting() {"routeState moving"} else {"routeState"}}>
            {string(if isRouting() {"routing"} else {"idle"})}
          </span>
        </div>
        <code>{string(server.activeServer())}</code>
        <p className="statusPath">{string(`Path: ${location.pathname}`)}</p>
        <p className="streamMeta">
          {string(`Stream: ${streamStatus()} (events ${streamEventCount()->Int.toString})`)}
        </p>
        {@show switch streamError() {
        | Some(message) => <p className="errorText">{string(`Stream error: ${message}`)}</p>
        | None => <span></span>
        }}
        <p className="streamMeta">{string(`Last event: ${streamLastEventKind()->Option.getOr("none")}`)}</p>

        <div className="serverForm">
          <input
            id="server-url-input"
            type_="text"
            value={server.serverDraft()}
            onInput={event => {
              let value = event->JsxEvent.Form.target->getInputValue
              server.setServerDraft(value)
            }}
            placeholder="https://your-opencode-server"
          />
          <button id="server-apply-btn" className="refreshBtn" onClick={_ => server.applyServer()}>
            {string("Apply")}
          </button>
          <button id="server-reset-btn" className="ghostBtn" onClick={_ => server.resetServer()}>
            {string("Reset")}
          </button>
          <button id="server-refresh-btn" className="ghostBtn" onClick={_ => server.refresh()}>
            {string("Refresh")}
          </button>
        </div>
      </section>

      {props.children}
    </main>,
    )
  }

  let overviewPage = _ => {
    let sync = GlobalSyncContext.use()
    <section className="panel">
      <h2>{string("Overview")}</h2>
      <ul className="summaryList">
        <li>
          <strong>{string("Health")}</strong>
          <span>{string(healthText())}</span>
        </li>
        <li>
          <strong>{string("Project")}</strong>
          <span>{string(projectText())}</span>
        </li>
        <li>
          <strong>{string("Sessions")}</strong>
          <span>{string(sessions()->Array.length->Int.toString)}</span>
        </li>
        <li>
          <strong>{string("Projects")}</strong>
          <span>{string(projects()->Array.length->Int.toString)}</span>
        </li>
        <li>
          <strong>{string("Last Event")}</strong>
          <span>{string(sync.lastEventKind()->Option.getOr("none"))}</span>
        </li>
        <li>
          <strong>{string("Running Sessions")}</strong>
          <span>{string(sessionStatuses()->countRunningSessions->Int.toString)}</span>
        </li>
      </ul>
      <ul className="projectList">
        {projects()
        ->Array.mapWithIndex((project, index) =>
          <li className="projectRow">
            <span className="eventIndex">{string(`#${index->Int.toString}`)}</span>
            <span>{string(renderProjectLabel(project))}</span>
          </li>
        )
        ->array}
      </ul>
      {@show switch state() {
      | Failed(message) => <p className="errorText">{string(`Request failed: ${message}`)}</p>
      | Loading => <p className="loadingText">{string("Loading ...")}</p>
      | Ready => <p className="okText">{string("Data loaded from server")}</p>
      }}
    </section>
  }

  let sessionsPage = _ =>
    <section className="panel">
      <h2>{string("Sessions")}</h2>
      <div className="queryGrid">
        <label>
          <span>{string("Directory")}</span>
          <input
            id="sessions-directory-filter"
            type_="text"
            value={sessionDirectoryDraft()}
            onInput={event => {
              let value = event->JsxEvent.Form.target->getInputValue
              setSessionDirectoryDraft(_ => value)
            }}
            placeholder="workspace"
          />
        </label>
        <label>
          <span>{string("Search")}</span>
          <input
            id="sessions-search-filter"
            type_="text"
            value={sessionSearchDraft()}
            onInput={event => {
              let value = event->JsxEvent.Form.target->getInputValue
              setSessionSearchDraft(_ => value)
            }}
            placeholder="title text"
          />
        </label>
        <label>
          <span>{string("Limit")}</span>
          <input
            id="sessions-limit-filter"
            type_="number"
            value={sessionLimitDraft()}
            onInput={event => {
              let value = event->JsxEvent.Form.target->getInputValue
              setSessionLimitDraft(_ => value)
            }}
            placeholder="25"
            min="1"
          />
        </label>
      </div>
      <div className="queryActions">
        <button id="sessions-apply-filters-btn" className="refreshBtn" onClick={_ => applySessionFilters()}>
          {string("Apply filters")}
        </button>
        <button id="sessions-clear-filters-btn" className="ghostBtn" onClick={_ => clearSessionFilters()}>
          {string("Clear")}
        </button>
        <span className="streamMeta">{string(`Active query: ${sessionQuery()->renderSessionQuery}`)}</span>
      </div>

      {@show switch sessions()->Array.length > 0 {
      | true =>
        <ul className="eventList">
          {sessions()
          ->Array.mapWithIndex((session, index) =>
            {
              let status = findSessionStatus(sessionStatuses(), session.id)
              let routeDirectory = routeDirectoryForSessions(sessionQuery())
            <li className="eventRow">
              <span className="eventIndex">{string(`#${index->Int.toString}`)}</span>
              <span className="eventKind">{string(session.id)}</span>
              <span className="sessionMeta">{string(renderSessionSubtitle(session))}</span>
              <span className={if status == Some(#running) {"badge hot"} else {"badge"}}>
                {string(renderSessionStatus(status))}
              </span>
              <R.Link
                href_={`/${routeDirectory}/session/${session.id}`}
                inactiveClass_="inlineLink"
                activeClass_="inlineLink"
              >
                {string("open")}
              </R.Link>
            </li>
            }
          )
          ->array}
        </ul>
      | false => <p className="loadingText">{string("No sessions matched the current filters")}</p>
      }}
    </section>

  let dirIndexPage = _ => {
    let params = R.useParams()
    let dir = params->Dict.get("dir")->Option.getOr("workspace")
    <R.Navigate href_={`/${dir}/session`} />
  }

  let sessionPage = _ => {
    let params = R.useParams()
    let dir = params->Dict.get("dir")->Option.getOr("workspace")
    let sessionId = params->Dict.get("id")->Option.getOr("latest")

    createEffect(() => {
      switch params->Dict.get("id") {
      | None => {
          setFocusedSessionId(_ => None)
          setFocusedSession(_ => None)
          setFocusedSessionError(_ => None)
          setComposerDraft(_ => "")
          setComposerError(_ => None)
        }
      | Some(id) => {
          setFocusedSessionId(_ => Some(id))
          setComposerError(_ => None)
          let _ = loadFocusedSessionById(~sessionId=id)
          ()
        }
      }
    })

    let selected =
      sessions()->Array.reduce(None, (found, item) =>
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

    let focusedMatch =
      switch focusedSession() {
      | Some(session) if sessionId == "latest" || session.id == sessionId => Some(session)
      | _ => None
      }

    let hasSessionMetadata = selected->Option.isSome || focusedMatch->Option.isSome

    let displayedSession =
      switch selected {
      | Some(session) => Some(session)
      | None =>
        switch focusedMatch {
        | Some(session) => Some(session)
        | None =>
          if sessionId == "latest" {
            None
          } else {
            Some({
              id: sessionId,
              title: None,
              updatedAt: None,
            })
          }
        }
      }

    let counterSessionId =
      if sessionId == "latest" {
        switch displayedSession {
        | Some(session) => session.id
        | None => sessionId
        }
      } else {
        sessionId
      }
    let pendingPermissionCount = () =>
      countTrackedQueueRequests(~items=trackedQueueRequests(), ~sessionId=counterSessionId, ~queue=#permission)
    let pendingQuestionCount = () =>
      countTrackedQueueRequests(~items=trackedQueueRequests(), ~sessionId=counterSessionId, ~queue=#question)
    let trackedSessionMessages = () =>
      trackedMessages()->Array.filter(item => item.sessionId == counterSessionId)
    let trackedSessionParts = () => trackedParts()->Array.filter(item => item.sessionId == counterSessionId)
    let trackedTodoCount = () => trackedTodoCountForSession(trackedTodos(), counterSessionId)
    let trackedDiffFileCount = () => trackedDiffFileCountForSession(trackedDiffs(), counterSessionId)
    let messageCount = () => trackedSessionMessages()->Array.length
    let messagePartCount = () => trackedSessionParts()->Array.length
    let streamedCharCount = () => trackedSessionParts()->Array.reduce(0, (count, item) => count + item.streamedChars)
    let routeStatus = () => findSessionStatus(sessionStatuses(), counterSessionId)
    let hasSessionActivity = () =>
      routeStatus()->Option.isSome
      || pendingPermissionCount() > 0
      || pendingQuestionCount() > 0
      || trackedTodoCount() > 0
      || trackedDiffFileCount() > 0
      || messageCount() > 0
      || messagePartCount() > 0
      || streamedCharCount() > 0
    let effectiveRouteStatus = () =>
      switch routeStatus() {
      | Some(status) => Some(status)
      | None => if hasSessionActivity() {Some(#running)} else {None}
      }
    let conversationRows = () => {
      let sessionParts = trackedSessionParts()
      let knownMessages = trackedSessionMessages()->Array.map(item => item.message)
      let mergedMessages =
        sessionParts->Array.reduce(knownMessages, (messages, part) => {
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

      mergedMessages
      ->reverseItems
      ->Array.map(message => {
        let messageParts =
          sessionParts
          ->Array.filter(part => part.messageId == message.id)
          ->reverseItems
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
    }

    let composerTargetSessionId =
      if sessionId == "latest" {
        switch displayedSession {
        | Some(session) => session.id
        | None => sessionId
        }
      } else {
        sessionId
      }

    let canSendComposer = composerTargetSessionId != "" && composerTargetSessionId != "latest"

    let sendComposer = async () => {
      let prompt = composerDraft()->String.trim

      if prompt == "" {
        ()
      } else if !canSendComposer {
        setComposerError(_ => Some("Select a concrete session before sending a prompt"))
      } else {
        let localNonce =
          `${streamEventCount()->Int.toString}-${messagePartCount()->Int.toString}-${prompt->String.length->Int.toString}`
        let localMessageId = `local-user-message-${composerTargetSessionId}-${localNonce}`
        let localPartId = `local-user-part-${localNonce}`
        let optimisticMessage: OpencodeEvent.messageSnapshot = {
          id: localMessageId,
          sessionId: composerTargetSessionId,
          role: Some(OpencodeEvent.UserRole),
        }
        let optimisticPart: OpencodeEvent.partSnapshot = {
          id: localPartId,
          sessionId: composerTargetSessionId,
          messageId: localMessageId,
          partType: Some(OpencodeEvent.TextPart),
        }

        setComposerError(_ => None)
        setIsComposerSending(_ => true)
        setTrackedMessages(items => upsertTrackedMessage(~items, ~message=optimisticMessage))
        setTrackedParts(items => {
          let withPart = upsertTrackedPart(~items, ~part=optimisticPart)
          withPart->Array.map(item =>
            if item.sessionId == composerTargetSessionId && item.messageId == localMessageId && item.part.id == localPartId {
              switch item.text {
              | "" => {...item, streamedChars: prompt->String.length, text: prompt}
              | _ => item
              }
            } else {
              item
            }
          )
        })
        setComposerDraft(_ => "")
        setFocusedSessionId(_ => Some(composerTargetSessionId))
        let _ = loadFocusedSessionById(~sessionId=composerTargetSessionId)
        let _ = refreshSessionSlice(~query=sessionQuery())
        let model = composerModelDraft()->normalizeQueryText
        switch await OpencodeClient.sendSessionTextMessage(
          client(),
          ~sessionId=composerTargetSessionId,
          ~text=prompt,
          ~model=?model,
        ) {
        | Ok(()) => ()
        | Error(error) => setComposerError(_ => Some(`Send failed: ${OpencodeClient.errorToString(error)}`))
        }
        setIsComposerSending(_ => false)
      }
    }

    let clearComposerDraft = () => {
      setComposerDraft(_ => "")
      setComposerError(_ => None)
    }

    let composerModelSelectValue = () => {
      if composerCustomModelEnabled() {
        customModelSentinel
      } else {
        switch composerModelDraft()->normalizeQueryText {
        | Some(value) if isKnownModelPreset(value) => value
        | Some(_) => customModelSentinel
        | None => ""
        }
      }
    }

    let applyComposerModelSelection = (value: string) => {
      if value == "" {
        setComposerCustomModelEnabled(_ => false)
        setComposerModelDraft(_ => "")
      } else if value == customModelSentinel {
        setComposerCustomModelEnabled(_ => true)
      } else {
        setComposerCustomModelEnabled(_ => false)
        setComposerModelDraft(_ => value)
      }
    }

    let sessionBody =
      {@defer {
        <div className="sessionBody">
          <div className="sessionMainStack">
            <section className="panel sessionHeaderPanel">
              <h2>{string(`Workspace ${dir}`)}</h2>
              <p className="sessionRoute">{string(`Session Route ID: ${sessionId}`)}</p>
              <p className="sessionRoute">
                {string(`Session Status: ${effectiveRouteStatus()->renderSessionStatus}`)}
              </p>
              {@show switch displayedSession {
              | Some(session) =>
                <p>
                  {string(
                    if hasSessionMetadata {
                      `Matched: ${renderSessionSubtitle(session)}`
                    } else {
                      `Route session: ${session.id} (metadata pending)`
                    },
                  )}
                </p>
              | None =>
                {@show switch hasSessionActivity() {
                | true =>
                  <p className="okText">
                    {string("Session activity is flowing; metadata list is still syncing for this route.")}
                  </p>
                | false =>
                  <p className="loadingText">
                    {string("No matching session in current list. Fetching from server may still be pending.")}
                  </p>
                }}
              }}
            </section>

            <section className="panel sessionTimelinePanel">
              <h3>{string("Timeline")}</h3>
              <p className="sessionRoute">{string("Recent sessions in current workspace scope")}</p>
              <ul className="sessionMiniList">
                {sessions()
                ->Array.map(item =>
                  <li className={if item.id == sessionId {"miniSessionRow active"} else {"miniSessionRow"}}>
                    <span className="eventKind">{string(item.id)}</span>
                    <span className="sessionMeta">{string(renderSessionSubtitle(item))}</span>
                  </li>
                )
                ->array}
              </ul>
            </section>

            <section className="panel sessionComposerPanel">
              <h3>{string("Composer")}</h3>
              <p className="sessionRoute">{string("Prompt dock for continuing the selected session")}</p>
              <div className="composerModelRow">
                <p className="sessionRoute">{string("Model override (optional)")}</p>
                <select
                  id="composer-model-select"
                  className="composerModelSelect"
                  value={composerModelSelectValue()}
                  onInput={event => {
                    let value = event->JsxEvent.Form.target->getInputValue
                    applyComposerModelSelection(value)
                  }}
                >
                  <option value="">{string("Default (session model)")}</option>
                  {modelPresetOptions
                  ->Array.map(((value, label)) => <option value={value}>{string(label)}</option>)
                  ->array}
                  <option value={customModelSentinel}>{string("Custom model...")}</option>
                </select>
                {@show switch composerCustomModelEnabled() {
                | true =>
                  <input
                    id="composer-model-input"
                    className="composerModelInput"
                    placeholder="e.g. anthropic/claude-sonnet-4-5"
                    value={composerModelDraft()}
                    onInput={event => {
                      let value = event->JsxEvent.Form.target->getInputValue
                      setComposerModelDraft(_ => value)
                    }}
                  />
                | false =>
                  <p className="sessionRoute composerModelHint">
                    {string("Select a preset or use custom for a manual model id.")}
                  </p>
                }}
              </div>
              <textarea
                className="composerInput"
                placeholder="Ask OpenCode to continue this session..."
                value={composerDraft()}
                onInput={event => {
                  let value = event->JsxEvent.Form.target->getInputValue
                  setComposerDraft(_ => value)
                }}
                onKeyDown={event => {
                  let key = event->getKeyboardKey
                  if key == "Enter" && !(event->getKeyboardShiftKey) {
                    event->preventDefault
                    let canTrigger = !(isComposerSending() || composerDraft()->String.trim == "" || !canSendComposer)
                    if canTrigger {
                      let _ = sendComposer()
                      ()
                    } else {
                      ()
                    }
                  } else {
                    ()
                  }
                }}
              />
              <div className="queryActions">
                <button
                  id="composer-send-btn"
                  className="refreshBtn"
                  disabled={isComposerSending() || composerDraft()->String.trim == "" || !canSendComposer}
                  onClick={_ => {
                    let _ = sendComposer()
                    ()
                  }}>
                  {string(if isComposerSending() {"Sending..."} else {"Send"})}
                </button>
                <button
                  id="composer-clear-btn"
                  className="ghostBtn"
                  disabled={isComposerSending() || composerDraft() == ""}
                  onClick={_ => clearComposerDraft()}>
                  {string("Clear draft")}
                </button>
              </div>
              {@show switch composerError() {
              | Some(error) => <p className="errorText">{string(error)}</p>
              | None => <span></span>
              }}
            </section>

            <section className="panel sessionTerminalPanel sessionChatPanel">
              <h3>{string("Conversation")}</h3>
              <p className="sessionRoute">{string("Live assistant and user message stream")}</p>
              {@show switch conversationRows()->Array.length > 0 {
              | true =>
                <ul className="chatList">
                  {conversationRows()
                  ->Array.map(row => {
                    let bubbleClass = row.message.role->messageRoleClass
                    <li className={`chatRow ${bubbleClass}`}>
                      <div className="chatMetaRow">
                        <span className="chatRole">{string(row.message.role->renderMessageRole)}</span>
                        <span className="terminalPartMeta">{string(row.message.id)}</span>
                      </div>
                      <pre className="chatBubbleText">{string(row.text)}</pre>
                    </li>
                  })
                  ->array}
                </ul>
              | false => <pre className="terminalStub">{string("$ waiting for stream output...")}</pre>
              }}
            </section>
          </div>

          {@defer {
            <aside className="sessionSidePanel">
              <section className="panel sideSection">
                <h3>{string("Review")}</h3>
                <p className="sessionRoute">{string("Reducer-routed global activity for this workspace")}</p>
                {@show switch focusedSessionError() {
                | Some(error) => <p className="errorText">{string(`Server lookup failed: ${error}`)}</p>
                | None => <span></span>
                }}
                {@show switch recentEvents()->Array.length > 0 {
                | true =>
                  <ul className="sideEventList">
                    {recentEvents()
                    ->Array.map(event =>
                      <li className="sideEventRow">{string(renderObservedEvent(event))}</li>
                    )
                    ->array}
                  </ul>
                | false => <p className="loadingText">{string("No events captured from the stream yet")}</p>
                }}
              </section>
              <section className="panel sideSection">
                <h3>{string("Context")}</h3>
                {@show switch displayedSession {
                | Some(session) =>
                  <ul className="summaryList sideSummaryList">
                    <li>
                      <strong>{string("Session")}</strong>
                      <span>{string(session.id)}</span>
                    </li>
                    <li>
                      <strong>{string("Title")}</strong>
                      <span>{string(session.title->Option.getOr("Untitled"))}</span>
                    </li>
                    <li>
                      <strong>{string("Updated")}</strong>
                      <span>{string(session.updatedAt->Option.getOr("Unknown"))}</span>
                    </li>
                    <li>
                      <strong>{string("Status")}</strong>
                      <span>{string(effectiveRouteStatus()->renderSessionStatus)}</span>
                    </li>
                  </ul>
                | None => <p className="loadingText">{string("No session payload is cached yet")}</p>
                }}
                <p className="sessionRoute">{string(`Filter scope: ${sessionQuery()->renderSessionQuery}`)}</p>
                <p className="sessionRoute">{string(`Known sessions: ${sessions()->Array.length->Int.toString}`)}</p>
                <p className="sessionRoute">
                  {string(
                    `Running sessions: ${
                      sessionStatuses()->Array.reduce(0, (count, item) =>
                        if item.status == #running {
                          count + 1
                        } else {
                          count
                        }
                      )->Int.toString
                    }`,
                  )}
                </p>
                <p className="sessionRoute">
                  {string(`Pending permissions: ${pendingPermissionCount()->Int.toString}`)}
                </p>
                <p className="sessionRoute">
                  {string(`Pending questions: ${pendingQuestionCount()->Int.toString}`)}
                </p>
                <p className="sessionRoute">
                  {string(`Todos tracked: ${trackedTodoCount()->Int.toString}`)}
                </p>
                <p className="sessionRoute">
                  {string(`Diff files tracked: ${trackedDiffFileCount()->Int.toString}`)}
                </p>
                <p className="sessionRoute">
                  {string(`Messages tracked: ${messageCount()->Int.toString}`)}
                </p>
                <p className="sessionRoute">
                  {string(`Message parts tracked: ${messagePartCount()->Int.toString}`)}
                </p>
                <p className="sessionRoute">
                  {string(`Streamed chars: ${streamedCharCount()->Int.toString}`)}
                </p>
              </section>
              <section className="panel sideSection">
                <h3>{string("Files")}</h3>
                {@show switch projects()->Array.length > 0 {
                | true =>
                  <ul className="sideProjectList">
                    {projects()
                    ->Array.map(project => {
                      let name = project.name->Option.getOr("Unnamed project")
                      let path = project.path->Option.getOr("Path unavailable")
                      <li className="sideProjectRow">
                        <span className="eventKind">{string(name)}</span>
                        <span className="sessionMeta">{string(path)}</span>
                      </li>
                    })
                    ->array}
                  </ul>
                | false => <p className="loadingText">{string("No project roots loaded from SDK")}</p>
                }}
              </section>
            </aside>
          }}
        </div>
      }}

    AppProviders.sessionProviders(
      ~children=<section className="sessionDetailLayout">
      {sessionBody}
      <R.Link href_="/sessions" inactiveClass_="inlineLink" activeClass_="inlineLink">
        {string("Back to sessions")}
      </R.Link>
    </section>,
    )
  }

  let routedShell =
    <R.Router root_={rootLayout}>
      <R.Route path_="/" component_={overviewPage} />
      <R.Route path_="/sessions" component_={sessionsPage} />
      <R.RouteWrapper path_="/:dir">
        <R.Route path_="/" component_={dirIndexPage} />
        <R.Route path_="/session/:id?" component_={sessionPage} />
      </R.RouteWrapper>
    </R.Router>

  let guardedShell =
    AppProviders.serverGate(
      ~server=serverValue.activeServer,
      ~children=<GlobalSDKContext value={sdkValue}>
        <GlobalSyncContext
          client={client}
          onOpen={() => {
            setStreamStatus(_ => "connected")
            setStreamError(_ => None)
          }}
          onError={message => {
            setStreamStatus(_ => "error")
            setStreamError(_ => Some(message))
          }}
          onEvent={event => {
            setStreamStatus(_ => "connected")
            setStreamError(_ => None)
            setStreamEventCount(prev => prev + 1)
            setStreamLastEventKind(_ => Some(OpencodeEvent.kind(event)))
            applyGlobalEvent(event)
          }}>
          {routedShell}
        </GlobalSyncContext>
      </GlobalSDKContext>,
    )

  AppProviders.appBaseProviders(
    ~children=<PlatformContext value={platformValue}>
      <ServerContext value={serverValue}>{guardedShell}</ServerContext>
    </PlatformContext>,
  )
}
