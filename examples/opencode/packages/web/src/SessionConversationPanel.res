open Solid

module For = SolidJSX.For

type row = {
  roleLabel: string,
  roleClass: string,
  messageId: string,
  text: string,
}

@jsx.component
let make = (~rows: array<row>) =>
  <section className="sessionConversationPanel">
    <header className="chatMetaRow">
      <p className="sessionRoute">{string("Timeline")}</p>
      <span className="terminalPartMeta">{string("Session events and assistant turns")}</span>
    </header>
    <div className="sessionChatPanel">
      {@show switch rows->Array.length > 0 {
      | true =>
        <ul className="chatList">
          <For each_={rows} fallback_={<li className="loadingText">{string("No timeline entries yet")}</li>}>
            {(row, _index) =>
              <li className={`chatRow ${row.roleClass}`}>
                <div className="chatMetaRow">
                  <span className="chatRole">{string(row.roleLabel)}</span>
                  <span className="terminalPartMeta">{string(row.messageId)}</span>
                </div>
                <pre className="chatBubbleText">{string(row.text)}</pre>
              </li>}
          </For>
        </ul>
      | false =>
        <div className="sessionTimelineEmpty">
          <div>
            <p className="loadingText">{string("No messages in this session yet.")}</p>
            <pre className="terminalStub">{string("$ send a prompt to begin the timeline")}</pre>
          </div>
        </div>
      }}
    </div>
  </section>
