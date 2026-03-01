open Solid

let appBaseProviders: (~children: element) => element
let appShellProviders: (~children: element) => element
let sessionProviders: (~children: element) => element
let routerRoot: (~children: element) => element
let serverGate: (~server: accessor<string>, ~children: element) => element
