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
    : ID ':' VALUE terminator  { $$ = [$1, $3] }
    ;

terminator
    : /*empty*/
    | TERMINATOR
    ;