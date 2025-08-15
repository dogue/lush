package lush_lua

import "core:c"
import "core:strings"
import lua "vendor:lua/5.4"

State :: lua.State

Config :: struct {
    alias: map[string]string,
    hist_size: c.int
}

@(private)
Lua_Func :: #type proc "c" (L: ^State) -> c.int

register_func :: proc(L: ^State, name: cstring, func: Lua_Func) {
    lua.pushcfunction(L, func)
    lua.setfield(L, -2, name)
}

init :: proc() -> ^State {
    L := lua.L_newstate()
    lua.L_openlibs(L)
    lua.createtable(L, 0, 0)

    // register shell-provided functions
    // see `funcs.odin`
    register_func(L, "get_term_size", func_get_term_size)

    // place shell functions/vars under a global `lush` table
    lua.setglobal(L, "lush")
    return L
}

deinit :: proc(L: ^State) {
    lua.close(L)
}

// execute a string as Lua
eval :: proc(L: ^State, line: string) -> c.int {
    cstr := strings.clone_to_cstring(line)
    defer delete(cstr)
    return lua.L_dostring(L, cstr)
}

get_config :: proc(L: ^State) -> (cfg: Config) {
    cfg.hist_size = 1000

    lua.getglobal(L, "config")
    if !lua.istable(L, -1) {
        lua.pop(L, 1)
        return cfg
    }

    cfg.alias = get_alias_map(L, -1)

    lua.getfield(L, -1, "hist_size")
    if lua.isinteger(L, -1) {
        cfg.hist_size = c.int(lua.tointeger(L, -1))
    }
    lua.pop(L, 1)
    lua.pop(L, 1)

    return cfg
}

// retrieve configured aliases from the Lua environment
get_alias_map :: proc(L: ^State, idx: c.int) -> (alias_map: map[string]string) {
    alias_map = make(map[string]string)

    stable_idx := lua.absindex(L, idx)

    lua.getfield(L, stable_idx, "alias")
    if !lua.istable(L, -1) {
        lua.pop(L, 1)
        delete(alias_map)
        return nil
    }

    lua.pushnil(L)
    for lua.next(L, -2) != 0 {
        key := lua.tostring(L, -2)
        val := lua.tostring(L, -1)
        if key != nil && val != nil {
            alias_map[string(key)] = string(val)
        }
        lua.pop(L, 1)
    }
    lua.pop(L, 1)

    return alias_map
}

// retrieve configured history max length
get_hist_size :: proc(L: ^State) -> (hist_size: c.int) {
    lua.getglobal(L, "hist_size")
    if !lua.isnumber(L, -1) {
        return 15 // editline default value
    }

    hist_size = c.int(lua.tointeger(L, -1))
    lua.pop(L, 1)
    return hist_size
}
