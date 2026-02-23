type request
type responseObject
type readableStream
type url
type responseInit

@new external makeUrl: string => url = "URL"
@get external pathname: url => string = "pathname"
@get external requestUrl: request => string = "url"
@get external requestMethod: request => string = "method"
@send external requestJson: request => Promise.t<JSON.t> = "json"

@obj external makeResponseInit: (~status: int=?, ~headers: dict<string>=?) => responseInit = ""
@new external makeResponseText: (string, responseInit) => responseObject = "Response"
@new external makeResponseStream: (readableStream, responseInit) => responseObject = "Response"
@scope("Response") @val external responseJson: (JSON.t, responseInit) => responseObject = "json"

type method = [#GET | #POST | #PUT | #PATCH | #DELETE | #OPTIONS]
type segment =
  | Literal(string)
  | Param(string)

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

type endpoint = {
  method: method,
  segments: array<segment>,
  handle: (params, request) => Promise.t<responseObject>,
}

type wsRoute = {
  segments: array<segment>,
  params: paramsDecoder<JSON.t>,
}

type router = {routes: array<endpoint>, wsRoutes: array<wsRoute>}

let json = (~status=?, value) => {
  let status = status->Option.getOr(200)
  Json(value, status)
}

let text = (~status=?, value) => {
  let status = status->Option.getOr(200)
  Text(value, status)
}

let stream = (~status=?, value) => {
  let status = status->Option.getOr(200)
  Stream(value, status)
}

let sse = (~status=?, value) => {
  let status = status->Option.getOr(200)
  Sse(value, status)
}

let empty = (~status=?, ()) => {
  let status = status->Option.getOr(204)
  Empty(status)
}

let paramsNone: paramsDecoder<unit> = _ => Ok(())
let bodyNone: bodyDecoder<unit> = _ => Ok(())
let bodyJson: bodyDecoder<JSON.t> = body =>
  switch body {
  | Some(value) => Ok(value)
  | None => Error("Missing JSON body")
  }

let responseJson: responseEncoder<JSON.t> = value => value

let sseHeaders =
  Dict.fromArray([|
    ("content-type", "text/event-stream"),
    ("cache-control", "no-cache"),
    ("connection", "keep-alive"),
  |])

let splitPath = path => {
  let len = String.length(path)
  let parts = ref([||])
  let push = value => parts := Array.concat(parts.contents, [|value|])

  if len == 0 {
    [||]
  } else {
    let start = if String.get(path, 0) == '/' { 1 } else { 0 }
    let rec loop = (i, segmentStart) => {
      if i >= len {
        let segmentLen = len - segmentStart
        if segmentLen > 0 {
          push(String.sub(path, segmentStart, segmentLen))
        }
      } else if String.get(path, i) == '/' {
        let segmentLen = i - segmentStart
        if segmentLen > 0 {
          push(String.sub(path, segmentStart, segmentLen))
        }
        loop(i + 1, i + 1)
      } else {
        loop(i + 1, segmentStart)
      }
    }

    loop(start, start)
    parts.contents
  }
}

let compilePath = path => {
  splitPath(path)->Array.map(segment =>
    if String.length(segment) > 0 && String.get(segment, 0) == ':' {
      Param(String.sub(segment, 1, String.length(segment) - 1))
    } else {
      Literal(segment)
    }
  )
}

let matchSegments = (segments, pathSegments) => {
  let segLen = Array.length(segments)
  if segLen != Array.length(pathSegments) {
    None
  } else {
    let params = ref([||])
    let ok = ref(true)

    for i in 0 to segLen - 1 {
      switch (Array.get(segments, i), Array.get(pathSegments, i)) {
      | (Some(Literal(lit)), Some(actual)) =>
        if lit != actual {
          ok := false
        }
      | (Some(Param(name)), Some(actual)) =>
        params := Array.concat(params.contents, [|(name, actual)|])
      | _ => ok := false
      }
    }

    if ok.contents {
      Some(Dict.fromArray(params.contents))
    } else {
      None
    }
  }
}

let methodFromString = value =>
  switch value {
  | "GET" => Some(#GET)
  | "POST" => Some(#POST)
  | "PUT" => Some(#PUT)
  | "PATCH" => Some(#PATCH)
  | "DELETE" => Some(#DELETE)
  | "OPTIONS" => Some(#OPTIONS)
  | _ => None
  }

let toResponse = (resp, encode) =>
  switch resp {
  | Json(value, status) => responseJson(encode(value), makeResponseInit(~status))
  | Text(value, status) => makeResponseText(value, makeResponseInit(~status))
  | Stream(value, status) => makeResponseStream(value, makeResponseInit(~status))
  | Sse(value, status) =>
    makeResponseStream(value, makeResponseInit(~status, ~headers=sseHeaders))
  | Empty(status) => makeResponseText("", makeResponseInit(~status))
  }

let readJson = async req => {
  try {
    Some(await requestJson(req))
  } catch {
  | _ => None
  }
}

let route = (~method, ~path, ~params, ~body, ~response, handler) => {
  let segments = compilePath(path)
  let handle = async (paramsDict, req) => {
    switch params(paramsDict) {
    | Error(msg) =>
      makeResponseText(msg, makeResponseInit(~status=400))
    | Ok(paramsValue) =>
      let bodyJson = await readJson(req)
      switch body(bodyJson) {
      | Error(msg) => makeResponseText(msg, makeResponseInit(~status=400))
      | Ok(bodyValue) =>
        let resp = await handler({params: paramsValue, body: bodyValue, req})
        toResponse(resp, response)
      }
    }
  }

  {method, segments, handle}
}

let get = (~path, ~params, ~body, ~response, handler) =>
  route(~method=#GET, ~path, ~params, ~body, ~response, handler)

let post = (~path, ~params, ~body, ~response, handler) =>
  route(~method=#POST, ~path, ~params, ~body, ~response, handler)

let ws = (~path, ~params) => {
  let segments = compilePath(path)
  {segments, params}
}

let make = routes => {routes, wsRoutes: [||]}

let makeWithWs = (~routes, ~wsRoutes) => {routes, wsRoutes}

let matchWs = (router, req) => {
  switch methodFromString(requestMethod(req)) {
  | Some(#GET) =>
    let url = makeUrl(requestUrl(req))
    let pathSegments = splitPath(pathname(url))
    let routes = router.wsRoutes
    let len = Array.length(routes)

    let rec loop = i =>
      if i >= len {
        Ok(None)
      } else {
        switch Array.get(routes, i) {
        | None => Ok(None)
        | Some(route) =>
          switch matchSegments(route.segments, pathSegments) {
          | None => loop(i + 1)
          | Some(paramsDict) =>
            switch route.params(paramsDict) {
            | Ok(data) => Ok(Some(data))
            | Error(msg) => Error(msg)
            }
          }
        }
      }

    loop(0)
  | _ => Ok(None)
  }
}

let handleRequest = async (router, req) => {
  switch methodFromString(requestMethod(req)) {
  | None => makeResponseText("Method Not Allowed", makeResponseInit(~status=405))
  | Some(method) =>
    let url = makeUrl(requestUrl(req))
    let pathSegments = splitPath(pathname(url))
    let routes = router.routes
    let len = Array.length(routes)

    let rec loop = async i => {
      if i >= len {
        None
      } else {
        switch Array.get(routes, i) {
        | None => None
        | Some(route) =>
          if route.method != method {
            await loop(i + 1)
          } else {
            switch matchSegments(route.segments, pathSegments) {
            | None => await loop(i + 1)
            | Some(paramsDict) => Some(await route.handle(paramsDict, req))
            }
          }
        }
      }
    }

    switch await loop(0) {
    | Some(resp) => resp
    | None => makeResponseText("Not Found", makeResponseInit(~status=404))
    }
  }
}

module Bun = {
  type server
  type websocket<'data>

  type websocketHandlers<'data> = {
    open: websocket<'data> => unit,
    message: (websocket<'data>, string) => unit,
    close: (websocket<'data>, int, string) => unit,
  }

  type serveOptions<'data> = {
    fetch: request => Promise.t<responseObject>,
    websocket: websocketHandlers<'data>,
  }

  @scope("Bun") @val external serveInternal: serveOptions<'data> => server = "serve"
  @send external upgrade: (server, request, {data: 'data}) => bool = "upgrade"
  @obj external makeUpgradeInfo: (~data: 'data) => {..} = ""

  let serve = (~router, ~websocket, ~wsData, ()) => {
    let serverRef = ref(None)
    let fetch = async req =>
      switch serverRef.contents {
      | None => await handleRequest(router, req)
      | Some(server) =>
        switch await matchWs(router, req) {
        | Error(msg) => makeResponseText(msg, makeResponseInit(~status=400))
        | Ok(None) => await handleRequest(router, req)
        | Ok(Some(data)) =>
          let upgradeData = wsData(data, req)
          let ok = server->upgrade(req, makeUpgradeInfo(~data=upgradeData))
          if ok {
            makeResponseText("", makeResponseInit(~status=101))
          } else {
            makeResponseText("Upgrade Failed", makeResponseInit(~status=500))
          }
        }
      }

    let server = serveInternal({fetch, websocket})
    serverRef := Some(server)
    server
  }
}
