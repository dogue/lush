package lush

Key :: union {
    EscapeKey,
    AlphaNumKey,
    ModKey,
    ShortcutKey,
    ControlChar,
    EOF,
    EOT,
}

EscapeKey :: struct{}

AlphaNumKey :: struct {
    key: byte,
}

ModKey :: struct {
    keys: []byte,
}

ShortcutKey :: enum {
    Clear,
    Interrupt,
}

ControlChar :: enum {
    Backspace,
    Return,
}

EOF :: struct{}
EOT :: struct{}
