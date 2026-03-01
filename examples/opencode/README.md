# OpenCode ReScript Example

This folder is a mono-style example workspace for reimplementing key OpenCode
web boundaries with `rescript-solid`.

Layout:

- `packages/sdk` - ReScript v12 SDK boundary decoders.
- `packages/web` - web UI spike using `rescript-solid` and sdk package.

Current scope:

- Uses OpenCode server as-is (client-side SDK only in this example).
- SDK client wrapper currently covers:
  - `GET /global/health`
  - `GET /global/event` (EventSource subscription)
  - `GET /project/current`
  - `GET /project`
  - `GET /session`
  - `GET /session/:id`
- Web routes currently include:
  - `/` overview
  - `/sessions`
  - `/:dir/session/:id?`
- Context skeletons now included in web package:
  - `PlatformContext` (browser actions + default server persistence)
  - `ServerContext` (active server + draft/apply/reset/refresh actions)
  - `GlobalSyncContext` (global event stream status/error/count/last-event)

Default server behavior:

- Reads and persists `opencode.settings.dat:defaultServerUrl` in localStorage.
- Falls back to `http://localhost:4096` on `*.opencode.ai` hosts.
- Otherwise falls back to `location.origin`.

Run:

```bash
bun install --cwd examples/opencode
bun run --cwd examples/opencode build
bun run --cwd examples/opencode dev
```
