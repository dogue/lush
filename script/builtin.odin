package script

import lua "vendor:lua/5.4"
import "core:c"
import "base:runtime"
import "core:os"
import "core:strings"
import raw_term "../ansi_term/raw_mode"

// proc type to be registered in Lua under the `lush` global table
LuaFunc :: proc "c" (^LuaState) -> c.int

scriptf_get_term_size :: proc "c" (L: ^LuaState) -> c.int {
    context = runtime.default_context()
    rows, cols, _ := raw_term.get_term_size()
    lua.pushnumber(L, lua.Number(cols))
    lua.pushnumber(L, lua.Number(rows))
    return 2
}
