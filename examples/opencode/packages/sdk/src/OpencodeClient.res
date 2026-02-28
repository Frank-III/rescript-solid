type t = {
  http: OpencodeHttp.t,
  config: OpencodeConfig.t,
}

type eventSource
type messageEvent

type subscription = {
  close: unit => unit,
}

@new @scope("window")
external createEventSource: string => eventSource = "EventSource"

@set
external setOnMessage: (eventSource, messageEvent => unit) => unit = "onmessage"

@set
external setOnError: (eventSource, unit => unit) => unit = "onerror"

@set
external setOnOpen: (eventSource, unit => unit) => unit = "onopen"

@send
external closeEventSource: eventSource => unit = "close"

@get
external getMessageData: messageEvent => string = "data"

@val
external parseJsonUnsafe: string => JSON.t = "JSON.parse"

@val
external encodeURIComponent: string => string = "encodeURIComponent"

type health = {
  status: string,
  version: option<string>,
}

type project = {
  id: option<string>,
  name: option<string>,
  path: option<string>,
}

type sessionSummary = {
  id: string,
  title: option<string>,
  updatedAt: option<string>,
}

type sessionMessagePart = {
  id: string,
  sessionId: string,
  messageId: string,
  partType: option<OpencodeEvent.partKind>,
  text: string,
}

type sessionMessage = {
  id: string,
  sessionId: string,
  role: option<OpencodeEvent.messageRole>,
  parts: array<sessionMessagePart>,
}

