open Solid

let (count, _setCount) = createSignal(0)

let value =
  {@defer {
    <p>{string("Deferred count: " ++ count()->Int.toString)}</p>
  }}
