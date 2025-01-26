package lush

import "core:io"
import "core:fmt"
import "core:sys/linux"
import "core:os"
import "core:strings"
import term "ansi_term"

byte_available :: proc() -> bool {
    poll_fd := linux.Poll_Fd {
        fd = linux.STDIN_FILENO,
        events = {.IN},
    }

    timeout := linux.Time_Spec {
        time_sec = 0,
        time_nsec = 0,
    }

    ready, _ := linux.ppoll({poll_fd}, &timeout, nil)

    return ready > 0
}

read_key :: proc() -> Key {
    // buffer used for capturing ANSI escape codes
    // size of 16 bytes was chosen by carefully
    // considering that it's probably enough
    buf: [16]byte

    buf[0], _ = io.read_byte(shell.stdin)
    // fmt.printf("RAW KEY: %x\n", buf[0])
    switch buf[0] {
    case 0x1b:    // escape
        if !byte_available() do return EscapeKey{}

        i := 0
        for byte_available() {
            if i >= len(buf) do break
            buf[i], _ = io.read_byte(shell.stdin)
            i += 1
        }

        fmt.fprintf(os.stdout, "ANSI CODE: %q\n", string(buf[:]))
        // return EOF{}

    case '0': return EOF{}
    case 0x4: return EOT{}
    case 0x7F: return ControlChar.Backspace
    case 0xD: return ControlChar.Return
    case 0xC: return ShortcutKey.Clear
    case: return AlphaNumKey{ buf[0] }
    }

    return nil
}

read_line :: proc() -> string {
    strings.builder_reset(&shell.builder)

    read: for {
        key := read_key()

        switch t in key {
        case AlphaNumKey:
            fmt.printf("%c", t.key)
            strings.write_byte(&shell.builder, t.key)
        case EscapeKey:
        case ShortcutKey:
            #partial switch t {
            case .Clear:
                term.erase_screen()
                term.cursor_move_to(1, 1)
                strings.builder_reset(&shell.builder)
                break read
            }
        case ControlChar:
            switch t {
            case .Return:
                term.cursor_return_down_by(1)
                break read
            case .Backspace:
                b := strings.pop_byte(&shell.builder)
                if b > 0 {
                    term.cursor_left_by(1)
                    term.erase_line_from_cursor_to_end()
                }
            }
        case ModKey:
        case EOF: break read
        case EOT: return "exit"
        }
    }

    fmt.println()
    return strings.to_string(shell.builder)
}
