# ReScript-Solid Form Events API Guide

## Accessing Form Event Target Values

When working with form events in ReScript-Solid, you need to properly access the `target.value` property from `JsxEvent.Form.t` events.

### The Problem

The `JsxEvent.Form.t` type has a `target` property that returns an open object type `{..}`. To access the `value` property, you need to properly type it.

### Solution 1: Using External Bindings (Recommended)

Create helper functions with external bindings:

```rescript
// FormEventHelpers.res

// External binding to get value from any target object
@get
external getInputValue: {..} => string = "value"

// Helper function to get value from JsxEvent.Form.t
let getFormEventValue = (event: JsxEvent.Form.t): string => {
  event->JsxEvent.Form.target->getInputValue
}
```

Usage:
```rescript
<input
  type_="text"
  value={inputValue()}
  onInput={e => {
    let value = FormEventHelpers.getFormEventValue(e)
    setInputValue(_ => value)
  }}
/>
```

### Solution 2: Type Casting Approach

Define typed targets and cast the event target:

```rescript
// Type definition for an input element target
type inputTarget = {
  "value": string,
  "checked": bool,
  "name": string,
}

// Cast the target to an input element
external targetAsInputElement: {..} => inputTarget = "%identity"

// Helper using the cast approach
let getFormEventValueAlt = (event: JsxEvent.Form.t): string => {
  let target = event->JsxEvent.Form.target->targetAsInputElement
  target["value"]
}
```

### Solution 3: Direct Property Access

You can also directly access the property using the pipe operator:

```rescript
<select
  value={selectValue()}
  onChange={e => {
    let value = e->JsxEvent.Form.target->FormEventHelpers.getInputValue
    setSelectValue(_ => value)
  }}
/>
```

### Solution 4: Raw JavaScript (Fallback)

When other methods don't work, you can use raw JavaScript:

```rescript
<input
  onInput={e => {
    let value: string = %raw(`e.target.value`)
    setInputValue(_ => value)
  }}
/>
```

## Complete Example

See `FormEventExample.res` for a complete working example demonstrating all these approaches with different form elements (text input, select, checkbox, textarea).

## Key Points

1. **Always use typed approaches when possible** - External bindings provide type safety
2. **Create reusable helpers** - Put common event accessors in a shared module
3. **Consider different form elements** - Checkboxes need `checked`, selects and inputs need `value`
4. **The target is an open object** - ReScript's `{..}` type requires proper handling
5. **JsxEvent follows React's synthetic event model** - The API is similar to React's event system

## Available Event Types

- `JsxEvent.Form.t` - For onChange, onInput, onSubmit events
- `JsxEvent.Mouse.t` - For onClick, onMouseOver events  
- `JsxEvent.Keyboard.t` - For onKeyDown, onKeyUp events
- `JsxEvent.Focus.t` - For onFocus, onBlur events

Each event type has a `target` property that returns `{..}` which can be accessed using the patterns shown above.