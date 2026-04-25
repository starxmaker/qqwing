# qqwing-wasm

`qqwing-wasm` packages the QQWing Sudoku generator and solver as an Emscripten WebAssembly module.

This package exposes the compiled module directly. After creating an instance, call `callMain()` with the same arguments you would pass to the QQWing CLI.

## Install

```sh
npm install qqwing-wasm
```

Node `>=18.3.0` is required.

## CommonJS

```js
const createQQWing = require('qqwing-wasm');

createQQWing({
	print: (line) => process.stdout.write(`${line}\n`),
	printErr: (line) => process.stderr.write(`${line}\n`),
}).then((module) => {
	module.callMain(['--generate', '1', '--difficulty', 'expert', '--one-line']);
});
```

## ESM

```js
import createQQWing from 'qqwing-wasm';

const module = await createQQWing({
	print: console.log,
	printErr: console.error,
});

module.callMain(['--generate', '1', '--difficulty', 'expert', '--one-line']);
```

## Notes

- `print` captures standard output.
- `printErr` captures standard error.
- `callMain()` accepts the same flags as the QQWing command-line tool.

## License

Copyright (C) 2006-2014 Stephen Ostermiller

QQWing is licensed under GPL-2.0-or-later. The full license text is included in `LICENSE`.
