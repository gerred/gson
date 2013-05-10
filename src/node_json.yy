%start root
%%

root
    : commands { return $1; }
    ;

commands
    : command { $$ = $1; }
    | commands command { yy.extend($1, $2); $$ = $1; }
    ;

command
    : pair { $$ = $1 }
    | block { $$ = $1 }
    ;

pair
    : ID VALUE terminator { $$ = {}; $$[$1] = $2 }
    ;

block
    : ID INDENT commands OUTDENT terminator { $$ = {}; $$[$1] = $3 }
    ;

terminator
    : /*empty*/
    | TERMINATOR
    ;