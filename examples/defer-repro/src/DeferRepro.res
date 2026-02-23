open Solid

@jsx.component
let make = () => {
  let (count, _setCount) = createSignal(0)
  <div>
    <p>{string("Probe")}</p>
    {@defer {
      <p>{string("Deferred count: " ++ count()->Int.toString)}</p>
    }}
  </div>
}
