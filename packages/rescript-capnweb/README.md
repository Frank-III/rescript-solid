# rescript-capnweb

Minimal ReScript bindings for Cap'n Web (client + server), plus a tiny JS helper
to wrap ReScript objects as `RpcTarget` instances.

## Client example (WebSocket)

```rescript
open Capnweb

type api = {
  hello: string => Promise.t<string>,
}

let api: rpcStub<api> = newWebSocketRpcSession("wss://example.com/api")
let result = await api.hello("World")
```

## Server example (Bun)

```rescript
open Capnweb

type api = {
  hello: string => string,
}

let impl: api = {
  hello: name => "Hello " ++ name,
}

let target = makeTarget(impl)

let handler = req => newHttpBatchRpcResponse(req, target)

// In Bun:
// Bun.serve({fetch: handler})
```

## WebSocket server (Bun)

```rescript
open Capnweb

type api = {
  hello: string => string,
}

let impl: api = {
  hello: name => "Hello " ++ name,
}

let target = makeTarget(impl)

// When Bun upgrades a WebSocket, pass the socket to the server session:
// newWebSocketRpcSessionServer(socket, target)
```
