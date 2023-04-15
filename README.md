# k-script
Non-recurive, one file version of `@fraczak/k`

To be used from javascript. Firstly, build the target `index.js` and
`index.mjs` files by running:

    npm run build-all

Then, in java-script do:

    const { parse } = require("./index.js");
    // or
    // import { parse } from "./index.mjs";
    
    const kTransform = parse("[<.a, 0>, <.b, 0>] PLUS");
    kTransform({a:12, b:8});
    // returns 20
