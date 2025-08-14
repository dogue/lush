#!/usr/bin/env bash

PROJECT_DIR=$(pwd)
EDITLINE_LIB_PATH="vendor/editline/src/.libs/libeditline.a"

# Build editline if necessary
if [ ! -f "$PROJECT_DIR/$EDITLINE_LIB_PATH" ]; then
    cd ./vendor/editline
    make clean
    ./autogen.sh
    ./configure --enable-static --disable-shared
    make
    cd $PROJECT_DIR
fi

# Build lush
odin build src -define:EDITLINE_PATH="../../../$EDITLINE_LIB_PATH" -out:lush
