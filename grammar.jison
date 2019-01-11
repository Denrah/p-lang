%lex

%{
    var parser = yy.parser;
%}


%%
";"                   return 'SEMICOLON'
\s+                   /* skip whitespace */
"$"[a-zA-Z]+[a-zA-Z0-9]*\b  return 'VARIABLE'
"#"[a-zA-Z]+[a-zA-Z0-9]*\b  return 'CONSTANT'
[0-9]+("."[0-9]+)?\b  return 'NUMBER'
"\""(.*)"\""          return 'STRING'
"'"(.)"'"             return 'CHAR'
"="                   return '='
"-"                   return '-'
"+"                   return '+'
"/"                   return '/'
"÷"                   return '/'
"*"                   return '*'
"^"                   return '^'
"("                   return '('
")"                   return ')'
"["                   return '['
"]"                   return ']'
","                   return ','
"write"               return 'WRITE'
"true"                return 'TRUE'
"false"               return 'FALSE'
"if"                  return 'IF'
":"                   return ':'
"<"                   return '<'
">"                   return '>'
"=="                  return '=='
"endif"               return 'ENDIF'
"while"               return 'WHILE'
"endwhile"            return 'ENDWHILE'
<<EOF>>               return 'EOF'

/lex

%start pgm

%right '='
%left '+' '-'
%left '*' '/'
%right '^'
%left UMINUS

%%

pgm
    : el EOF
        {
            var res = { ast: $1, varTable: yy.parser.getVarTable(), constTable: yy.parser.getConstTable() };
            yy.parser.clearTables();
            return res;
        }
    ;
el
    : stm SEMICOLON
    {
        $$ = [$1];
    }
    | stm SEMICOLON el
    {
        $3.unshift($1);
        $$ = $3;
    }
    ;

stm
    : ifstm
    | loopstm
    | array
    | WRITE '(' e ')'
        {
            $$ = {type: "WRITE", args: [[$3]]};
        }
    | e
        { yy.parser.addResult($1); }
    ;

ifstm
    : IF '(' cmp ')' ':' el ENDIF
        {
            $$ = {type: "IF_EXPR", args: [$3, $6]};
        }
    ;

loopstm
    : WHILE '(' cmp ')' ':' el ENDWHILE
        {
            $$ = {type: "WHILE_EXPR", args: [$3, $6]};
        }
    ;

cmp
    : e '==' e
        {
            $$ = [{type: "EQUALITY", args: [[$1], [$3]]}];
        }
    | e '<' e
        {
            $$ = [{type: "SMALLER", args: [[$1], [$3]]}];
        }
    | e '>' e
        {
            $$ = [{type: "GREATER", args: [[$1], [$3]]}];
        }
    | e
        {
            $$ = [{type: "LOGICAL", args: [[$1]]}];
        }
    ;


array 
    : VARIABLE '=' '[' ArrEl ']'
        {
            var str = String($1);
            str = str.substring(1, str.length);
            $$ = {type: "SET_ARRAY", args: [str, $4]}
        }
    ;

ArrEl
    : e "," ArrEl
        {
            $3.unshift([$1]);
            $$ = $3;
        }
    | e
        {
            $$ = [[$1]];
        }
    ;


e
    : NUMBER
        {
            $$ = {type: "NUMBER", args: [Number(yytext)]};
        }
    | TRUE
        {
            $$ = {type: "TRUE", args: [Boolean(yytext)]};
        }
    | FALSE
        {
            $$ = {type: "FALSE", args: [Boolean(yytext)]};
        }
    | VARIABLE '=' e
        {
            //yy.parser.setVar($1);
            var str = String($1);
            str = str.substring(1, str.length);
            $$ = {type: "SET_VARIABLE", args: [str, [$3]]};
            yy.parser.setVar(str, $3);
        }
    | VARIABLE '[' e ']' '=' e
        {
            //yy.parser.setVar($1);
            var str = String($1);
            str = str.substring(1, str.length);
            $$ = {type: "SET_ARRAY_EL", args: [str, [$3], [$6]]};
            yy.parser.setVar(str, $3);
        }
    | VARIABLE
        {
            var str = String($1);
            str = str.substring(1, str.length);
            $$ = {type: "VARIABLE", args: [str]};
        }
    | VARIABLE '[' e ']'
        {
            var str = String($1);
            str = str.substring(1, str.length);
            $$ = {type: "ARRAY_EL", args: [str, [$3]]};
        }
    | CONSTANT '=' e
        {
            //yy.parser.setConst($1, $3);
            var str = String($1);
            str = str.substring(1, str.length);
            $$ = {type: "SET_CONSTANT", args: [str, [$3]]};
            yy.parser.setConst(str, $3);
        }
    | CONSTANT
        {
            var str = String($1);
            str = str.substring(1, str.length);
            $$ = {type: "CONSTANT", args: [str]};
        }
    | STRING
        {
            var str = String(yytext);
            str = str.substring(1, str.length - 1);
            $$ = str;
        }
    | CHAR
        {
            var str = String(yytext);
            str = str.substring(1, str.length - 1);
            $$ = str;
        }
    | e '+' e
        {
            $$ = {type: "PLUS_EXPR", args: [[$1], [$3]]};
        }
    | e '-' e
        {
            $$ = {type: "MINUS_EXPR", args: [[$1], [$3]]}
        }
    | e '*' e
        {
            $$ = {type: "MULT_EXPR", args: [[$1], [$3]]};
        }
    | e '/' e
        {$$ = $1/$3;}
    | e '^' 'e'
        {$$ = Math.pow($1, $3);}
    | '-' e %prec UMINUS
        {$$ = -$2;}
    | '(' e ')'
        {$$ = ($2);}
    ;

%%

parser.addResult = function(value) {
    if (!this._results) {
        this._results = [];
    }
    this._results.push(value);
}

parser.getResults = function() {
    return this._results;
}

parser.clearResults = function() {
    this._results = [];
}

parser.getVar = function(key) {
    if (!this._varTable) {
        return undefined;
    } else {
        return this._varTable[key];
    }
}

parser.setVar = function(key, val) {
    if (!this._varTable) {
        this._varTable = {};
    }
    this._varTable[key] = 0;
}

parser.getConst = function(key) {
    if (!this._constTable) {
        return undefined;
    } else {
        return this._constTable[key];
    }
}

parser.setConst = function(key, val) {
    if (!this._constTable) {
        this._constTable = {};
    }
    if(this._constTable[key] === undefined)
        this._constTable[key] = 0;
    else
    {
        this._constTable = undefined;
        this._varTable = undefined;
        throw 'Trying to modify constant';
    }
}

parser.getVarTable = function() {
  return this._varTable;
}

parser.getConstTable = function() {
  return this._constTable;
}
parser.clearTables = function() {
    this._constTable = undefined;
    this._varTable = undefined;
}
