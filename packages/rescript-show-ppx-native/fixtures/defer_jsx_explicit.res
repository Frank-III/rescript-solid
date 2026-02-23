open Solid

module SolidJSX = {
  let ppxDefer = (children: unit => element) => children()
}

let (count, _setCount) = createSignal(0)

let value =
  SolidJSX.ppxDefer(() => <p>{string("Deferred count: " ++ count()->Int.toString)}</p>)
