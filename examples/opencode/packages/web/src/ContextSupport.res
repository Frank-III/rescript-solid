open Solid

type providerProps<'a> = {
  value: 'a,
  children: element,
}

@get
external provider: context<'a> => component<providerProps<'a>> = "Provider"