type sessionStatus = [#running | #idle]

type sessionStatusItem = {
  id: string,
  status: sessionStatus,
}

type sessionQuery = {
  directory: option<string>,
  search: option<string>,
  limit: option<int>,
}

type modelSelection = {
  providerID: string,
  modelID: string,
}

type modelOption = {
  id: string,
  label: string,
  providerID: string,
  modelID: string,
}

let decodeMaybeString = (value: option<JSON.t>): option<string> =>
  switch value {
  | Some(JSON.String(text)) => Some(text)
  | _ => None
  }

let decodeHealth = (value: JSON.t): option<health> =>
  switch value {
  | Object(dict{"status": JSON.String(status), "version": ?version}) =>
    Some({status, version: decodeMaybeString(version)})
  | Object(dict{"status": JSON.String(status)}) => Some({status, version: None})
  | _ => None
  }

let rec decodeProject = (value: JSON.t): option<project> =>
  switch value {
  | Object(dict{"project": projectPayload}) => decodeProject(projectPayload)
  | Object(dict{"id": ?id, "name": ?name, "path": ?path}) =>
    Some({
      id: decodeMaybeString(id),
      name: decodeMaybeString(name),
      path: decodeMaybeString(path),
    })
  | _ => None
  }

let decodeProjectArray = (value: JSON.t): array<project> => {
  let source =
    switch value {
    | JSON.Array(items) => items
    | Object(dict{"projects": JSON.Array(items)}) => items
    | Object(dict{"data": JSON.Array(items)}) => items
    | _ => []
    }

  source->Array.reduce([], (acc, item) =>
    switch decodeProject(item) {
    | Some(project) => acc->Array.concat([project])
    | None => acc
    }
  )
}

let decodeSession = (value: JSON.t): option<sessionSummary> =>
  switch value {
  | Object(
      dict{
        "id": JSON.String(id),
        "title": ?title,
        "time": Object(dict{"updated": JSON.Number(updated)}),
      },
    ) =>
    Some({
      id,
      title: decodeMaybeString(title),
      updatedAt: Some(updated->Float.toString),
    })
  | Object(dict{"id": JSON.String(id), "title": ?title, "updated": ?updated}) =>
    Some({
      id,
      title: decodeMaybeString(title),
      updatedAt: decodeMaybeString(updated),
    })
  | Object(dict{"id": JSON.String(id), "title": ?title, "updatedAt": ?updatedAt}) =>
    Some({
      id,
      title: decodeMaybeString(title),
      updatedAt: decodeMaybeString(updatedAt),
    })
  | Object(dict{"id": JSON.String(id)}) => Some({id, title: None, updatedAt: None})
  | _ => None
  }

let decodeMessageRole = (value: JSON.t): option<OpencodeEvent.messageRole> =>
  switch value {
  | JSON.String("user") => Some(OpencodeEvent.UserRole)
  | JSON.String("assistant") => Some(OpencodeEvent.AssistantRole)
  | JSON.String("tool") => Some(OpencodeEvent.ToolRole)
  | JSON.String("system") => Some(OpencodeEvent.SystemRole)
  | JSON.String(other) => Some(OpencodeEvent.UnknownMessageRole(other))
  | _ => None
  }

let decodePartKind = (value: JSON.t): option<OpencodeEvent.partKind> =>
  switch value {
  | JSON.String("text") => Some(OpencodeEvent.TextPart)
  | JSON.String("tool") => Some(OpencodeEvent.ToolPart)
  | JSON.String("file") => Some(OpencodeEvent.FilePart)
  | JSON.String("reasoning")
  | JSON.String("thinking") => Some(OpencodeEvent.ReasoningPart)
  | JSON.String(other) => Some(OpencodeEvent.UnknownPartKind(other))
  | _ => None
  }

let decodeStringWithFallback = (
  ~primary: option<JSON.t>,
  ~fallback: option<JSON.t>,
): option<string> =>
  switch primary->decodeMaybeString {
  | Some(value) => Some(value)
  | None => fallback->decodeMaybeString
  }

let decodeSessionMessagePart = (
  value: JSON.t,
  ~fallbackSessionId: string,
  ~fallbackMessageId: string,
): option<sessionMessagePart> =>
  switch value {
  | Object(dict{"id": JSON.String(id), "text": ?text, "type": ?partType, "sessionID": ?sessionID, "sessionId": ?sessionId, "messageID": ?messageID, "messageId": ?messageId}) =>
    let resolvedSessionId =
      decodeStringWithFallback(~primary=sessionID, ~fallback=sessionId)->Option.getOr(fallbackSessionId)
    let resolvedMessageId =
      decodeStringWithFallback(~primary=messageID, ~fallback=messageId)->Option.getOr(fallbackMessageId)
    let resolvedText = text->decodeMaybeString->Option.getOr("")
    let resolvedPartType =
      switch partType {
      | Some(raw) => raw->decodePartKind
      | None => None
      }

    Some({
      id,
      sessionId: resolvedSessionId,
      messageId: resolvedMessageId,
      partType: resolvedPartType,
      text: resolvedText,
    })
  | _ => None
  }

let decodeSessionMessage = (value: JSON.t, ~fallbackSessionId: string): option<sessionMessage> =>
  switch value {
  | Object(dict{"info": JSON.Object(info), "parts": JSON.Array(partsRaw)}) =>
    switch (Dict.get(info, "id"), decodeStringWithFallback(~primary=Dict.get(info, "sessionID"), ~fallback=Dict.get(info, "sessionId"))) {
    | (Some(JSON.String(id)), Some(sessionId)) => {
        let role =
          switch Dict.get(info, "role") {
          | Some(rawRole) => rawRole->decodeMessageRole
          | None => None
          }

        let parts =
          partsRaw->Array.reduce([], (acc, rawPart) =>
            switch decodeSessionMessagePart(rawPart, ~fallbackSessionId=sessionId, ~fallbackMessageId=id) {
            | Some(part) => acc->Array.concat([part])
            | None => acc
            }
          )

        Some({id, sessionId, role, parts})
      }
    | (Some(JSON.String(id)), None) =>
      Some({id, sessionId: fallbackSessionId, role: None, parts: []})
    | _ => None
    }
  | _ => None
  }

let decodeSessionMessageArray = (
  value: JSON.t,
  ~fallbackSessionId: string,
): array<sessionMessage> => {
  let source =
    switch value {
    | JSON.Array(items) => items
    | Object(dict{"messages": JSON.Array(items)}) => items
    | Object(dict{"data": JSON.Array(items)}) => items
    | _ => []
    }

  source->Array.reduce([], (acc, item) =>
    switch decodeSessionMessage(item, ~fallbackSessionId) {
    | Some(message) => acc->Array.concat([message])
    | None => acc
    }
  )
}

let decodeSessionEnvelope = (value: JSON.t): option<sessionSummary> =>
  switch value {
  | Object(dict{"session": sessionPayload}) => decodeSession(sessionPayload)
  | _ => decodeSession(value)
  }

let decodeSessionArray = (value: JSON.t): array<sessionSummary> => {
  let source =
    switch value {
    | JSON.Array(items) => items
    | Object(dict{"sessions": JSON.Array(items)}) => items
    | Object(dict{"data": JSON.Array(items)}) => items
    | _ => []
    }

  source->Array.reduce([], (acc, item) =>
    switch decodeSession(item) {
    | Some(session) => acc->Array.concat([session])
    | None => acc
    }
  )
}

let decodeSessionStatus = (value: JSON.t): option<sessionStatus> =>
  switch value {
  | JSON.String("running") => Some(#running)
  | JSON.String("idle") => Some(#idle)
  | _ => None
  }

let decodeSessionStatusArray = (value: JSON.t): array<sessionStatusItem> =>
  switch value {
  | Object(statusMap) =>
    statusMap
    ->Dict.toArray
    ->Array.reduce([], (acc, item) => {
      let (sessionId, rawStatus) = item
      switch decodeSessionStatus(rawStatus) {
      | Some(status) => acc->Array.concat([{id: sessionId, status: status}])
      | None => acc
      }
    })
  | _ => []
  }

let decodeProviderModelEntries = (
  ~providerName: string,
  value: JSON.t,
): array<modelOption> =>
  switch value {
  | JSON.Object(dict{"models": JSON.Object(models)}) =>
    models
    ->Dict.toArray
    ->Array.reduce([], (acc, item) => {
      let (displayLabel, rawModel) = item
      let modelId =
        switch rawModel {
        | JSON.Object(modelEntry) =>
          switch Dict.get(modelEntry, "id") {
          | Some(JSON.String(id)) => id
          | _ => displayLabel
          }
        | _ => displayLabel
        }

      let providerID =
        switch rawModel {
        | JSON.Object(modelEntry) =>
          switch Dict.get(modelEntry, "providerID") {
          | Some(JSON.String(id)) => id
          | _ => providerName
          }
        | _ => providerName
        }

      let resolvedModelID =
        switch rawModel {
        | JSON.Object(modelEntry) =>
          switch Dict.get(modelEntry, "modelID") {
          | Some(JSON.String(id)) => id
          | _ => modelId
          }
        | _ => modelId
        }

      let id = modelId->String.trim
      let normalizedProviderID = providerID->String.trim
      let normalizedModelID = resolvedModelID->String.trim

      if id == "" || normalizedProviderID == "" || normalizedModelID == "" {
        acc
      } else {
        let label = `${displayLabel} (${providerName})`
        acc->Array.concat([
          {
            id,
            label,
            providerID: normalizedProviderID,
            modelID: normalizedModelID,
          },
        ])
      }
    })
  | _ => []
  }

let decodeConfigModelOptions = (value: JSON.t): array<modelOption> => {
  let options =
    switch value {
    | JSON.Object(dict{"provider": JSON.Object(providers)}) =>
      providers
      ->Dict.toArray
      ->Array.reduce([], (acc, item) => {
        let (providerName, providerValue) = item
        let providerOptions = decodeProviderModelEntries(~providerName, providerValue)
        acc->Array.concat(providerOptions)
      })
    | _ => []
    }

  options->Array.reduce([], (acc, optionItem) => {
    let exists = acc->Array.some(existing => existing.id == optionItem.id)
    if exists {
      acc
    } else {
      acc->Array.concat([optionItem])
    }
  })
}

let normalizedQueryValue = (value: option<string>): option<string> =>
  switch value {
  | Some(text) =>
    let trimmed = text->String.trim
    if trimmed == "" {
      None
    } else {
      Some(trimmed)
    }
  | None => None
  }

let normalizeModelSelection = (value: option<modelSelection>): option<modelSelection> =>
  switch value {
  | Some(model) =>
    let providerID = model.providerID->String.trim
    let modelID = model.modelID->String.trim
    if providerID == "" || modelID == "" {
      None
    } else {
      Some({providerID, modelID})
    }
  | None => None
  }

let queryPairs = (query: sessionQuery): array<(string, string)> => {
  let directoryPairs =
    switch normalizedQueryValue(query.directory) {
    | Some(directory) => [("directory", directory)]
    | None => []
    }

  let searchPairs =
    switch normalizedQueryValue(query.search) {
    | Some(search) => [("search", search)]
    | None => []
    }

  let limitPairs =
    switch query.limit {
    | Some(limit) if limit > 0 => [("limit", limit->Int.toString)]
    | _ => []
    }

  directoryPairs->Array.concat(searchPairs)->Array.concat(limitPairs)
}

let withQuery = (path: string, pairs: array<(string, string)>): string => {
  let queryString =
    pairs->Array.reduce("", (acc, pair) => {
      let (key, value) = pair
      let item = `${key->encodeURIComponent}=${value->encodeURIComponent}`
      if acc == "" {
        item
      } else {
        `${acc}&${item}`
      }
    })

  if queryString == "" {
    path
  } else {
    `${path}?${queryString}`
  }
}

let withSessionQuery = (path: string, query: sessionQuery): string =>
  withQuery(path, query->queryPairs)

let withStatusQuery = (path: string, query: sessionQuery): string =>
  switch normalizedQueryValue(query.directory) {
  | Some(directory) => withQuery(path, [("directory", directory)])
  | None => path
  }

let make = (~serverUrl: string, ~authToken: option<string>=?, ~defaultHeaders: array<(string, string)>=[], ()) => {
  let config = OpencodeConfig.make(~serverUrl, ~authToken?, ~defaultHeaders, ())
  {
    http: OpencodeHttp.make(config),
    config: config,
  }
}

let subscribeGlobalEvents = (
  client: t,
  ~onEvent: OpencodeEvent.t => unit,
  ~onOpen: unit => unit=(() => ()),
  ~onError: string => unit=(_ => ()),
  (),
): subscription => {
  let source = createEventSource(OpencodeConfig.resolveUrl(client.config, "/global/event"))

  setOnOpen(source, _ => onOpen())

  setOnMessage(source, event => {
    let payloadString = getMessageData(event)
    try {
      let payload = parseJsonUnsafe(payloadString)
      let eventPayload =
        switch payload {
        | Object(dict{"payload": nestedPayload}) => nestedPayload
        | _ => payload
        }
      onEvent(OpencodeEvent.decode(eventPayload))
    } catch {
    | _ => onError(`Invalid event payload: ${payloadString}`)
    }
  })

  setOnError(source, _ => onError("Global event stream error"))

  {
    close: () => closeEventSource(source),
  }
}

let closeSubscription = (subscription: subscription) => subscription.close()

let errorToString = (error: OpencodeHttp.error): string =>
  switch error {
  | NetworkError(message) => message
  | HttpError({status, bodyText}) => `HTTP ${(status->Int.toString)} ${bodyText}`
  | InvalidJson(body) => `Invalid JSON: ${body}`
  }

let health = async (client: t) => {
  switch await OpencodeHttp.getJson(client.http, ~path="/global/health", ()) {
  | Error(error) => Error(error)
  | Ok(payload) =>
    switch decodeHealth(payload) {
    | Some(parsed) => Ok(parsed)
    | None => Error(InvalidJson("Expected /global/health JSON object"))
    }
  }
}

let projectCurrent = async (client: t) => {
  switch await OpencodeHttp.getJson(client.http, ~path="/project/current", ()) {
  | Error(error) => Error(error)
  | Ok(payload) => Ok(decodeProject(payload))
  }
}

let sessions = async (client: t, ~query: option<sessionQuery>=?, ()) => {
  let path =
    switch query {
    | Some(params) => withSessionQuery("/session", params)
    | None => "/session"
    }

  switch await OpencodeHttp.getJson(client.http, ~path, ()) {
  | Error(error) => Error(error)
  | Ok(payload) => Ok(decodeSessionArray(payload))
  }
}

let projects = async (client: t) => {
  switch await OpencodeHttp.getJson(client.http, ~path="/project", ()) {
  | Error(error) => Error(error)
  | Ok(payload) => Ok(decodeProjectArray(payload))
  }
}

let sessionById = async (client: t, ~sessionId: string) => {
  switch await OpencodeHttp.getJson(client.http, ~path=`/session/${sessionId}`, ()) {
  | Error(error) => Error(error)
  | Ok(payload) => Ok(decodeSessionEnvelope(payload))
  }
}

let sessionStatuses = async (client: t, ~query: option<sessionQuery>=?, ()) => {
  let path =
    switch query {
    | Some(params) => withStatusQuery("/session/status", params)
    | None => "/session/status"
    }

  switch await OpencodeHttp.getJson(client.http, ~path, ()) {
  | Error(error) => Error(error)
  | Ok(payload) => Ok(decodeSessionStatusArray(payload))
  }
}

let configModels = async (client: t) => {
  switch await OpencodeHttp.getJson(client.http, ~path="/config", ()) {
  | Error(error) => Error(error)
  | Ok(payload) => Ok(decodeConfigModelOptions(payload))
  }
}

let sessionMessages = async (client: t, ~sessionId: string) => {
  switch await OpencodeHttp.getJson(client.http, ~path=`/session/${sessionId}/message`, ()) {
  | Error(error) => Error(error)
  | Ok(payload) => Ok(decodeSessionMessageArray(payload, ~fallbackSessionId=sessionId))
  }
}

let sendSessionTextMessage = async (
  client: t,
  ~sessionId: string,
  ~text: string,
  ~model: option<modelSelection>=?,
) => {
  let trimmed = text->String.trim
  let normalizedModel = model->normalizeModelSelection

  if trimmed == "" {
    Ok(())
  } else {
    let part =
      JSON.Object(
        Dict.fromArray([
          ("type", JSON.String("text")),
          ("text", JSON.String(trimmed)),
        ]),
      )

    let bodyPairs =
      switch normalizedModel {
      | Some(modelValue) => [
          ("parts", JSON.Array([part])),
          (
            "model",
            JSON.Object(
              Dict.fromArray([
                ("providerID", JSON.String(modelValue.providerID)),
                ("modelID", JSON.String(modelValue.modelID)),
              ]),
            ),
          ),
        ]
      | None => [("parts", JSON.Array([part]))]
      }
    let body = JSON.Object(Dict.fromArray(bodyPairs))

    switch await OpencodeHttp.postJsonAck(client.http, ~path=`/session/${sessionId}/message`, ~body, ()) {
    | Error(error) => Error(error)
    | Ok(()) => Ok(())
    }
  }
}
