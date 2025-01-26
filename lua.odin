package lush

import lua "vendor:lua/5.4"
import "core:fmt"
import "core:c"
import "core:strings"
import "base:runtime"
import raw_term "ansi_term/raw_mode"

LuaState :: lua.State
LuaFunc :: proc "c" (^LuaState) -> c.int

lua_init :: proc() -> ^LuaState {
    L := lua.L_newstate()
    lua.L_openlibs(L)

    lua.createtable(L, 0, 0)

    // register funcs
    lua_register_proc(L, "get_cwd", luaf_get_cwd)
    lua_register_proc(L, "print", luaf_print)
    lua_register_proc(L, "get_term_size", luaf_get_term_size)

    lua.setglobal(L, "lush")

    return L
}

lua_register_proc :: proc(L: ^LuaState, name: cstring, func: LuaFunc) {
    lua.pushcfunction(L, func)
    lua.setfield(L, -2, name)
}

lua_eval :: proc(line: cstring) -> c.int {
    return lua.L_dostring(shell.lua_state, line)
}

luaf_get_cwd :: proc "c" (L: ^LuaState) -> c.int {
    context = runtime.default_context()
    cwd := strings.clone_to_cstring(shell.cwd)
    defer delete(cwd)
    lua.pushstring(L, cwd)
    return 1
}

luaf_print :: proc "c" (L: ^LuaState) -> c.int {
    context = runtime.default_context()

    str: cstring
    if lua.type(L, 1) == .NIL {
        str = "nil"
    } else {
        str = lua.tostring(L, 1)
    }

    fmt.println(str)
    return 0
}

luaf_get_term_size :: proc "c" (L: ^LuaState) -> c.int {
    context = runtime.default_context()
    rows, cols, _ := raw_term.get_term_size()
    lua.pushnumber(L, lua.Number(cols))
    lua.pushnumber(L, lua.Number(rows))
    return 2
}

lua_dump_stack :: proc "odin" (L: ^LuaState) {
    top := lua.gettop(L)
    fmt.printfln("Stack (%d elements):", top)

    for i := top; i >= 1; i -= 1 {
        t := lua.type(L, i)
        #partial switch t {
        case .STRING:
            fmt.printfln("    %d: string: %s", i, lua.tostring(L, i))

        case .NUMBER:
            fmt.printfln("    %d: number: %f", i, lua.tonumber(L, i))

        case .TABLE:
            fmt.printfln("    %d: table", i)

        case .NIL:
            fmt.printfln("    %d: nil", i)

        case:
            fmt.printfln("    %d: %v", i, t)
        }
    }
}

lua_dump_globals :: proc "odin" (L: ^LuaState) {
    fmt.println("\nGlobals:")
    lua.pushglobaltable(L)
    lua.pushnil(L)
    for lua.next(L, -2) != 0 {
        if key := lua.tostring(L, -2); key != nil {
            fmt.printfln("    %s: %v", key, lua.type(L, -1))
        }
        lua.pop(L, 1)
    }
    lua.pop(L, 1)
}
