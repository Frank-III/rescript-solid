type method_ = [#GET | #POST]

type error =
  | NetworkError(string)
  | HttpError({status: int, bodyText: string})
  | InvalidJson(string)

type t

let make: OpencodeConfig.t => t
let requestJson: (
  t,
  ~method_: method_,
  ~path: string,
  ~headers: array<(string, string)>=?,
  ~body: JSON.t=?,
  unit,
) => promise<result<JSON.t, error>>
let getJson: (t, ~path: string, ~headers: array<(string, string)>=?, unit) => promise<result<JSON.t, error>>
let postJson: (
  t,
  ~path: string,
  ~body: JSON.t,
  ~headers: array<(string, string)>=?,
  unit,
) => promise<result<JSON.t, error>>

let postJsonAck: (
  t,
  ~path: string,
  ~body: JSON.t,
  ~headers: array<(string, string)>=?,
  unit,
) => promise<result<unit, error>>
