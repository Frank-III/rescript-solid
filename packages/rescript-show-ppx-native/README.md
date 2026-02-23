# rescript-show-ppx-native

Native OCaml PPX for ReScript Solid directives.

This package is the robust migration path from the JS source transformer.

## Current scope

- `@show` rewrite for `switch` on `option` (`Some` + `None`/`_` fallback).
- `@defer` is pass-through by default in native PPX.
- With `RESCRIPT_SHOW_PPX_NATIVE_DEFER=1`, native `@defer` rewrites only
  non-JSX payloads and keeps JSX payloads as pass-through for call-shape
  stability.

## Defer investigation

Run the investigation matrix:

```bash
bun run -F rescript-show-ppx-native investigate:defer
```

To probe the env-gated native `@defer` rewrite path against router sources, set:

```bash
RESCRIPT_SHOW_PPX_NATIVE_DEFER=1 bun run -F solid-examples-router res:build
```

Current finding: the native defer guard now passes the router full-build probe
while keeping JSX-defer payloads in pass-through mode.

## Build

```bash
opam exec -- dune build --root packages/rescript-show-ppx-native
```

Executable path:

```bash
packages/rescript-show-ppx-native/_build/default/bin/show_ppx_native.exe
```
