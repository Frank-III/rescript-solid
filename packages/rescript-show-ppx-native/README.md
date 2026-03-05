# rescript-show-ppx-native

Native OCaml PPX for ReScript Solid directives.

This package is the robust migration path from the JS source transformer.

## Current scope

- `@show` rewrite for `switch` on `option` (`Some` + `None`/`_` fallback)
  and `bool` (`true` + `false`/`_` fallback).
- `@defer` is pass-through by default in native PPX.
- With `RESCRIPT_SHOW_PPX_NATIVE_DEFER=1`, native `@defer` rewrites only
  non-JSX payloads and keeps JSX payloads as pass-through for call-shape
  stability.
- With `RESCRIPT_SHOW_PPX_NATIVE_DEFER_JSX=1` (together with
  `RESCRIPT_SHOW_PPX_NATIVE_DEFER=1`), JSX payloads are also rewritten.
  This is experimental and may regress type inference/LSP in real app contexts.

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

## Isolated repro (JSX auto-rewrite)

This repo includes a minimal isolated repro at `examples/defer-repro`.

Baseline (expected pass):

```bash
bun run -F solid-examples-defer-repro res:clean && bun run -F solid-examples-defer-repro res:build
```

Guarded native `@defer` rewrite (expected pass):

```bash
bun run -F solid-examples-defer-repro res:clean && RESCRIPT_SHOW_PPX_NATIVE_DEFER=1 bun run -F solid-examples-defer-repro res:build
```

Full JSX auto-rewrite (expected failure in current compiler behavior):

```bash
bun run -F solid-examples-defer-repro res:clean && RESCRIPT_SHOW_PPX_NATIVE_DEFER=1 RESCRIPT_SHOW_PPX_NATIVE_DEFER_JSX=1 bun run -F solid-examples-defer-repro res:build
```

Current failure signature:

- File: `examples/defer-repro/src/DeferRepro.res`
- Error: `This function is a curried function where an uncurried function is expected`

For community/forum discussion, include:

- ReScript version and platform
- Commands above
- Transformed output comparison (`-dsource`) between explicit source
  `SolidJSX.ppxDefer(() => <p>...</p>)` and PPX-generated JSX `@defer` rewrite

## Build

```bash
opam exec -- dune build --root packages/rescript-show-ppx-native
```

Executable path:

```bash
packages/rescript-show-ppx-native/_build/default/bin/show_ppx_native.exe
```

Root scripts:

```bash
bun run build:solid2
bun run build:ppx:native
```
