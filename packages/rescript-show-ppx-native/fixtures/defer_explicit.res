module SolidJSX = {
  let ppxDefer = (children: unit => int) => children()
}

let value = SolidJSX.ppxDefer(() => 1 + 2)
