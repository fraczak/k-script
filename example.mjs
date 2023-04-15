import { parse } from "./index.mjs";
const kTransform = parse("[<.a, 0>, <.b, 0>] PLUS");

console.log(kTransform({a:12, b:8}));
