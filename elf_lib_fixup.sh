#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <elf> <.deb>"
    echo ""
    exit 1
fi
ORIGINAL_DIR=$(pwd)

# extract data.tar.xz
ar x "$2" data.tar.xz

# extract lib
tar -xaf data.tar.xz ./lib
rm -f data.tar.xz



readarray -d '' NEEDED_LIBS < <(readelf -dW "$1" | grep --color=never NEEDED | grep --color=never -Po '(?<=\[)[^\]]+(?=\])' | tr '\n' '\0')

for i in "${NEEDED_LIBS[@]}"; do
	# echo "$i"

	readarray -d '' FILES < <(find ./lib -type f -iname $i -print0)
	readarray -d '' LINKS < <(find ./lib -type l -iname $i -print0)
	for k in "${LINKS[@]}"; do
		echo "$k"
		cp --preserve=links "$k" .
		link_name=$(readlink -f -n $k)
		# echo "$link_name"
		FILES+=($link_name)
	done

	for k in "${FILES[@]}"; do
		echo "$k"
	done

	if [ ${#FILES[@]} -ge 1 ]; then
		cp --preserve=links ${FILES[0]} .
	fi

done

LINKER_NAME=$(basename $(readelf -lW "$1" | grep --color=never -Po '(?<=\[Requesting program interpreter: )[^\]]+(?=\])'))
LINKER=$(find ./lib -type l,f -iname $LINKER_NAME)
cp "$LINKER" "$LINKER_NAME"
cp "$1" "$1.patched"

patchelf --set-interpreter "$LINKER_NAME" "$1.patched"
rm -rf ./lib

echo ""
echo "created $1.patched"
echo "run with:"
echo "LD_LIBRARY_PATH=. ./$1.patched"
