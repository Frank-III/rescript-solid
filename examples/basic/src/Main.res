open SolidWeb

switch Document.getElementById("app") {
| Some(root) => {
    let dispose = render(() => <App />, root)
    ignore(dispose)
  }
| None => Console.error("Could not find root element")
}

