package shell

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:path/filepath"
import "core:os"
import "core:strings"
import "core:sys/posix"
import "core:mem"
import vmem "core:mem/virtual"

import term "../ansi_term"
import "../termios"
import "../types"

Shell :: struct {
    stdin: io.Reader,
    stdout: io.Writer,
    stderr: io.Writer,
    arena: vmem.Arena,
    inital_term_state: termios.Termios,
    should_shutdown: bool,
    aliases: map[string]string,
}

init :: proc(/*state: ^lush.LuaState*/) -> Shell {
    shell := Shell {
        stdin = os.stream_from_handle(os.stdin),
        stdout = os.stream_from_handle(os.stdout),
        stderr = os.stream_from_handle(os.stderr),
    }

    _ = vmem.arena_init_static(&shell.arena)
    termios.tcgetattr(0, &shell.inital_term_state)
    raw_mode_state := shell.inital_term_state
    termios.cfmakeraw(&raw_mode_state)
    raw_mode_state.c_oflag |= termios.OF_ONLCR | termios.OF_OPOST // map NL -> CRNL on output
    termios.tcsetattr(0, termios.TCSANOW, &raw_mode_state)

    return shell
}

close :: proc(shell: ^Shell) {
    termios.tcsetattr(0, termios.TCSANOW, &shell.inital_term_state)
    shell.should_shutdown = true
}

// checks for and performs internal shell operations
// returns true if matched so further processing can be skipped
match_builtin :: proc(shell: ^Shell, line: string) -> bool {
    switch line {
    case "": return true
    case "exit":
        close(shell)
    }

    return false
}

prompt :: proc(shell: Shell, prompt := "lush # ") {
    io.write_string(shell.stdout, prompt)
}

