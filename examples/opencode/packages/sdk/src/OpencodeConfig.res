type t = {
  serverUrl: string,
  authToken: option<string>,
  defaultHeaders: array<(string, string)>,
}

let make = (~serverUrl, ~authToken=?, ~defaultHeaders=[], ()): t => {
  serverUrl,
  authToken,
  defaultHeaders,
}

let withServerUrl = (config: t, serverUrl: string): t => {
  ...config,
  serverUrl,
}

let withAuthToken = (config: t, authToken: string): t => {
  ...config,
  authToken: Some(authToken),
}

let clearAuthToken = (config: t): t => {
  ...config,
  authToken: None,
}

let withDefaultHeaders = (config: t, defaultHeaders: array<(string, string)>): t => {
  ...config,
  defaultHeaders,
}

let resolveUrl = (config: t, path: string): string => config.serverUrl ++ path
