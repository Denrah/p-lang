var parser = require('./grammar').parser;
var fs = require('fs');

let _varTable = [];
let _constTable = [];

function parseAst(node) {
  for(let i = 0; i < node.length; i++) {
    switch (node[i].type) {
      case "NUMBER":
        return node[i].args[0];
        break;
      case "PLUS_EXPR":
        return parseAst(node[i].args[0]) + parseAst(node[i].args[1]);
        break;
      case "MINUS_EXPR":
        return parseAst(node[i].args[0]) - parseAst(node[i].args[1]);
        break;
      case "MULT_EXPR":
        return parseAst(node[i].args[0]) * parseAst(node[i].args[1]);
        break;
      case "LOGICAL":
        if(parseAst(node[i].args[0])) {
          return true;
        }
        else {
          return false;
        }
        break;
      case "GREATER":
        if(parseAst(node[i].args[0]) > parseAst(node[i].args[1])) {
          return true;
        }
        else {
          return false;
        }
        break;
      case "SMALLER":
        if(parseAst(node[i].args[0]) < parseAst(node[i].args[1])) {
          return true;
        }
        else {
          return false;
        }
        break;
      case "EQUALITY":
        if(parseAst(node[i].args[0]) == parseAst(node[i].args[1])) {
          return true;
        }
        else {
          return false;
        }
        break;
      case "SET_ARRAY":
        let t = [];
        node[i].args[1].forEach(element => {
          t.push(parseAst(element));
        });
        _varTable[node[i].args[0]] = t;
        break;
      case "ARRAY_EL":
        return _varTable[node[i].args[0]][parseAst(node[i].args[1])];
        break;
      case "SET_ARRAY_EL":
        _varTable[node[i].args[0]][parseAst(node[i].args[1])] = parseAst(node[i].args[2]);
        break;
      case "SET_VARIABLE":
        _varTable[node[i].args[0]] = parseAst(node[i].args[1]);
        break;
      case "VARIABLE":
        return _varTable[node[i].args[0]];
        break;
      case "CONSTANT":
        return _constTable[node[i].args[0]];
        break;
      case "SET_CONSTANT":
        _constTable[node[i].args[0]] = parseAst(node[i].args[1]);
        break;
      case "IF_EXPR":
        if(parseAst(node[i].args[0])) {
          parseAst(node[i].args[1]);
        }
        break;
      case "WHILE_EXPR":
        while(parseAst(node[i].args[0])) {
          parseAst(node[i].args[1]);
        }
        break;
      case "WRITE":
        console.log(parseAst(node[i].args[0]));
        break;
      default:
        return 0;
    }
  }
}


function exec(input) {
  return parser.parse(input);
}

fs.readFile("program.p", "utf8", function(err, source) {

  var res = exec(source);
  console.log(JSON.stringify(res));

  _varTable = res.varTable;
  _constTable = res.constTable;
  parseAst(res.ast);

});