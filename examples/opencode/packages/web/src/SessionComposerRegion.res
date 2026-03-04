open Solid

module For = SolidJSX.For

@get external getInputValue: {..} => string = "value"
@get external getKeyboardKey: JsxEvent.Keyboard.t => string = "key"
@get external getKeyboardShiftKey: JsxEvent.Keyboard.t => bool = "shiftKey"
@send external preventDefault: JsxEvent.Keyboard.t => unit = "preventDefault"

type modelOption = {
  value: string,
  label: string,
}

@jsx.component
let make = (
  ~modelSelectValue: string,
  ~modelOptions: array<modelOption>,
  ~customModelSentinel: string,
  ~customModelEnabled: bool,
  ~modelDraft: string,
  ~onModelSelectionChange: string => unit,
  ~onModelDraftInput: string => unit,
  ~composerDraft: string,
  ~onComposerInput: string => unit,
  ~isSending: bool,
  ~canSend: bool,
  ~onSend: unit => unit,
  ~onClear: unit => unit,
  ~onComposerSubmitFromKeyboard: unit => unit,
  ~composerError: option<string>,
) =>
  <section className="sessionComposerDock">
    <header>
      <p className="sessionRoute">{string("Composer")}</p>
      <p className="composerModelHint">
        {string("Draft the next turn, then send or clear this session input.")}
      </p>
    </header>
    <div className="composerModelRow">
      <p className="sessionRoute">{string("Model override")}</p>
      <select
        id="composer-model-select"
        className="composerModelSelect"
        value={modelSelectValue}
        onInput={event => {
          let value = event->JsxEvent.Form.target->getInputValue
          onModelSelectionChange(value)
        }}>
        <option value="">{string("Default (session model)")}</option>
        <For each_={modelOptions} fallback_={<option value="">{string("No models available")}</option>}>
          {(option, _index) => <option value={option.value}>{string(option.label)}</option>}
        </For>
        <option value={customModelSentinel}>{string("Custom model...")}</option>
      </select>
      {@show switch customModelEnabled {
      | true =>
        <input
          id="composer-model-input"
          className="composerModelInput"
          placeholder="e.g. anthropic/claude-sonnet-4-5"
          value={modelDraft}
          onInput={event => {
            let value = event->JsxEvent.Form.target->getInputValue
            onModelDraftInput(value)
          }}
        />
      | false =>
        <p className="sessionRoute composerModelHint">
          {string("Use the session default, choose a preset, or provide a custom model id.")}
        </p>
      }}
    </div>
    <textarea
      className="composerInput"
      placeholder="Ask OpenCode to continue this session..."
      value={composerDraft}
      onInput={event => {
        let value = event->JsxEvent.Form.target->getInputValue
        onComposerInput(value)
      }}
      onKeyDown={event => {
        let key = event->getKeyboardKey
        if key == "Enter" && !(event->getKeyboardShiftKey) {
          event->preventDefault
          onComposerSubmitFromKeyboard()
        }
      }}
    />
    <div className="queryActions">
      <button
        id="composer-send-btn"
        className="refreshBtn"
        disabled={isSending || composerDraft->String.trim == "" || !canSend}
        onClick={_ => onSend()}>
        {string(if isSending {"Sending..."} else {"Send"})}
      </button>
      <button
        id="composer-clear-btn"
        className="ghostBtn"
        disabled={isSending || composerDraft == ""}
        onClick={_ => onClear()}>
        {string("Clear")}
      </button>
    </div>
    {@show switch composerError {
    | Some(error) => <p className="errorText">{string(error)}</p>
    | None =>
      <p className="composerModelHint">{string("Press Enter to send and Shift+Enter for a new line.")}</p>
    }}
  </section>
