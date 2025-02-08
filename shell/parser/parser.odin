package parser

import "core:mem"

Parser :: struct {
    nodes: [dynamic]Node,
    tokens: []Token,
    alloc: mem.Allocator,
    current: int,
}

parser_init :: proc(toks: []Token, alloc := context.temp_allocator) -> Parser {
    return Parser {
        tokens = toks,
        alloc = alloc,
        nodes = make([dynamic]Node, alloc)
    }
}

parser_destroy :: proc(p: ^Parser) {
    delete(p.nodes)
}

parse :: proc(p: ^Parser) -> []Node {
    return p.nodes[:]
}

parser_at_end :: proc(p: ^Parser) -> bool {
    return p.current >= len(p.tokens)
}
