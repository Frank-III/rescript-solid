# ReScript + SolidJS (JSX v4 Preserve)

This package wires ReScript’s generic JSX v4 to SolidJS and runs in JSX preserve mode so Vite’s Solid plugin can compile the raw JSX. Result: idiomatic ReScript, Solid’s fine‑grained updates, and type‑checked props — without a React shim.

## Install

```sh
npm install
```

This project expects `solid-js` to be present (added to `package.json`).

## Build

- Library build: `npm run build` (runs `rescript`)
- Clean: `npm run clean`

Example app (under `example/`):

- Dev server: `npm run dev` (Vite + preserve-mode JSX)
- Build: `npm run build` (runs `rescript && vite build`)

## Usage

- `rescript.json` delegates JSX to module `Solid` and enables preserve mode. Output suffix is `.mjs` so Vite can transform raw JSX.
- `src/Solid.res` provides the generic JSX surface; `src/SolidDOM.res` extends DOM props with Solid extras.
- Control flow components are in `src/SolidJSX.res` and are exported as modules with `make`.
- Example app lives under `example/` and demonstrates Solid patterns in ReScript.

Minimal component in ReScript:

```rescript
open Solid

@jsx.component
let make = (~name: string, ()) => {
  <div class="greeting">{string("Hello, " ++ name)}</div>
}
```

## API Surface

- JSX runtime: `Solid.jsx/jsxs/Fragment`, `Solid.Elements` (lowercase DOM; props = `SolidDOM.domProps`)
- Reactivity: `createSignal`, `createMemo`, `createEffect`, `on`, `untrack`, `batch`, `createRoot`
- Lifecycle: `onMount`, `onCleanup`, `onError`
- Context: `createContext`, `useContext`, `children`, `createUniqueId`
- Resources: `createResource`
- Store: in `src/SolidStore.res` (`createStore`, `produce`, `reconcile`, `unwrap`, `createMutable`)
- Web: in `src/SolidWeb.res` (`render`, `hydrate`, `renderToString`, `renderToStringAsync`, `renderToStream`, `isServer`)
- Control flow (modules with `make`): `SolidJSX.Show`, `For`, `Index`, `Switch`, `Match`, `ErrorBoundary`, `Suspense`, `SuspenseList`, `Portal`, `Dynamic`, `NoHydration`

## Notes for JSX Preserve

- Children must be `Jsx.element`. Wrap primitives: `Solid.string`, `Solid.int`, `Solid.float`.
- Avoid inline JSX comments (`{/* ... */}`) — they parse as `{}`; comment outside JSX.
- DOM props supported via `SolidDOM.domProps`: `class`, `classList`, `textContent`, `innerHTML`, plus base `JsxDOM.domProps` like `onClick`, `style`, etc.
- Control flow props in ReScript use suffixed labels mapped to Solid’s names:
  - `Show`: `when_` → `when`, `fallback_` → `fallback`
  - `For` / `Index`: `each_` → `each`, `fallback_` → `fallback`

Example:

```rescript
module Show = SolidJSX.Show
module For = SolidJSX.For

let (show, setShow) = createSignal(true)
let (items, _setItems) = createSignal(["A", "B", "C"])

<Show when_={show()} fallback_={string("Hidden")}>
  {_ => <div>{string("Visible")}</div>}
</Show>

<For each_={items()} fallback_={string("No items")}>
  {(item, _i) => <div>{string(item)}</div>}
</For>
```

Reactivity tips (important when mixing with ReScript transforms):
- Read signals/resources inside JSX callbacks or control‑flow children; don’t hoist them into lets before JSX.
- Prefer `<Show when_={sig()}>{v => ...}</Show>` over `if sig() { ... } else { ... }` to keep tracking scopes.
- Use `createMemo` for derived values and `on`/`untrack` inside `createEffect` where appropriate.

## Example Index

- App: toggles `<Show>` and lists with `<For>`, counter, then renders `<Features />`.
- Features: shows `createResource + <Show>`, `<Portal>`, memo + effect logging, and `<ErrorBoundary>`.

Run dev: `cd example && npm run dev`

## TypeScript for Vite

The example includes `example/tsconfig.json` with `jsx: "preserve"` and `jsxImportSource: "solid-js"` so editors and vite-plugin-solid understand `.mjs` JSX.
