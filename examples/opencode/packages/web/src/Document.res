@val @scope("document")
external getElementByIdUnsafe: string => Nullable.t<Dom.element> = "getElementById"

let getElementById = id => getElementByIdUnsafe(id)->Nullable.toOption
