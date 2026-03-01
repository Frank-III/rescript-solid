type t = {
  serverUrl: string,
  authToken: option<string>,
  defaultHeaders: array<(string, string)>,
}

let make: (~serverUrl: string, ~authToken: string=?, ~defaultHeaders: array<(string, string)>=?, unit) => t
let withServerUrl: (t, string) => t
let withAuthToken: (t, string) => t
let clearAuthToken: t => t
let withDefaultHeaders: (t, array<(string, string)>) => t
let resolveUrl: (t, string) => string
