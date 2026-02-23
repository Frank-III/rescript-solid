# rescript-show-ppx

Experimental source transform for ReScript + Solid.

## `@show` (v2)

This transform rewrites `@show switch` expressions into Solid control-flow
components.

### 1) Option narrowing -> `ShowOption`

Supported:

```rescript
@show
switch someOption {
| Some(value) => <Value value />
| None => <Fallback />
}
```

or

```rescript
@show
switch someOption {
| Some(value) => <Value value />
| _ => <Fallback />
}
```

Generated shape:

```rescript
<SolidJSX.ShowOption when_={someOption} fallback={<Fallback />}>
  {value => <Value value />}
</SolidJSX.ShowOption>
```

### 2) Single payload constructor + fallback -> `ShowOption`

Supported:

```rescript
@show
switch state {
| Loaded(value) => <LoadedView value />
| _ => <LoadingView />
}
```

Generated shape:

```rescript
<SolidJSX.ShowOption
  when_={switch state {
    | Loaded(value) => Some(value)
    | _ => None
  }}
  fallback={<LoadingView />}
>
  {value => <LoadedView value />}
</SolidJSX.ShowOption>
```

### 3) Literal/constructor value matching -> `Switch`/`Match`

Supported:

```rescript
@show
switch status {
| "zero" => <Zero />
| "low" => <Low />
| _ => <High />
}
```

Generated shape:

```rescript
<SolidJSX.Switch.make fallback_={<High />}>
  <SolidJSX.Match.make when_={status == "zero"}><Zero /></SolidJSX.Match.make>
  <SolidJSX.Match.make when_={status == "low"}><Low /></SolidJSX.Match.make>
</SolidJSX.Switch.make>
```

## Native PPX handoff

The native OCaml PPX package (`packages/rescript-show-ppx-native`) is now wired
into ReScript builds.

Current split:

- JS transformer handles `@show` and `@defer` rewriting.
- Native PPX starts porting `@show` (`option` switch form).

Once native parity is complete, the JS transform will be retired.

## Usage

Rewrite files in place:

```bash
bun packages/rescript-show-ppx/bin/show-ppx.mjs rewrite examples/router/src
```

Temporary transform while running `rescript` (restores originals afterward):

```bash
bun packages/rescript-show-ppx/bin/show-ppx.mjs run examples/router/src -- rescript
```
