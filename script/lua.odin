package script

import lua "vendor:lua/5.4"
import "core:fmt"
import "core:c"
import "core:strings"
import "base:runtime"
import "core:os"
import raw_term "../ansi_term/raw_mode"

LuaState :: lua.State

init :: proc() -> ^LuaState {
    register_proc :: proc(L: ^LuaState, name: cstring, func: LuaFunc) {
        lua.pushcfunction(L, func)
        lua.setfield(L, -2, name)
    }

    L := lua.L_newstate()
    lua.L_openlibs(L)

    lua.createtable(L, 0, 0)

    // register Lua script funcs provided by the shell
    register_proc(L, "get_term_size", scriptf_get_term_size)

    lua.setglobal(L, "lush")

    return L
}

eval :: proc(L: ^LuaState, line: cstring) -> c.int {
    return lua.L_dostring(L, line)
}

get_aliases :: proc(L: ^LuaState) -> (aliases: map[string]string, ok: bool) {
    aliases = make(map[string]string)

    lua.getglobal(L, "alias")
    if !lua.istable(L, -1) {
        delete(aliases)
        return
    }

    fmt.println("got alias table")

    lua.pushnil(L)
    for lua.next(L, -2) != 0 {
        if key := lua.tostring(L, -2); key != nil {
            if val := lua.tostring(L, -1); val != nil {
                aliases[string(key)] = string(val)
            }
        }
        lua.pop(L, 1)
    }
    lua.pop(L, 1)
    return
}
