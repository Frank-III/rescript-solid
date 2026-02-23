# rescript-http PPX: Type-Safe Routes (Design Draft)

This document proposes a PPX that generates type-safe HTTP routes for the
`rescript-http` package. The goal is Elysia/Hono-level DX while preserving
explicit types and `JSON.t` payloads.

## Goals

- Minimal boilerplate: no manual decoders/encoders at call sites.
- End-to-end type safety: params/body/response types are enforced.
- Keep runtime small and predictable.
- Allow protocol swapping via a `Decode` module later.

## Proposed Syntax

### Basic route

```rescript
@route("/users/:id", method=#GET)
let getUser = (params: {id: int}, _body: unit) =>
  Http.json(JSON.string(params.id))
```

### POST with JSON body

```rescript
type CreateUser = {name: string, age: int}

@route("/users", method=#POST)
let createUser = (_params: unit, body: CreateUser) =>
  Http.json(JSON.string(body.name))
```

### Custom response type

```rescript
type User = {id: int, name: string}

@route("/users/:id", method=#GET)
let getUser = (params: {id: int}, _body: unit) =>
  Http.json(User.encode(params.id))
```

## Inference Rules

- **Params type**: inferred from the first argument type annotation.
  - Path params (e.g. `:id`) must exist as fields on the params record.
  - Path param types must be `string | int | float | bool`.
- **Body type**: inferred from the second argument type annotation.
  - `unit` means no body.
  - Any other type uses JSON decoding.
- **Response type**: inferred from the expression returned by the handler.
  - The handler must return `Http.response<'a>`.
- **JSON**: encode/decode always uses `JSON.t`.

## Generated Code (Conceptual)

```rescript
let getUserRoute =
  Http.get(
    ~path="/users/:id",
    ~params=Params.decode,
    ~body=Http.bodyNone,
    ~response=User.encode,
    ({params, _body, _req}) =>
      Promise.resolve(Http.json(User.encode(params.id))),
  )
```

## Derived Decoders/Encoders

PPX generates these helpers per route:

- `Params.decode: dict<string> => Result<params, string>`
- `Body.decode: option<JSON.t> => Result<body, string>`
- `Response.encode: resp => JSON.t`

For record fields:

- `int`: parse using `Int.fromString` or error
- `float`: parse using `Float.fromString` or error
- `bool`: accept `"true" | "false"`
- `string`: pass through

## Errors

PPX should produce clear, compile-time errors for:

- Missing `:param` in params record
- Unsupported param type
- Handler without type annotations
- Body type without JSON codec (if custom codecs are required)

## Future: Protocol Switching

The PPX can target a functorized API:

```rescript
module Http = Http.Make(JsonDecode)
```

So the generated routes call into `Http` rather than a fixed backend.

## Minimal Implementation Plan

1) **Parse attributes**: `@route("/path", method=#GET)` on `let` bindings
2) **Extract type annotations**: params/body types must be explicit
3) **Generate decoders**: inline functions per route
4) **Emit route value**: `Http.get` or `Http.post` with generated helpers
5) **Keep handler unchanged**: wrap to match `Http.handler` signature

## Non-goals (initial)

- Query params
- Wildcards (`*`)
- Streaming/SSE/WS handler generation

These can be added once the core route generation is stable.
