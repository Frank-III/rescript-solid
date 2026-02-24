# rescript-show-ppx-native

Native OCaml PPX for ReScript Solid directives.

This package is the robust migration path from the JS source transformer.

## Current scope

- `@show` rewrite for `switch` on `option` (`Some` + `None`/`_` fallback).
- `@defer` is currently pass-through in native PPX.
  Use explicit `SolidJSX.ppxDefer(() => expr)` in source for now.

## Build

```bash
opam exec -- dune build --root packages/rescript-show-ppx-native
```

Executable path:

```bash
packages/rescript-show-ppx-native/_build/default/bin/show_ppx_native.exe
```
