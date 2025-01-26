package lush

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:path/filepath"
import "core:os"
import "core:strings"
import "core:sys/posix"
import "core:mem"
import vmem "core:mem/virtual"

import term "ansi_term"
import "termios"

Shell :: struct {
    stdin: io.Reader,
    stdout: io.Writer,
    stderr: io.Writer,
    cwd: string,
    lua_state: ^LuaState,
    allocator: mem.Allocator,
    arena: vmem.Arena,
    inital_term_state: termios.Termios,
    builder: strings.Builder,
}

shell: Shell

shell_init :: proc() {
    shell.allocator = vmem.arena_allocator(&shell.arena)
    shell.stdin = os.stream_from_handle(os.stdin)
    shell.stdout = os.stream_from_handle(os.stdout)
    shell.stderr = os.stream_from_handle(os.stderr)
    shell.cwd = os.get_current_directory(shell.allocator)
    shell.lua_state = lua_init()

    strings.builder_init(&shell.builder, shell.allocator)

    termios.tcgetattr(0, &shell.inital_term_state)
    raw_mode_state := shell.inital_term_state

    termios.cfmakeraw(&raw_mode_state)

    raw_mode_state.c_oflag |= termios.OF_ONLCR | termios.OF_OPOST // map NL -> CRNL on output
    termios.tcsetattr(0, termios.TCSANOW, &raw_mode_state)
}

shell_close :: proc() {
    termios.tcsetattr(0, termios.TCSANOW, &shell.inital_term_state)
}

// checks for and performs internal shell operations
// returns true if matched so further processing can be skipped
shell_match :: proc(line: string) -> bool {
    switch line {
    case "^L":
        term.erase_screen()
        term.cursor_move_to(1, 1)
    }

    return false
}

shell_prompt :: proc(prompt := "lush # ") {
    fmt.print(prompt)
}

