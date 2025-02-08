package script

import lua "vendor:lua/5.4"
import "core:fmt"

// for debugging the Lua interop
// provides basic procs for dumping
// the Lua stack and global table

debug_dump_stack :: proc(L: ^LuaState) {
    top := lua.gettop(L)
    fmt.printfln("Stack (%d elements):", top)

    for i := top; i >= 1; i -= 1  {
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

debug_dump_globals :: proc(L: ^LuaState) {
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
