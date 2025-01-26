package lush

import "core:fmt"
import "core:strings"
import "core:mem"
import "core:sys/posix"
import "spawn"

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

        if len(raw_line) > 0 && raw_line[0] == ':' {
            lua_src := strings.clone_to_cstring(string(raw_line[1:]))
            lua_eval(lua_src)
            delete(lua_src)
            continue
        }

        switch raw_line {
        case "": continue
        case "exit": break main
        case "dump_stack": lua_dump_stack(shell.lua_state)
        case "dump_globals": lua_dump_globals(shell.lua_state)
        case:
            parts := split_to_cstring(raw_line)
            defer delete(parts)
            child, err := spawn.spawn(..parts)
            if err != .NONE {
                if err == .ENOENT {
                    fmt.printfln("command not found: %s", parts[0])
                    continue
                }
                fmt.panicf("Failed to fork child process: %v\n", err)
            }
            for child_running(child.pid) {}
        }
    }
}

child_running :: proc(pid: int) -> bool {
    status: i32
    wait := posix.waitpid(posix.pid_t(pid), &status, {})
    if wait == -1 {
        panic("failed to get child process status")
    }

    return !posix.WIFEXITED(status) && !posix.WIFSIGNALED(status)
}

split_to_cstring :: proc(str: string, sep := " ") -> []cstring {
    parts := strings.split(str, sep)
    parts_c := make([]cstring, len(parts))
    for p, i in parts {
        parts_c[i] = strings.clone_to_cstring(p)
    }
    delete(parts)
    return parts_c
}
