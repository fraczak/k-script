const { parse } = require("./index.js");
const kTransform = parse("[<.a, 0>, <.b, 0>] PLUS");

console.log(kTransform({a:12, b:8}));

console.log(parse("_log! {() input, toDateMsec msec,toDateStr str}")("Sat Apr 15 12:40:55 PM EDT 2023"));