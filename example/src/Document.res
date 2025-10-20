// Document utilities

@val @scope("document")
external getElementById: string => Nullable.t<Dom.element> = "getElementById"

let getElementById = id => getElementById(id)->Nullable.toOption