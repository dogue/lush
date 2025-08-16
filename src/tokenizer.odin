package lush

import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

Token :: struct {
    start: int,
    end: int,
    kind: Token_Kind,
}

Token_Kind :: enum {
    EOF,
    Word,

    // operators
    Less_Than    = '<',
    Greater_Than = '>',
    Pipe         = '|',
    Colon        = ':',
    Semicolon    = ';',
    Left_Paren   = '(',
    Right_Paren  = ')',
}

Tokenizer :: struct {
    input: []rune,
    index: int,
    next: int,
    char: rune,
}

tokenizer_init :: proc(input: string) -> ^Tokenizer {
    t := new(Tokenizer)
    t.input = utf8.string_to_runes(input)
    tokenizer_advance(t)
    return t
}

tokenizer_deinit :: proc(t: ^Tokenizer) {
    if t.input != nil {
        delete(t.input)
    }
    free(t)
}

// The slice returned must be freed by the caller
tokenizer_get_tokens :: proc(t: ^Tokenizer) -> []Token {
    toks := make([dynamic]Token)

    for {
        tok := tokenizer_next_token(t)
        if tok.kind == .EOF do break
        append(&toks, tok)
    }

    return toks[:]
}

@(private = "file")
tokenizer_next_token :: proc(t: ^Tokenizer) -> (token: Token) {
    tokenizer_skip_space(t)
    token.start = t.index
    token.end = t.next

    if t.char == 0 {
        token.kind = .EOF
        return token
    }

    if is_operator(t.char) {
        token.kind = Token_Kind(t.char)
        tokenizer_advance(t)
        return token
    }

    token.start, token.end = tokenizer_extract_word(t)
    token.kind = .Word
    return token
}

@(private = "file")
tokenizer_advance :: proc(t: ^Tokenizer) -> (did_advance: bool) {
    if t.next >= len(t.input) {
        t.char = 0
        did_advance = false
    } else {
        t.index = t.next
        t.next += 1
        t.char = t.input[t.index]
        did_advance = true
    }

    return did_advance
}

@(private = "file")
tokenizer_skip_space :: proc(t: ^Tokenizer) {
    for unicode.is_space(t.char) {
        // bail out if EOF is reached
        if !tokenizer_advance(t) do break
    }
}

@(private = "file")
tokenizer_extract_word :: proc(t: ^Tokenizer) -> (start: int, end: int) {
    start = t.index
    end = start
    read: for {
        switch true {
        case is_operator(t.char): break read
        case unicode.is_space(t.char): break read
        }
        if tokenizer_advance(t) {
            end += 1
        } else {
            end += 1
            break read
        }
    }
    return start, end
}

@(private = "file")
is_operator :: proc(ch: rune) -> bool {
    switch ch {
    case '<', '>', '|', ':', ';', '(', ')': return true
    case: return false
    }
}
