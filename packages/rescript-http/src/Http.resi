type request
type responseObject
type readableStream

type method = [#GET | #POST | #PUT | #PATCH | #DELETE | #OPTIONS]
type params = dict<string>

type paramsDecoder<'a> = params => Result<'a, string>
type bodyDecoder<'a> = option<JSON.t> => Result<'a, string>
type responseEncoder<'a> = 'a => JSON.t

type response<'a> =
  | Json('a, int)
  | Text(string, int)
  | Stream(readableStream, int)
  | Sse(readableStream, int)
  | Empty(int)

type handler<'params, 'body, 'resp> =
  {params: 'params, body: 'body, req: request} => Promise.t<response<'resp>>

type endpoint
type wsRoute
type router

let json: (~status: int=?, 'a) => response<'a>
let text: (~status: int=?, string) => response<'a>
let stream: (~status: int=?, readableStream) => response<'a>
let sse: (~status: int=?, readableStream) => response<'a>
let empty: (~status: int=?, unit) => response<'a>

let paramsNone: paramsDecoder<unit>
let bodyNone: bodyDecoder<unit>
let bodyJson: bodyDecoder<JSON.t>
let responseJson: responseEncoder<JSON.t>

let route: (
  ~method: method,
  ~path: string,
  ~params: paramsDecoder<'params>,
  ~body: bodyDecoder<'body>,
  ~response: responseEncoder<'resp>,
  handler<'params, 'body, 'resp>,
) => endpoint

let get: (
  ~path: string,
  ~params: paramsDecoder<'params>,
  ~body: bodyDecoder<'body>,
  ~response: responseEncoder<'resp>,
  handler<'params, 'body, 'resp>,
) => endpoint

let post: (
  ~path: string,
  ~params: paramsDecoder<'params>,
  ~body: bodyDecoder<'body>,
  ~response: responseEncoder<'resp>,
  handler<'params, 'body, 'resp>,
) => endpoint

let ws: (~path: string, ~params: paramsDecoder<'params>) => wsRoute
let make: array<endpoint> => router
let makeWithWs: (~routes: array<endpoint>, ~wsRoutes: array<wsRoute>) => router
let matchWs: (router, request) => Result<option<JSON.t>, string>
let handleRequest: (router, request) => Promise.t<responseObject>

module Bun: {
  type server
  type websocket<'data>
  type websocketHandlers<'data> = {
    open: websocket<'data> => unit,
    message: (websocket<'data>, string) => unit,
    close: (websocket<'data>, int, string) => unit,
  }

  let serve: (
    ~router: router,
    ~websocket: websocketHandlers<'data>,
    ~wsData: ('params, request) => 'data,
    unit,
  ) => server
}
