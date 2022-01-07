#!/bin/bash

mkdir -p "$HOME/.local/bin"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

install "$SCRIPT_DIR/elf_lib_fixup.sh" "$HOME/.local/bin"
