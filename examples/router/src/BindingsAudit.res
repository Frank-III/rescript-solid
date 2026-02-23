open Solid

module Match = SolidPrimitivesMatch
module KSwitch = KobalteSwitch
module Resizable = CorvuResizable
module KDialog = KobalteDialog
module KTabs = KobalteTabs
module EventListener = SolidPrimitivesEventListener
module Keyboard = SolidPrimitivesKeyboard
module Media = SolidPrimitivesMedia
module ResizeObserver = SolidPrimitivesResizeObserver
module Trigger = SolidPrimitivesTrigger
module RSet = SolidPrimitivesSet
module RMap = SolidPrimitivesMap
module KPopover = KobaltePopover
module KAccordion = KobalteAccordion
module KSelect = KobalteSelect

let maybeParityMessage = count =>
  if count % 2 == 0 {
    Some("Parity: even")
  } else {
    None
  }

@jsx.component
let make = () => {
  let (count, setCount) = createSignal(0)
  let (dialogOpen, setDialogOpen) = createSignal(false)
  let (popoverOpen, setPopoverOpen) = createSignal(false)
  let (accordionValue, setAccordionValue) = createSignal("item-a")
  let (selectValue, setSelectValue) = createSignal("apple")
  let (tabValue, setTabValue) = createSignal("first")
  let (windowClicks, setWindowClicks) = createSignal(0)
  let setStore = RSet.makeReactiveSetFromArray(["alpha", "beta"])
  let mapStore = RMap.makeReactiveMapFromArray([("alpha", 1), ("beta", 2)])
  let prefersDark = Media.usePrefersDark()
  let isNarrow = Media.createMediaQuery("(max-width: 900px)", None)
  let windowSize = ResizeObserver.useWindowSize()
  let windowSizeSnapshot = ResizeObserver.getWindowSize()
  let maybeElementSize = ResizeObserver.getElementSize(None)
  let maybeElementWidthText =
    switch maybeElementSize.width->Nullable.toOption {
    | Some(width) => width->Float.toString
    | None => "none"
    }
  let (trackTrigger, markDirty) = Trigger.createTrigger()

  EventListener.createEventListener(
    ~target=EventListener.window,
    ~type_="click",
    ~handler={_ => setWindowClicks(prev => prev + 1)},
    (),
  )

  EventListener.createEventListenerMap(
    EventListener.window,
    EventListener.handlers([
      ("dblclick", _ => setCount(prev => prev + 2)),
    ]),
    None,
  )

  let isShiftHeld = Keyboard.createKeyHold("Shift", None)
  let keysDown = Keyboard.useKeyDownList()

  Keyboard.createShortcut(
    ["Shift", "K"],
    _event => setCount(prev => prev + 1),
    None,
  )

  let triggerSummary = () => {
    trackTrigger()
    "Tracked clicks: " ++ windowClicks()->Int.toString
  }

  let status = () =>
    if count() == 0 {
      "zero"
    } else if count() < 3 {
      "low"
    } else {
      "high"
    }

  let cases =
    Match.MatchValue.cases([
      ("zero", () => <p>{string("status: zero")}</p>),
      ("low", () => <p>{string("status: low")}</p>),
      ("high", () => <p>{string("status: high")}</p>),
    ])

  <section>
    <h3>{string("Binding Audit")}</h3>
    <button onClick={_ => setCount(prev => prev + 1)}>{string("Increment")}</button>
    <p>{string("Count: " ++ count()->Int.toString)}</p>
    <p>{string("Window clicks: " ++ windowClicks()->Int.toString)}</p>
    <p>{string("Window width: " ++ windowSize.width->Float.toString)}</p>
    <p>{string("Window width snapshot: " ++ windowSizeSnapshot.width->Float.toString)}</p>
    <p>{string("Element width snapshot: " ++ maybeElementWidthText)}</p>
    <p>{string("Prefers dark: " ++ (prefersDark() ? "true" : "false"))}</p>
    <p>{string("Narrow viewport: " ++ (isNarrow() ? "true" : "false"))}</p>
    <p>{string("Shift held: " ++ (isShiftHeld() ? "true" : "false"))}</p>
    <p>{string("Keys down: " ++ keysDown()->Array.length->Int.toString)}</p>
    <p>{string(triggerSummary())}</p>
    <button onClick={_ => markDirty()}>{string("Dirty trigger")}</button>

    <EventListener.WindowEventListener onMousemove={_ => markDirty()} />
    <EventListener.DocumentEventListener onSelectionchange={_ => markDirty()} />

    <button
      onClick={_ => {
        let name = "item-" ++ count()->Int.toString
        ignore(setStore->RSet.add(name))
      }}>
      {string("Add reactive set item")}
    </button>
    <p>{string("Reactive set size: " ++ setStore->RSet.size->Int.toString)}</p>

    <button
      onClick={_ => {
        let next = windowClicks()
        ignore(mapStore->RMap.set("clicks", next))
      }}>
      {string("Update reactive map")}
    </button>
    <p>{string("Reactive map size: " ++ mapStore->RMap.size->Int.toString)}</p>

    <KSwitch.Root checked={count() % 2 == 0} className="k-switch">
      <KSwitch.Input className="k-switch-input" />
      <KSwitch.Label>{string("Even count")}</KSwitch.Label>
      <KSwitch.Control className="k-switch-control">
        <KSwitch.Thumb className="k-switch-thumb" />
      </KSwitch.Control>
      <KSwitch.Description>{string("Toggles with count parity")}</KSwitch.Description>
    </KSwitch.Root>

    <Match.MatchValue
      on={status()}
      case_={cases}
      fallback={() => <p>{string("status: fallback")}</p>}
    />

    <Resizable.Root orientation=#horizontal sizes={[0.5, 0.5]} className="resizable">
      <Resizable.Panel initialSize=0.5 minSize=0.2 className="resizable-panel">
        <p>{string("Left panel")}</p>
      </Resizable.Panel>
      <Resizable.Handle className="resizable-handle" ariaLabel="Resize panels" />
      <Resizable.Panel initialSize=0.5 minSize=0.2 className="resizable-panel">
        <p>{string("Right panel")}</p>
      </Resizable.Panel>
    </Resizable.Root>

    <KTabs.Root value={tabValue()} onChange={next => setTabValue(_ => next)} className="k-tabs">
      <KTabs.List className="k-tabs-list">
        <KTabs.Trigger value="first">{string("First")}</KTabs.Trigger>
        <KTabs.Trigger value="second">{string("Second")}</KTabs.Trigger>
        <KTabs.Indicator className="k-tabs-indicator" />
      </KTabs.List>
      <KTabs.Content value="first">{string("First tab content")}</KTabs.Content>
      <KTabs.Content value="second">{string("Second tab content")}</KTabs.Content>
    </KTabs.Root>

    <KDialog.Root open_={dialogOpen()} onOpenChange={next => setDialogOpen(_ => next)}>
      <KDialog.Trigger className="k-dialog-trigger">{string("Open dialog")}</KDialog.Trigger>
      <KDialog.Portal>
        <KDialog.Overlay className="k-dialog-overlay" />
        <KDialog.Content className="k-dialog-content">
          <KDialog.Title>{string("Kobalte Dialog")}</KDialog.Title>
          <KDialog.Description>
            {string("Dialog state follows reactive signal")}
          </KDialog.Description>
          <KDialog.CloseButton className="k-dialog-close">{string("Close")}</KDialog.CloseButton>
        </KDialog.Content>
      </KDialog.Portal>
    </KDialog.Root>

    <KPopover.Root
      open_={popoverOpen()}
      onOpenChange={next => setPopoverOpen(_ => next)}
      modal={false}
      forceMount={true}
      gutter=8
      flip={true}
      shift={true}
      detachedPadding=6
      arrowPadding=4>
      <KPopover.Anchor className="k-popover-anchor">
        <KPopover.Trigger className="k-popover-trigger">{string("Toggle popover")}</KPopover.Trigger>
      </KPopover.Anchor>
      <KPopover.Portal>
        <KPopover.Content className="k-popover-content">
          <KPopover.Arrow className="k-popover-arrow" />
          <KPopover.Title>{string("Kobalte Popover")}</KPopover.Title>
          <KPopover.Description>{string("Popover follows reactive open state")}</KPopover.Description>
          <KPopover.CloseButton className="k-popover-close">{string("Close")}</KPopover.CloseButton>
        </KPopover.Content>
      </KPopover.Portal>
    </KPopover.Root>

    <KAccordion.Root
      value={accordionValue()}
      onChange={next => setAccordionValue(_ => next)}
      collapsible={true}
      className="k-accordion">
      <KAccordion.Item value="item-a" className="k-accordion-item">
        <KAccordion.Header className="k-accordion-header">
          <KAccordion.Trigger className="k-accordion-trigger">{string("Section A")}</KAccordion.Trigger>
        </KAccordion.Header>
        <KAccordion.Content className="k-accordion-content">
          {string("Accordion content A")}
        </KAccordion.Content>
      </KAccordion.Item>
      <KAccordion.Item value="item-b" className="k-accordion-item">
        <KAccordion.Header className="k-accordion-header">
          <KAccordion.Trigger className="k-accordion-trigger">{string("Section B")}</KAccordion.Trigger>
        </KAccordion.Header>
        <KAccordion.Content className="k-accordion-content">
          {string("Accordion content B")}
        </KAccordion.Content>
      </KAccordion.Item>
    </KAccordion.Root>

    <KSelect.Root value={selectValue()} onChange={next => setSelectValue(_ => next)} className="k-select">
      <KSelect.Trigger className="k-select-trigger">
        <KSelect.Value className="k-select-value" />
        <KSelect.Icon className="k-select-icon">{string("v")}</KSelect.Icon>
      </KSelect.Trigger>
      <KSelect.Portal>
        <KSelect.Content className="k-select-content">
          <KSelect.Listbox className="k-select-listbox">
            <KSelect.Item item="apple" className="k-select-item">
              <KSelect.ItemLabel>{string("Apple")}</KSelect.ItemLabel>
              <KSelect.ItemIndicator>{string("*")}</KSelect.ItemIndicator>
            </KSelect.Item>
            <KSelect.Item item="orange" className="k-select-item">
              <KSelect.ItemLabel>{string("Orange")}</KSelect.ItemLabel>
              <KSelect.ItemIndicator>{string("*")}</KSelect.ItemIndicator>
            </KSelect.Item>
          </KSelect.Listbox>
        </KSelect.Content>
      </KSelect.Portal>
    </KSelect.Root>

    {SolidJSX.ppxDefer(() => <p>{string("Deferred count: " ++ count()->Int.toString)}</p>)}

    {@show
    switch maybeParityMessage(count()) {
    | Some(message) => <p>{string(message)}</p>
    | None => <p>{string("No parity message")}</p>
    }}
  </section>
}
