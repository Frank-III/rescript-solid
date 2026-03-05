open Solid

@jsx.component
let make = () => {
  let (count, _setCount) = createSignal(2)
  let maybeLabel = createMemo(() => if count() % 2 == 0 { Some("even") } else { None })

  let deferredLabel =
    {@defer {
      switch maybeLabel() {
      | Some(label) => "label: " ++ label ++ ", n=" ++ Int.toString(count())
      | None => "label: odd"
      }
    }}

  <section>
    <p>{string("PPX smoke")}</p>
    <p>{string(deferredLabel)}</p>
    {@defer {
      <p>{string("Deferred JSX value: " ++ count()->Int.toString)}</p>
    }}
  </section>
}
