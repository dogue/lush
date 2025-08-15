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

    lua.eval(shell.lua_state, `config = { alias = { nv = "nvim", cat = "bat" }}`)
    // TODO: decide config.lua location and eval it here
    shell.config = lua.get_config(shell.lua_state)
    editline.hist_size = shell.config.hist_size
    // editline.hist_size = lua.get_hist_size(shell.lua_state)

    return shell
}

deinit :: proc(shell: ^Shell) {
    if shell.config.alias != nil {
        delete(shell.config.alias)
    }

    lua.deinit(shell.lua_state)

    // this causes a bad free ???
    // editline.uninitialize()
}

main :: proc() {
    lush := init()
    defer deinit(&lush)

    fmt.printfln("aliases: %v", lush.config.alias)
    fmt.printfln("hist_size: %d", editline.hist_size)
}
