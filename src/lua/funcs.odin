// shell-provided functions for the Lua environment

#+private
package lush_lua

import "core:c"
import "base:runtime"
import "../../ansi_term/raw_mode"
import lua "vendor:lua/5.4"

// returns the terminal size in (cols, rows) order
func_get_term_size :: proc "c" (L: ^State) -> c.int {
    context = runtime.default_context()
    rows, cols, _ := raw_mode.get_term_size()
    lua.pushnumber(L, lua.Number(cols))
    lua.pushnumber(L, lua.Number(rows))
    return 2
}
