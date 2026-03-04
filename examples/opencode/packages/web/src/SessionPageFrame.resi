open Solid

type displayedSession = {
  id: string,
  subtitle: string,
}

@jsx.component
let make: (
  ~workspaceDirectory: string,
  ~sessionRouteId: string,
  ~statusText: string,
  ~displayedSession: option<displayedSession>,
  ~hasSessionMetadata: bool,
  ~hasSessionActivity: bool,
  ~conversationPanel: element,
  ~composerRegion: element,
  ~sidePanel: element,
  ~backHref: string,
) => Solid.element
