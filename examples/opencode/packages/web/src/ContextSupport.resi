open Solid

type providerProps<'a> = {
  value: 'a,
  children: element,
}

let provider: context<'a> => component<providerProps<'a>>
