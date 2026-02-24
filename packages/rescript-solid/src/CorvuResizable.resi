open Solid

module Root: {
  type orientation = [#horizontal | #vertical]

  type props = {
    orientation?: orientation,
    sizes?: array<float>,
    @as("onSizesChange") onSizesChange?: array<float> => unit,
    keyboardDelta?: float,
    handleCursorStyle?: bool,
    contextId?: string,
    className?: string,
    children: element,
  }

  @module("@corvu/resizable")
  external make: Jsx.component<props> = "Root"
}

module Panel: {
  type props = {
    initialSize?: float,
    minSize?: float,
    maxSize?: float,
    collapsible?: bool,
    collapsedSize?: float,
    collapseThreshold?: float,
    @as("onResize") onResize?: float => unit,
    @as("onCollapse") onCollapse?: unit => unit,
    @as("onExpand") onExpand?: unit => unit,
    panelId?: string,
    contextId?: string,
    className?: string,
    children: element,
  }

  @module("@corvu/resizable")
  external make: Jsx.component<props> = "Panel"
}

module Handle: {
  type props = {
    startIntersection?: float,
    endIntersection?: float,
    altKey?: bool,
    @as("onHandleDragStart") onHandleDragStart?: unit => unit,
    @as("onHandleDrag") onHandleDrag?: unit => unit,
    @as("onHandleDragEnd") onHandleDragEnd?: unit => unit,
    contextId?: string,
    @as("aria-label") ariaLabel?: string,
    className?: string,
    children?: element,
  }

  @module("@corvu/resizable")
  external make: Jsx.component<props> = "Handle"
}
