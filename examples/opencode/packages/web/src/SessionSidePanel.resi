type sessionInfo = {
  id: string,
  title: string,
  updatedAt: string,
  status: string,
}

type projectRow = {
  name: string,
  path: string,
}

@jsx.component
let make: (
  ~serverLookupError: option<string>,
  ~recentEvents: array<string>,
  ~sessionInfo: option<sessionInfo>,
  ~contextLines: array<string>,
  ~projectRows: array<projectRow>,
) => Solid.element
