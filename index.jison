%{

function builtin(fnName, arg) {
  switch (fnName) {
    case "_log!":
      console.error(`_log!: ${JSON.stringify(arg)}`);
      return arg;
    case "GT": {
      const [last,...args] = arg;
      const [ok,_] = args.reduce(([ok,last], x) =>
        [ok && (last > x), x ]
      , [true,last]);
      return ok ? arg : undefined;
    }
    case "EQ": {
      const [last,...args] = arg;
      const [ok,_] = args.reduce(([ok,last], x) =>
        [ok && (last == x), x ]
      , [true,last]);
      return ok ? arg : undefined;
    }
    case "PLUS":
      if (!Array.isArray(arg)) return; 
      return valid(arg.reduce((res, x) => res + x), 0);
    case "TIMES":
      if (!Array.isArray(arg)) return; 
      return valid(arg.reduce((res, x) => res * x), 1);
    case "DIV": {
      if (!Array.isArray(arg)) return; 
      if (arg.length !== 2)
        return undefined;
      const [x,y] = arg; 
      const div = ~~(x / y);
      let rem = x % y;
      if (rem < 0) rem = y + rem;
      if (x === div * y + rem)
        return {div,rem}
      return undefined;
    }
    case "FDIV": {
      if (!Array.isArray(arg)) return; 
      if (arg.length !== 2) return;
      const [x,y] = arg; 
      return valid(x / y);
    }
    case "CONCAT": 
      if (!Array.isArray(arg)) return; 
      return arg.join('');
    case "true": return true;
    case "false": return false;
    case "null": return null;
    case "toJSON": return JSON.stringify(arg);
    case "fromJSON": 
      try { return JSON.parse(arg); } catch(err) {
        return;
      }
    case "CONS": {
      if (!Array.isArray(arg)) return; 
      if (arg.length !== 2) return;
      const [x,y] = arg;
      return [x,...y];
    }
    case "SNOC": {
      if (!Array.isArray(arg)) return; 
      return (arg.length > 1) ? [arg[0],arg.slice(1)] : undefined;
    }
    case "toDateMsec": return new Date(arg).getTime();
    case "toDateStr": return new Date(arg).toISOString();
  }
}

const identity = {op: "identity"};

function is_identity_rel(rel) {
  return (rel.op === "identity");
}

function is_empty_rel(rel) {
  return (rel.op === "union" && rel.union.length === 0);
}
  
function is_full_rel(rel) {
  switch (rel.op) {
    case "int":
    case "str":
    case "identity":
      return true;
    case "comp":
      return rel.comp.every(is_full_rel);
    case "product":
    case "vector":
      return Object.values(rel[rel.op]).every(is_full_rel);
  };
  return false;
}

function comp(e1, e2) {
  if (is_identity_rel(e1)) return e2; 
  if (is_identity_rel(e2)) return e1; 
  if (is_empty_rel(e1)) return e1; 
  if (is_empty_rel(e2)) return e2; 
  if (e1.op === "comp" && e2.op === "comp")
    return {op: "comp", comp: [].concat(e1.comp,e2.comp)};
  if (e1.op === "comp")
    return {op: "comp", comp: [].concat(e1.comp,[e2])};
  if (e2.op === "comp")
    return {op: "comp", comp: [].concat([e1],e2.comp)};
  return {op: "comp", comp: [e1,e2]};
}

function union(rels) {
  const list = [];
  block: {
    for(const rel of rels) {
      for(const x of (rel.op === "union") ? rel.union : [rel]) {
        list.push(x);
        if (is_full_rel(x)) break block;
      }
    }
  }
  if (list.length === 1) return list[0];
  return {op: "union", union: list};
}
    
function valid(x) {
  if (isNaN(x)) 
    return undefined
  return x;
}

function run(expr, value) {
  "use strict"
  if (value === undefined)
    return undefined; 
  switch (expr.op) {
    case "ref": return builtin(expr.ref, value); 
    case "identity": return value;
    case "str":
    case "int":
      return expr[expr.op];
    case "dot":
      return value[expr.dot]
    case "comp":
      return expr.comp.reduce((value, exp) =>
        (value === undefined) ? value : run(exp, value)
      , value);
    case "union":
      for(const e of expr.union) {
        const result = run(e, value);
        if (result !== undefined)
          return result;
      } 
      return undefined;
    case "vector": {
      const result = []
      for(const e of expr.vector) {
        const r = run(e, value);
        if (r === undefined)
          return undefined; 
        result.push(r);
      }
      return result;
    }
    case "product": {
      const result = {};
      for(const {label,exp} of expr.product) {
        const r = run(exp, value);
        if (r === undefined)
          return undefined; 
        result[label] = r;
      }
      return result;
    }
    default:  
      throw new Error(`Unknown operation: ${expr}`);
  }
}

%}

