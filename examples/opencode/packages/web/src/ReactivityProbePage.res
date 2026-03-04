open Solid

module For = SolidJSX.For

@jsx.component
let make = (
  ~streamEventCount: int,
  ~recentEventCount: int,
  ~trackedMessageCount: int,
  ~trackedPartCount: int,
  ~sessionCount: int,
  ~activeSessionId: option<string>,
) => {
  let (samples, setSamples) = createSignal([0])

  let rec buildChunk = (~size: int, ~next: int, ~acc: array<int>): array<int> =>
    if size <= 0 {
      acc
    } else {
      buildChunk(~size=size - 1, ~next=next + 1, ~acc=Array.concat(acc, [next]))
    }

  let burst = (~size: int) =>
    setSamples(items => {
      let base = items->Array.length
      let nextChunk = buildChunk(~size, ~next=base + 1, ~acc=[])
      Array.concat(items, nextChunk)
    })

  let reverseOrder = () => {
    setSamples(items => items->Array.reduce([], (acc, item) => [item, ...acc]))
  }

  let pruneHalf = () =>
    setSamples(items => {
      let keepNext = ref(true)
      items->Array.filter(_ => {
        let keep = keepNext.contents
        keepNext.contents = !keepNext.contents
        keep
      })
    })

  let clearAll = () => setSamples(_ => [])

  <section className="panel sessionsPanel">
    <h2>{string("Reactivity Probe")}</h2>
    <p className="sessionRoute">
      {string(
        "Stress helper for For/Show update behavior while stream events are flowing through the app.",
      )}
    </p>

    <ul className="summaryList">
      <li>
        <strong>{string("Stream events")}</strong>
        <span>{string(streamEventCount->Int.toString)}</span>
      </li>
      <li>
        <strong>{string("Recent reducer events")}</strong>
        <span>{string(recentEventCount->Int.toString)}</span>
      </li>
      <li>
        <strong>{string("Tracked messages")}</strong>
        <span>{string(trackedMessageCount->Int.toString)}</span>
      </li>
      <li>
        <strong>{string("Tracked parts")}</strong>
        <span>{string(trackedPartCount->Int.toString)}</span>
      </li>
      <li>
        <strong>{string("Sessions in memory")}</strong>
        <span>{string(sessionCount->Int.toString)}</span>
      </li>
      <li>
        <strong>{string("Active session id")}</strong>
        <span>{string(activeSessionId->Option.getOr("none"))}</span>
      </li>
    </ul>

    <div className="queryActions">
      <button className="refreshBtn" onClick={_ => burst(~size=50)}>
        {string("Burst +50")}
      </button>
      <button className="refreshBtn" onClick={_ => burst(~size=200)}>
        {string("Burst +200")}
      </button>
      <button className="ghostBtn" onClick={_ => reverseOrder()}>
        {string("Reverse")}
      </button>
      <button className="ghostBtn" onClick={_ => pruneHalf()}>
        {string("Prune half")}
      </button>
      <button className="ghostBtn" onClick={_ => clearAll()}>
        {string("Clear")}
      </button>
    </div>

    <ul className="eventList">
      <For each_={samples()} fallback_={<li className="eventRow">{string("No local samples")}</li>}>
        {(sample, _index) =>
          <li className="eventRow">
            <span className="eventKind">{string(`sample-${sample->Int.toString}`)}</span>
            <span className="sessionMeta">{string("local reactive row")}</span>
          </li>}
      </For>
    </ul>
  </section>
}
