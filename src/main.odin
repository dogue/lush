package lush

import "core:fmt"
import el "../vendor/odin-editline/src"

main :: proc() {
	el.hist_size = 20

	el.initialize()
	defer el.uninitialize()

	el.read_history("history.txt")

	for line in el.readline() {
		fmt.printfln("You said: %q", line)

		delete(line)
	}

	el.write_history("history.txt")
}
