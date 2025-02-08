#+private = "file"
package parser

import "core:testing"
import vmem "core:mem/virtual"

ta: vmem.Arena
tt :: TokenType
alloc :: vmem.arena_allocator

@(test)
test_tokenize_words :: proc(t: ^testing.T) {
    input := `foo bar baz`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 3)
    testing.expect_value(t, toks[0].type, tt.Word)
    testing.expect_value(t, toks[0].text, "foo")
    testing.expect_value(t, toks[1].type, tt.Word)
    testing.expect_value(t, toks[1].text, "bar")
    testing.expect_value(t, toks[2].type, tt.Word)
    testing.expect_value(t, toks[2].text, "baz")
}

@(test)
test_tokenize_vars :: proc(t: ^testing.T) {
    input := `$FOO $BAR`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 2)
    testing.expect_value(t, toks[0].type, tt.Variable)
    testing.expect_value(t, toks[0].text, "FOO")
    testing.expect_value(t, toks[1].type, tt.Variable)
    testing.expect_value(t, toks[1].text, "BAR")
}

@(test)
test_tokenize_pipe :: proc(t: ^testing.T) {
    input := `foo | bar`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 3)
    testing.expect_value(t, toks[0].type, tt.Word)
    testing.expect_value(t, toks[1].type, tt.Pipe)
    testing.expect_value(t, toks[1].text, "|")
    testing.expect_value(t, toks[2].type, tt.Word)
}

@(test)
test_tokenize_redirect :: proc(t: ^testing.T) {
    input := `foo > bar < baz`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 5)
    testing.expect_value(t, toks[0].type, tt.Word)
    testing.expect_value(t, toks[1].type, tt.RedirRight)
    testing.expect_value(t, toks[1].text, ">")
    testing.expect_value(t, toks[2].type, tt.Word)
    testing.expect_value(t, toks[3].type, tt.RedirLeft)
    testing.expect_value(t, toks[3].text, "<")
    testing.expect_value(t, toks[4].type, tt.Word)
}

@(test)
test_tokenize_trunc :: proc(t: ^testing.T) {
    input := `foo >> bar << baz`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 5)
    testing.expect_value(t, toks[0].type, tt.Word)
    testing.expect_value(t, toks[1].type, tt.TruncRight)
    testing.expect_value(t, toks[1].text, ">>")
    testing.expect_value(t, toks[2].type, tt.Word)
    testing.expect_value(t, toks[3].type, tt.TruncLeft)
    testing.expect_value(t, toks[3].text, "<<")
    testing.expect_value(t, toks[4].type, tt.Word)
}

@(test)
test_tokenize_single_quote :: proc(t: ^testing.T) {
    input := `'foo bar'`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 1)
    testing.expect_value(t, toks[0].type, tt.String)
    testing.expect_value(t, toks[0].text, "foo bar")
}

@(test)
test_tokenize_double_quote :: proc(t: ^testing.T) {
    input := `"foo bar"`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 1)
    testing.expect_value(t, toks[0].type, tt.String)
    testing.expect_value(t, toks[0].text, "foo bar")
}

@(test)
test_tokenize_number :: proc(t: ^testing.T) {
    input := `1234 5678`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 2)
    testing.expect_value(t, toks[0].type, tt.Number)
    testing.expect_value(t, toks[0].text, "1234")
    testing.expect_value(t, toks[1].type, tt.Number)
    testing.expect_value(t, toks[1].text, "5678")
}

@(test)
test_tokenize_substitution :: proc(t: ^testing.T) {
    input := `$(foo)`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 1)
    testing.expect_value(t, toks[0].type, tt.Substitution)
    testing.expect_value(t, toks[0].text, "foo")
}

@(test)
test_tokenize_keywords :: proc(t: ^testing.T) {
    input := `cd foo`
    l := lexer_init(input, alloc(&ta))
    toks := tokenize(&l)

    testing.expect_value(t, len(toks), 2)
    testing.expect_value(t, toks[0].type, tt.Cd)
    testing.expect_value(t, toks[0].text, "cd")
    testing.expect_value(t, toks[1].type, tt.Word)
    testing.expect_value(t, toks[1].text, "foo")
}
