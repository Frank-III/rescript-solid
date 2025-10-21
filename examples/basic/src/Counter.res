open Solid

@jsx.component
let make = (~initialCount: int=0, ()) => {
  let (count, setCount) = createSignal(initialCount)
  let increment = _ => setCount(prev => prev + 1)
  let decrement = _ => setCount(prev => prev - 1)
  let reset = _ => setCount(_ => initialCount)
  let doubleCount = createMemo(() => count() * 2)
  <div>
    <h2>{string("Counter Component")}</h2>
    <p>{string("Count: ")}<strong>{int(count())}</strong></p>
    <p>{string("Double: ")}<strong>{int(doubleCount())}</strong></p>
    <div>
      <button onClick=decrement>{string("Decrement")}</button>
      <button onClick=reset>{string("Reset")}</button>
      <button onClick=increment>{string("Increment")}</button>
    </div>
  </div>
}

