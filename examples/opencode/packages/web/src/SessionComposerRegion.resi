type modelOption = {
  value: string,
  label: string,
}

@jsx.component
let make: (
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
) => Solid.element
