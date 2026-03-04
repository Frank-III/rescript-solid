type projectRow = {
  label: string,
}

type statusLine = {
  className: string,
  text: string,
}

@jsx.component
let make: (
  ~activeServer: string,
  ~healthText: string,
  ~projectText: string,
  ~sessionCount: int,
  ~projectCount: int,
  ~lastEvent: string,
  ~runningSessionCount: int,
  ~projects: array<projectRow>,
  ~statusLine: statusLine,
) => Solid.element
