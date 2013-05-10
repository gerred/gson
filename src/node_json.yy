%start root
%%

root
    : commands { return $1; }
    ;

commands
    : command { $$ = [$1]; }
    | commands command { $1.push($2); $$ = $1; }
    ;

command
    : ID VALUE terminator  { $$ = [$1, $2] }
    ;

terminator
    : /*empty*/
    | TERMINATOR
    ;