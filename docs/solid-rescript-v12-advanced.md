# ReScript v12 + Solid: Advanced Patterns (Preserve JSX)

This guide focuses on Solid-friendly patterns when using ReScript v12 with JSX preserve mode.

## JSX Preserve Configuration

Use v12 JSX preserve mode and point JSX at the Solid runtime:

```json
{
  "jsx": {
    "version": 4,
    "module": "Solid",
    "preserve": true
  }
}
```

## Reactive Reads: Keep Them In Tracking

Solid tracks reads that happen inside JSX expressions, memos, or effects.
Avoid storing reactive values into plain locals.

### Good: Inline reads in JSX

```rescript
<div>{React.string(count())}</div>
```

### Good: Memo then call

```rescript
let view = createMemo(() =>
  switch route() {
  | "home" => <Home />
  | _ => <NotFound />
  }
)

<div>{view()}</div>
```

### Bad: Early read into local

```rescript
let current = route()
<div>{React.string(current)}</div>
```

## Reactive Switch Patterns

`switch` is reactive only when it runs inside a tracked computation.

### Inline switch

```rescript
<div>
  {switch route() {
   | "home" => <Home />
   | "user" => <User />
   | _ => <NotFound />
   }}
</div>
```

### Memoized switch

```rescript
let view = createMemo(() =>
  switch route() {
  | "home" => <Home />
  | "user" => <User />
  | _ => <NotFound />
  }
)

<div>{view()}</div>
```

### Switch/Match components

```rescript
module Switch = SolidJSX.Switch
module Match = SolidJSX.Match

<Switch.make>
  <Match.make when_={route() == "home"}><Home /></Match.make>
  <Match.make when_={route() == "user"}><User /></Match.make>
  <Match.make when_={true}><NotFound /></Match.make>
</Switch.make>
```

## Scoped JSX (Closure Return)

If you want to predefine JSX, keep it as a function or memo so it runs reactively.

### Function

```rescript
let body = () => <div>{React.string(name())}</div>
<div>{body()}</div>
```

### Memo

```rescript
let body = createMemo(() => <div>{React.string(name())}</div>)
<div>{body()}</div>
```

## Option-Friendly Show

`Show` passes its `when_` value directly to children. If you pass an option,
the child receives an option and you must `switch`.

Use `ShowOption` to narrow `option<'a>` to `'a` once:

```rescript
module ShowOption = SolidJSX.ShowOption

<ShowOption when_={data()}>
  {value => <div>{React.string(value)}</div>}
</ShowOption>
```

## PPX: `@show` (v2)

For Solid-style narrowing DX, `rescript-show-ppx` supports `@show`.

Use `@show` on `switch` to compile into Solid control-flow primitives while
preserving narrowing patterns.

Input style:

```rescript
@show
switch state {
| Loaded(user) => <UserCard user />
| _ => <Spinner />
}
```

Generated style (conceptual):

```rescript
let narrowed = switch state {
| Loaded(user) => Some(user)
| _ => None
}

<ShowOption when_={narrowed} fallback={<Spinner />}>
  {user => <UserCard user />}
</ShowOption>
```

This keeps narrowing explicit via pattern matching while giving a compact JSX
authoring style.

Current v2 scope:

- `option` switches (`Some(value)` + `None`/`_`) -> `ShowOption`
- single payload constructor + fallback (e.g. `Loaded(value)` + `_`) -> `ShowOption`
- literal/constructor value branches + optional `_` fallback -> `Switch`/`Match`

### `@defer` scoped block

`@defer` lets you write an inline scoped block that compiles to an IIFE-style
expression.

Input:

```rescript
{@defer {
  let label = "Deferred count: " ++ count()->Int.toString
  <p>{string(label)}</p>
}}
```

Generated shape:

```rescript
{(() => {
  let label = "Deferred count: " ++ count()->Int.toString
  <p>{string(label)}</p>
})()}
```

## Common Reactive Sources

Treat these as reactive sources and avoid early reads:

- `createSignal` accessors
- `createMemo` accessors
- `createResource` accessors
- `useParams`, `useLocation`, `useSearchParams`, `useMatch`, `useIsRouting`

If you need to derive a value, wrap it in `createMemo` and call it where used.

## JS to ReScript: Practical Migration

There is no official automatic JS -> ReScript converter. The most reliable path
is manual translation with incremental interop.

### Recommended workflow

1) Bind JS modules with `external` and keep the JS implementation.
2) Convert one file at a time to `.res`.
3) Move logic out of externals into ReScript as you go.

### Example: JS function -> ReScript

JavaScript:

```js
export function add(a, b) {
  return a + b
}
```

ReScript:

```rescript
let add = (a: int, b: int) => a + b
```

### Example: JS module -> external binding

JavaScript module:

```js
export function greet(name) {
  return `Hello ${name}`
}
```

ReScript binding:

```rescript
@module("./greet.js")
external greet: string => string = "greet"
```

Then later replace the external with a pure ReScript implementation and delete
the JS file.
