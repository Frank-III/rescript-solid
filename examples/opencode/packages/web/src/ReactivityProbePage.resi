@jsx.component
let make: (
  ~streamEventCount: int,
  ~recentEventCount: int,
  ~trackedMessageCount: int,
  ~trackedPartCount: int,
  ~sessionCount: int,
  ~activeSessionId: option<string>,
) => Solid.element
