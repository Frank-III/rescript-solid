type sidebarSessionItem = {
  id: string,
  href: string,
  isRunning: bool,
}

@jsx.component
let make: (
  ~children: Solid.element,
  ~serverStatusPanel: Solid.element,
  ~sidebarSessions: array<sidebarSessionItem>,
  ~onBack: unit => unit,
  ~onForward: unit => unit,
  ~onReload: unit => unit,
  ~onOpenUpstream: unit => unit,
) => Solid.element
