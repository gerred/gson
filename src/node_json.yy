%lex
%x js
%%

\w+                             { return 'ID'; }
":"                             { this.begin('js'); return ':' }
<js>[a-zA-Z0-9_$]+              { return 'VALUE'; }
<js>[\t ]+                      {}
<js>[\n\;]                      { this.popState(); return 'TERMINATOR'; }
<INITIAL,js><<EOF>>             { return 'EOF'; }
<INITIAL>\n {}
"each"                          {}
"in"                            {}

/lex

%start root
%%

root
    : commands EOF { return $1; }
    ;

commands
    : command { $$ = [$1]; }
    | commands command { $1.push($2); $$ = $1; }
    ;

command
    : ID ':' VALUE terminator { $$ = [$1, $3] }
    ;

terminator
    : /*empty*/
    | TERMINATOR
    ;