%lex

%%
[/][*]([*][^/]|[^*])*[*][/]                    /* c-comment */
("//"|"#"|"%"|"--")[^\n]*                      /* one line comment */
\s+                                            /* blanks */
"<"                                            return 'LA';
"{"                                            return 'LC';
"["                                            return 'LB';
"("                                            return 'LP';
">"                                            return 'RA';
"}"                                            return 'RC';
"]"                                            return 'RB';
")"                                            return 'RP';
"."                                            return 'DOT';
","                                            return 'COMMA';
";"                                            return 'SC';
":"                                            return 'COL';
\"[^\"\n]*\"|\'[^\'\n]*\'                      return 'STRING'
[a-zA-Z_][a-zA-Z0-9_?!]*                       return 'NAME';
0|[-]?[1-9][0-9]*                              return 'INT';
<<EOF>>                                        return 'EOF';

/lex

%token NAME STRING INT
%token LA LC LB LP RA RP RB RC DOT COMMA SC COL
%token EOF

%start input_with_eof

%%

name: NAME                              { $$ = String(yytext); };
str: STRING                             { $$ = String(yytext).slice(1,-1); };
int: INT                                { $$ = parseInt(String(yytext)); };

input_with_eof: comp EOF               {
    const exp = $1;
    return run.bind(null,exp);
};

comp 
    : exp                               { $$ = $1; }
    | comp exp                          { $$ = comp($1, $2); }
    ;

exp
    : LC labelled RC                    { $$ = $2; }
    | LB list RB                        { $$ = {op: "vector", vector: $2}; }
    | LA list RA                        { $$ = union($2); }
    | name                              { $$ = {op: "ref", ref: $1}; }
    | LP RP                             { $$ = identity;  }
    | LP comp RP                        { $$ = $2;  }
    | str                               { $$ = {op: "str", str: $1}; }
    | int                               { $$ = {op: "int", int: $1}; }
    | DOT int                           { $$ = {op: "dot", dot: $2}; }
    | DOT str                           { $$ = {op: "dot", dot: $2}; }
    | DOT name                          { $$ = {op: "dot", dot: $2}; }
    ;

labelled
    :                                   { $$ = {op: "product", product: []}; }
    | non_empty_labelled                { $$ = $1; }
    ;

non_empty_labelled
    : comp_label
        { $$ = {op: "product", product: [$1]}; }
    | non_empty_labelled COMMA comp_label
        { $1.product = [].concat($1.product,$3); $$ = $1; }
    ;

comp_label
    : comp name  { $$ = {label: $2, exp: $1}; }
    | comp str   { $$ = {label: $2, exp: $1}; }
    | name COL comp { $$ = {label: $1, exp: $3}; }
    | str COL comp { $$ = {label: $1, exp: $3}; }
    ;

list
    : /*empty */             { $$ = []; }
    | non_empty_list         { $$ = $1; }
    ;

non_empty_list
    : comp                              { $$ = [$1]; }
    | non_empty_list COMMA comp  { $$ = [].concat($1,$3); }
    ;

%%
