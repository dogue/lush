package lush

import "core:fmt"
import "core:strings"
import "core:mem"
import "core:sys/posix"
import "core:os"
import vmem "core:mem/virtual"
import "spawn"
import "shell"
import "script"
import "types"

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

    lua_state := script.init()
    script.eval(lua_state, `alias = { nv = "nvim" }`)
    lush := shell.init()
    defer shell.close(&lush)
    lush.aliases, _ = script.get_aliases(lua_state)
    fmt.printfln("aliases: %v", lush.aliases)
    allocator := vmem.arena_allocator(&lush.arena)

    raw_line: string
    for !lush.should_shutdown {
        tmp := vmem.arena_temp_begin(&lush.arena)
        defer vmem.arena_temp_end(tmp)
        shell.prompt(lush)
        raw_line = shell.read_line(&lush)

        if len(raw_line) > 0 && raw_line[0] == ':' {
            src := strings.clone_to_cstring(string(raw_line[1:]))
            script.eval(lua_state, src)
            delete(src)
            continue
        }

        switch raw_line {
        case "": continue
        case "exit": shell.close(&lush)
        case "dump_stack": script.debug_dump_stack(lua_state)
        case "dump_globals": script.debug_dump_globals(lua_state)
        case:
            if alias, ok := lush.aliases[raw_line]; ok {
                raw_line = alias
            }
            parts := split_to_cstring(raw_line)
            defer delete(parts)

            if parts[0] == "cd" {
                target, alloc := strings.remove(raw_line, "cd ", 1)

                // defer if alloc do delete(target)
                os.set_current_directory(target)
                continue
            }

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
