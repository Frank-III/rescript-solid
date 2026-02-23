type request
type responseObject
type websocket
type rpcTarget
type rpcStub<'api>
type rpcPromise<'a>
type disposable

@module("./CapnwebTarget.js")
external makeTarget: 'impl => rpcTarget = "makeTarget"

@module("capnweb")
external newWebSocketRpcSession: string => rpcStub<'api> = "newWebSocketRpcSession"

@module("capnweb")
external newHttpBatchRpcSession: string => rpcStub<'api> = "newHttpBatchRpcSession"

@module("capnweb")
external newHttpBatchRpcResponse: (request, rpcTarget) => Promise.t<responseObject> =
  "newHttpBatchRpcResponse"

@module("capnweb")
external newWebSocketRpcSessionServer: (websocket, rpcTarget) => disposable =
  "newWebSocketRpcSession"
