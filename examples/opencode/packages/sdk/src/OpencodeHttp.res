type method_ = [#GET | #POST]

type error =
  | NetworkError(string)
  | HttpError({status: int, bodyText: string})
  | InvalidJson(string)

type t = {config: OpencodeConfig.t}

type fetchInit
type response

@obj
external makeFetchInit: (
  @as("method") ~method_: string,
  ~headers: dict<string>,
  ~body: string=?,
  unit,
) => fetchInit = ""

@val external fetchWithInit: (string, fetchInit) => promise<response> = "fetch"
@get external responseOk: response => bool = "ok"
@get external responseStatus: response => int = "status"
@send external responseJson: response => promise<JSON.t> = "json"
@send external responseText: response => promise<string> = "text"
@val external stringifyJson: JSON.t => string = "JSON.stringify"

let make = (config: OpencodeConfig.t): t => {config: config}

let methodToString = (method_: method_): string =>
  switch method_ {
  | #GET => "GET"
  | #POST => "POST"
  }

let authHeaders = (config: OpencodeConfig.t): array<(string, string)> =>
  switch config.authToken {
  | Some(token) => [("Authorization", "Bearer " ++ token)]
  | None => []
  }

let requestHeaders = (~client: t, ~headers: array<(string, string)>, ~withJsonBody: bool): dict<string> => {
  let baseHeaders =
    client.config.defaultHeaders
    ->Array.concat(authHeaders(client.config))
    ->Array.concat(headers)
  let withContentType =
    if withJsonBody {
      baseHeaders->Array.concat([("Content-Type", "application/json")])
    } else {
      baseHeaders
    }
  withContentType->Dict.fromArray
}

let requestJson = async (
  client: t,
  ~method_: method_,
  ~path: string,
  ~headers: array<(string, string)>=[],
  ~body: option<JSON.t>=?,
  (),
) => {
  try {
    let url = OpencodeConfig.resolveUrl(client.config, path)
    let requestBody = body->Option.map(stringifyJson)
    let headerObject = requestHeaders(~client, ~headers, ~withJsonBody=requestBody->Option.isSome)
    let init =
      switch requestBody {
      | Some(payload) => makeFetchInit(~method_=methodToString(method_), ~headers=headerObject, ~body=payload, ())
      | None => makeFetchInit(~method_=methodToString(method_), ~headers=headerObject, ())
      }
    let response = await fetchWithInit(url, init)
    if responseOk(response) {
      let payload = await responseJson(response)
      Ok(payload)
    } else {
      let status = responseStatus(response)
      let bodyText = await responseText(response)
      Error(HttpError({status, bodyText}))
    }
  } catch {
  | _ => Error(NetworkError("Network request failed"))
  }
}

let getJson = (
  client: t,
  ~path: string,
  ~headers: array<(string, string)>=[],
  (),
): promise<result<JSON.t, error>> => requestJson(client, ~method_=#GET, ~path, ~headers, ())

let postJson = (
  client: t,
  ~path: string,
  ~body: JSON.t,
  ~headers: array<(string, string)>=[],
  (),
): promise<result<JSON.t, error>> =>
  requestJson(client, ~method_=#POST, ~path, ~headers, ~body, ())

let postJsonAck = async (
  client: t,
  ~path: string,
  ~body: JSON.t,
  ~headers: array<(string, string)>=[],
  (),
) => {
  try {
    let url = OpencodeConfig.resolveUrl(client.config, path)
    let payload = stringifyJson(body)
    let headerObject = requestHeaders(~client, ~headers, ~withJsonBody=true)
    let init = makeFetchInit(~method_=methodToString(#POST), ~headers=headerObject, ~body=payload, ())
    let response = await fetchWithInit(url, init)
    if responseOk(response) {
      Ok(())
    } else {
      let status = responseStatus(response)
      let bodyText = await responseText(response)
      Error(HttpError({status, bodyText}))
    }
  } catch {
  | _ => Error(NetworkError("Network request failed"))
  }
}
