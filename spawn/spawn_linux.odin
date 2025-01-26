package spawn

import "core:fmt"
import "core:io"
import "core:sys/posix"
import "core:os"

Process :: struct {
    pid: int,
    stdin:  io.Writer,
    stdout: io.Reader,
    stderr: io.Reader,
}

spawn :: proc(args: ..cstring) -> (process: Process, err: posix.Errno) {
    process.pid = int(posix.fork())
    switch process.pid {
    case -1:
        err = posix.errno()
        return

    case 0:
        nil_term_args := make([]cstring, len(args) + 1)
        copy(nil_term_args, args)

        ret := posix.execvp(nil_term_args[0], raw_data(nil_term_args))
        if ret != 0 {
            errno := posix.errno()
            errstr := posix.strerror(errno)
            fmt.panicf("Child process failed: %v, %v\n", errno, errstr)
        }
    }

    return
}

spawn_piped :: proc(args: ..cstring) -> (process: Process, err: posix.Errno) {
    stdin: [2]posix.FD
    stdout: [2]posix.FD
    stderr: [2]posix.FD

    if posix.pipe(&stdin) != .OK {
        process.pid = -1
        err = posix.errno()
        return
    }

    if posix.pipe(&stdout) != .OK {
        process.pid = -1
        err = posix.errno()
        return
    }

    if posix.pipe(&stderr) != .OK {
        process.pid = -1
        err = posix.errno()
    }

    process.pid = int(posix.fork())
    switch process.pid {
    case -1: // error
        err = posix.errno()
        return

    case 0: // child
        posix.close(stdin[1]) // close write end
        posix.dup2(stdin[0], posix.STDIN_FILENO)

        posix.close(stdout[0]) // close read end
        posix.dup2(stdout[1], posix.STDOUT_FILENO)

        posix.close(stderr[0])
        posix.dup2(stderr[1], posix.STDERR_FILENO)

        nil_term_args := make([]cstring, len(args) + 1)
        copy(nil_term_args, args)

        ret := posix.execvp(nil_term_args[0], raw_data(nil_term_args))
        if ret != 0 {
            errno := posix.errno()
            errstr := posix.strerror(errno)
            fmt.panicf("Child process failed: %v, %v\n", errno, errstr)
        }

    case: // parent
        posix.close(stdin[0])
        process.stdin = os.stream_from_handle(os.Handle(stdin[1]))

        posix.close(stdout[1])
        process.stdout = os.stream_from_handle(os.Handle(stdout[0]))

        posix.close(stderr[1])
        process.stderr = os.stream_from_handle(os.Handle(stderr[0]))
    }

    return
}
