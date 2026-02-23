open Solid

@jsx.component
let make = () => {
  let (count, _setCount) = createSignal(0)
  <div>
    {@defer {
      <p>{string("Deferred count: " ++ count()->Int.toString)}</p>
    }}
  </div>
}
