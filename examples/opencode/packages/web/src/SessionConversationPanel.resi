type row = {
  roleLabel: string,
  roleClass: string,
  messageId: string,
  text: string,
}

@jsx.component
let make: (~rows: array<row>) => Solid.element
