open Solid

type t = {
  streamStatus: accessor<string>,
  streamError: accessor<option<string>>,
  eventCount: accessor<int>,
  lastEventKind: accessor<option<string>>,
}

let use: unit => t

@jsx.component
let make: (
  ~client: accessor<OpencodeClient.t>,
  ~onOpen: unit => unit=?,
  ~onError: string => unit=?,
  ~onEvent: OpencodeEvent.t => unit=?,
  ~children: element,
) => element
