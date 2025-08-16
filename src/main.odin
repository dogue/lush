package lush

import "core:fmt"
import "lua"
import editline "../vendor/odin-editline/src"

Shell :: struct {
    lua_state: ^lua.State,
    config: lua.Config,
}

init :: proc() -> (shell: Shell) {
    editline.initialize()
    shell.lua_state = lua.init()

    test_config := `
    config = {
        alias = {
            nv = "nvim",
            cat = "bat",
        },
        hist_size = 1500,
    }`

    lua.eval(shell.lua_state, test_config)
    // TODO: decide config.lua location and eval it here
    shell.config = lua.get_config(shell.lua_state)
    editline.hist_size = shell.config.hist_size

    return shell
}

deinit :: proc(shell: ^Shell) {
    if shell.config.alias != nil {
        delete(shell.config.alias)
    }

    lua.deinit(shell.lua_state)

    // TODO: figure out why this is causing a bad free
    // editline.uninitialize()
}

import "core:strings"

main :: proc() {
    lush := init()
    defer deinit(&lush)

    for raw_line in editline.readline() {
        defer delete(raw_line)

        if strings.has_prefix(raw_line, ":") {
            lua.eval(lush.lua_state, raw_line[1:])
            continue
        }

        // parse and execute
        t := tokenizer_init(raw_line)
        defer tokenizer_deinit(t)

        toks := tokenizer_get_tokens(t)
        for tok in toks {
            fmt.printfln("%v (%s)", tok, t.input[tok.start:tok.end])
        }
    }
}
