type t
type subscription

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

let make: (
  ~serverUrl: string,
  ~authToken: string=?,
  ~defaultHeaders: array<(string, string)>=?,
  unit,
) => t

let subscribeGlobalEvents: (
  t,
  ~onEvent: OpencodeEvent.t => unit,
  ~onOpen: (unit => unit)=?,
  ~onError: (string => unit)=?,
  unit,
) => subscription

let closeSubscription: subscription => unit

let errorToString: OpencodeHttp.error => string

let health: t => promise<result<health, OpencodeHttp.error>>
let projectCurrent: t => promise<result<option<project>, OpencodeHttp.error>>
let sessions: (t, ~query: sessionQuery=?, unit) => promise<result<array<sessionSummary>, OpencodeHttp.error>>
let projects: t => promise<result<array<project>, OpencodeHttp.error>>
let sessionById: (t, ~sessionId: string) => promise<result<option<sessionSummary>, OpencodeHttp.error>>
let sessionMessages: (t, ~sessionId: string) => promise<result<array<sessionMessage>, OpencodeHttp.error>>
let sessionStatuses: (t, ~query: sessionQuery=?, unit) => promise<result<array<sessionStatusItem>, OpencodeHttp.error>>
let sendSessionTextMessage: (
  t,
  ~sessionId: string,
  ~text: string,
  ~model: string=?,
) => promise<result<unit, OpencodeHttp.error>>
