open Solid

type t = {
  streamStatus: accessor<string>,
  streamError: accessor<option<string>>,
  eventCount: accessor<int>,
  lastEventKind: accessor<option<string>>,
}

let defaultValue: t = {
  streamStatus: () => "disconnected",
  streamError: () => None,
  eventCount: () => 0,
  lastEventKind: () => None,
}

let context = createContext(defaultValue)

let use = () => useContext(context)

@jsx.component
let make = (
  ~client: accessor<OpencodeClient.t>,
  ~onOpen: (unit => unit)=(() => ()),
  ~onError: (string => unit)=(_ => ()),
  ~onEvent: (OpencodeEvent.t => unit)=(_ => ()),
  ~children: element,
) => {
  let (streamStatus, setStreamStatus) = createSignal("disconnected")
  let (streamError, setStreamError) = createSignal(None)
  let (eventCount, setEventCount) = createSignal(0)
  let (lastEventKind, setLastEventKind) = createSignal(None)

  createEffect(() => {
    let sdk = client()
    let subscription =
      OpencodeClient.subscribeGlobalEvents(
        sdk,
        ~onOpen=() => {
          setStreamStatus(_ => "connected")
          setStreamError(_ => None)
          onOpen()
        },
        ~onEvent=event => {
          setStreamStatus(_ => "connected")
          setStreamError(_ => None)
          setEventCount(prev => prev + 1)
          setLastEventKind(_ => Some(OpencodeEvent.kind(event)))
          onEvent(event)
        },
        ~onError=message => {
          setStreamStatus(_ => "error")
          setStreamError(_ => Some(message))
          onError(message)
        },
        (),
      )

    onCleanup(() => OpencodeClient.closeSubscription(subscription))
  })

  let value: t = {
    streamStatus,
    streamError,
    eventCount,
    lastEventKind,
  }

  let providerComponent = ContextSupport.provider(context)
  providerComponent({value: value, children: children})
}
