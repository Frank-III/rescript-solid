open Solid

module MatchValue = {
  type cases = dict<unit => element>

  let cases = entries => Dict.fromArray(entries)

  type props<'a> = {
    on: 'a,
    @as("case") case_: cases,
    fallback?: unit => element,
  }

  @module("@solid-primitives/match")
  external make: Jsx.component<props<'a>> = "MatchValue"
}

module MatchTag = {
  type cases<'value> = dict<accessor<'value> => element>

  let cases = entries => Dict.fromArray(entries)

  type props<'value> = {
    on: 'value,
    @as("case") case_: cases<'value>,
    tag?: string,
    partial?: bool,
    fallback?: unit => element,
  }

  @module("@solid-primitives/match")
  external make: Jsx.component<props<'value>> = "MatchTag"
}
