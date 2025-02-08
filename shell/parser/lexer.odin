package parser

import "core:mem"
import "core:unicode/utf8"
import "core:unicode"

Lexer :: struct {
    input: []rune,
    start, current: int,
    alloc: mem.Allocator,
    toks: [dynamic]Token,
}

lexer_init :: proc(input: string, alloc := context.temp_allocator) -> Lexer {
    return Lexer {
        input = utf8.string_to_runes(input, alloc),
        alloc = alloc,
        toks = make([dynamic]Token, alloc),
    }
}

lexer_destroy :: proc(l: ^Lexer) {
    delete(l.toks)
}

tokenize :: proc(l: ^Lexer) -> []Token {
    terminators := bit_set[0..=' ']{0, ' ', '\n'}
    for !lexer_at_end(l) {
        l.start = l.current

        ch := lexer_advance(l)
        switch ch {
        case 0: lexer_add_token(l, .EOF)
        case '\n', '\r': break
        case '\t', ' ': continue
        case '|': lexer_add_token(l, .Pipe)
        case '<':
            if lexer_match(l, '<') { // <<
                lexer_add_token(l, .TruncLeft)
            } else {
                lexer_add_token(l, .RedirLeft)
            }

        case '>':
            if lexer_match(l, '>') { // >>
                lexer_add_token(l, .TruncRight)
            } else {
                lexer_add_token(l, .RedirRight)
            }

        case '-':
            for !lexer_match(l, ' ') && !lexer_match(l, '\n') {
                lexer_advance(l)
            }
            lexer_add_token(l, .Word)

        case '$':
            if lexer_match(l, '(') {
                l.start = l.current
                for lexer_peek(l) != ')' {
                    lexer_advance(l)
                }
                lexer_add_token(l, .Substitution)
                lexer_advance(l)
            } else {
                l.start += 1 // discard $
                for !(lexer_peek(l) in terminators) {
                    lexer_advance(l)
                }
                lexer_add_token(l, .Variable)
            }

        case '\'':
            l.start = l.current
            lexer_advance(l)
            for lexer_peek(l) != '\'' {
                lexer_advance(l)
            }
            lexer_add_token(l, .String)
            lexer_advance(l)

        case '"':
            l.start = l.current
            lexer_advance(l)
            for lexer_peek(l) != '"' {
                lexer_advance(l)
            }
            lexer_add_token(l, .String)
            lexer_advance(l)

        case '0'..='9':
            for unicode.is_digit(lexer_peek(l)) {
                lexer_advance(l)
            }
            lexer_add_token(l, .Number)

        case 'a'..='z', 'A'..='Z':
            for !(lexer_peek(l) in terminators) {
                lexer_advance(l)
            }

            if kw, ok := Keywords[lexer_get_string(l)]; ok {
                lexer_add_token(l, kw)
            } else {
                lexer_add_token(l, .Word)
            }
        }
    }

    return l.toks[:]
}

lexer_at_end :: proc(l: ^Lexer) -> bool {
    return l.current >= len(l.input)
}

lexer_advance :: proc(l: ^Lexer) -> rune {
    if lexer_at_end(l) {
        return 0
    }

    defer l.current += 1
    return l.input[l.current]
}

lexer_peek :: proc(l: ^Lexer) -> rune {
    if lexer_at_end(l) {
        return 0
    }
    return l.input[l.current]
}

lexer_look_ahead :: proc(l: ^Lexer, n := 1) -> rune {
    if l.current + n >= len(l.input) {
        return 0
    }

    return l.input[l.current + n]
}

lexer_match :: proc(l: ^Lexer, expected: rune) -> bool {
    if lexer_at_end(l) {
        return false
    }

    if lexer_peek(l) != expected {
        return false
    }

    l.current += 1
    return true
}

lexer_get_string :: proc(l: ^Lexer) -> string {
    str := utf8.runes_to_string(l.input[l.start:l.current], l.alloc)
    return str
}

lexer_add_token :: proc(l: ^Lexer, type: TokenType) {
    text := utf8.runes_to_string(l.input[l.start:l.current], l.alloc)
    append(&l.toks, Token {type, text})
}

