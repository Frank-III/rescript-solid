let probeSwitchCallOnce = () => Some(1)

let value =
  {@defer {
    switch probeSwitchCallOnce() {
    | Some(v) => v + 1
    | None => 0
    }
  }}
