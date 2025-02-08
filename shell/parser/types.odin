#+feature dynamic-literals
package parser

TokenType :: enum {
    Illegal,
    Internal,
    Word,
    String,
    Variable,
    Number,
    Pipe,
    RedirLeft,
    RedirRight,
    TruncLeft,
    TruncRight,
    Substitution,
    Cd,
    EOF,
}

Token :: struct {
    type: TokenType,
    text: string,
}

Keywords := map[string]TokenType {
    "cd" = .Cd,
}

Node :: union {
    SystemCommand,
    ShellCommand,
    Substitution,
    Pipe,
    Argument,
}

SystemCommand :: struct {
    token: Token,
    command: string,
    args: []Argument,
}

ShellCommand :: struct {
    token: Token,
    command: TokenType,
    args: []Argument,
}

Substitution :: struct {
    token: Token,
    subcommand: string,
}

Pipe :: struct {
    token: Token,
    left: ^Node,
    right: ^Node,
}

Argument :: struct {
    token: Token,
    value: ArgValue,
}

ArgValue :: union #no_nil {
    string,
    int,
    f32,
}
