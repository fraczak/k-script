# k-script
Non-recurive, one file version of `@fraczak/k`

To be used from javascript. Firstly, build the target `index.js` file by:

    npm run build

Then, in java-script do:

    const { parse } = require("./index.js");
    
    const kTransform = parse("[<.a, 0>, <.b, 0>] PLUS");
    
    kTransform({a:12, b:8});
    // returns 20

