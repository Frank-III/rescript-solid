open SolidWeb

switch Document.getElementById("app") {
| Some(root) => ignore(render(() => <App />, root))
| None => Console.error("Could not find root element")
}

