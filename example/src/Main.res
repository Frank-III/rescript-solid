open SolidWeb

// Mount the app
switch Document.getElementById("app") {
| Some(root) => {
    let dispose = render(() => <App />, root)
    // Log success
    Console.log("App mounted successfully!")
    ignore(dispose)
  }
| None => Console.error("Could not find root element")
}