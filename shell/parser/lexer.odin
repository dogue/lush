#+private file
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

@(export)
lexer_init :: proc(input: string, alloc := context.temp_allocator) -> Lexer {
    return Lexer {
        input = utf8.string_to_runes(input, alloc),
        alloc = alloc,
        toks = make([dynamic]Token, alloc),
    }
}

@(export)
lexer_destroy :: proc(l: ^Lexer) {
    delete(l.toks)
}

@(export)
tokenize :: proc(l: ^Lexer) -> []Token {
    terminators := bit_set[0..=' ']{0, ' ', '\n'}
    for !at_end(l) {
        l.start = l.current

        ch := advance(l)
        switch ch {
        case 0: add_token(l, .EOF)
        case '\n', '\r': break
        case '\t', ' ': continue
        case '|': add_token(l, .Pipe)
        case '<':
            if match(l, '<') { // <<
                add_token(l, .TruncLeft)
            } else {
                add_token(l, .RedirLeft)
            }

        case '>':
            if match(l, '>') { // >>
                add_token(l, .TruncRight)
            } else {
                add_token(l, .RedirRight)
            }

        case '-':
            for !match(l, ' ') && !match(l, '\n') {
                advance(l)
            }
            add_token(l, .Word)

        case '$':
            if match(l, '(') {
                l.start = l.current
                for peek(l) != ')' {
                    advance(l)
                }
                add_token(l, .Substitution)
                advance(l)
            } else {
                l.start += 1 // discard $
                for !(peek(l) in terminators) {
                    advance(l)
                }
                add_token(l, .Variable)
            }

        case '\'':
            l.start = l.current
            advance(l)
            for peek(l) != '\'' {
                advance(l)
            }
            add_token(l, .String)
            advance(l)

        case '"':
            l.start = l.current
            advance(l)
            for peek(l) != '"' {
                advance(l)
            }
            add_token(l, .String)
            advance(l)

        case '0'..='9':
            for unicode.is_digit(peek(l)) {
                advance(l)
            }
            add_token(l, .Number)

        case 'a'..='z', 'A'..='Z':
            for !(peek(l) in terminators) {
                advance(l)
            }

            if kw, ok := Keywords[get_string(l)]; ok {
                add_token(l, kw)
            } else {
                add_token(l, .Word)
            }
        }
    }

    return l.toks[:]
}

at_end :: proc(l: ^Lexer) -> bool {
    return l.current >= len(l.input)
}

advance :: proc(l: ^Lexer) -> rune {
    if at_end(l) {
        return 0
    }

    defer l.current += 1
    return l.input[l.current]
}

peek :: proc(l: ^Lexer) -> rune {
    if at_end(l) {
        return 0
    }
    return l.input[l.current]
}

look_ahead :: proc(l: ^Lexer, n := 1) -> rune {
    if l.current + n >= len(l.input) {
        return 0
    }

    return l.input[l.current + n]
}

match :: proc(l: ^Lexer, expected: rune) -> bool {
    if at_end(l) {
        return false
    }

    if peek(l) != expected {
        return false
    }

    l.current += 1
    return true
}

get_string :: proc(l: ^Lexer) -> string {
    str := utf8.runes_to_string(l.input[l.start:l.current], l.alloc)
    return str
}

add_token :: proc(l: ^Lexer, type: TokenType) {
    text := utf8.runes_to_string(l.input[l.start:l.current], l.alloc)
    append(&l.toks, Token {type, text})
}

