open SolidWeb

let mount = () =>
  switch Document.getElementById("app") {
  | Some(root) => {
      let initialServer = WebPlatform.deriveDefaultServerUrl()
      let _ = render(() => <App defaultServer=initialServer />, root)
      ()
    }
  | None => Console.error("Could not find root element")
  }

let _ = mount()
