// Solid-specific DOM props for JSX preserve mode
// Extends the base JsxDOM props with Solid additions

type style = JsxDOMStyle.t
type domRef

type classList = dict<bool>

type domProps = {
  ...JsxDOM.domProps,
  class?: string,
  classList?: classList,
  textContent?: string,
  innerHTML?: string,
}
