- You use the latest ReScript v12 RC.
- Ensure suggestions match this version. Refer to the indexed ReScript manual.
- Ensure any produced JSX matches the ReScript JSX syntax.
- Never ever use the `Belt` or `Js` modules, these are legacy.
- Always use the `JSON.t` type for json.
- Module with React components do require a signature file (`.resi`) for Vite HMR to work.
  Only the React components can be exposed from the javascript.
- In ReScript you cannot add text as child of a react component directly.
  `<h1 className="text-4xl font-bold mb-4">404 - Page Not Found</h1>` is wrong. The parser does not accept this.
  It should be `<h1 className="text-4xl font-bold mb-4">{React.string("404 - Page Not Found")}</h1>`.
  Everything should be a `React.element` in ReScript. So you need to use primitive conversion functions like `React.string`, `React.int`, `React.float` & `React.array`.
- When dealing with promises, prefer using `async/await` syntax.
- `React.useState` in ReScript takes a function when invoked. `let (age, setAge) = React.useState(_ => 4)`
- Every expression inside an interpolated string is expected to be of type string. You can't do `\`age = ${42}\``.
  You need to convert that number to a string. `\`age = ${(42)->Int.toString}\``
- In ReScript `type` is a keyword, so it can't be used a prop name in a JSX prop. Use `type_` if you need it. For example `<button type_="Submit"></button>`
