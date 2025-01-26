package lush

import "core:fmt"
import "core:strings"
import "core:mem"

main :: proc() {
    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                for _, entry in track.allocation_map {
                    fmt.eprintfln("%v leaked %v bytes", entry.location, entry.size)
                }
            }

            if len(track.bad_free_array) > 0 {
                for entry in track.bad_free_array {
                    fmt.eprintfln("%v bad free at %v", entry.location, entry.memory)
                }
            }

            mem.tracking_allocator_destroy(&track)
        }
    }

    shell_init()
    defer shell_close()


    raw_line: string
    main: for {
        shell_prompt()
        raw_line = read_line()

        switch raw_line {
        case "": continue
        case "exit": break main
        case "test": fmt.print("foo\r\n")
        case "dump_stack": lua_dump_stack(shell.lua_state)
        case "dump_globals": lua_dump_globals(shell.lua_state)
        }

        if raw_line[0] == ':' {
            lua_src := strings.clone_to_cstring(string(raw_line[1:]))
            lua_eval(lua_src)
            delete(lua_src)
        }
    }
}
