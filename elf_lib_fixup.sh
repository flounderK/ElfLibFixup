#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <elf> <.deb>"
    echo ""
    exit 1
fi
ORIGINAL_DIR=$(pwd)
LIB_DIR="lib"

# extract data.tar.xz
DATA_TARBALL_NAME=$(ar t "$2" | grep --color=never '^data')


ar x "$2" "$DATA_TARBALL_NAME"

# extract lib
tar -xaf "$DATA_TARBALL_NAME" ./$LIB_DIR
rm -f "$DATA_TARBALL_NAME"



readarray -d '' NEEDED_LIBS < <(readelf -dW "$1" | grep --color=never NEEDED | grep --color=never -Po '(?<=\[)[^\]]+(?=\])' | tr '\n' '\0')

for i in "${NEEDED_LIBS[@]}"; do
	# echo "$i"

	readarray -d '' FILES < <(find ./$LIB_DIR -type f -iname $i -print0)
	readarray -d '' LINKS < <(find ./$LIB_DIR -type l -iname $i -print0)
	for k in "${LINKS[@]}"; do
		# echo "$k"
		cp --preserve=links "$k" .
		link_name=$(readlink -f -n $k)
		# echo "$link_name"
		FILES+=($link_name)
	done

	# for k in "${FILES[@]}"; do echo "$k"; done

	if [ ${#FILES[@]} -ge 1 ]; then
		cp --preserve=links ${FILES[0]} .
	fi

done

LINKER_NAME=$(basename $(readelf -lW "$1" | grep --color=never -Po '(?<=\[Requesting program interpreter: )[^\]]+(?=\])'))

echo "expecting linker $LINKER_NAME"

readarray -d '' POSSIBLE_LINKERS < <(find ./$LIB_DIR -type l,f -iname $LINKER_NAME -o -iname 'ld*so*' -print0)
for i in "${POSSIBLE_LINKERS[@]}"; do
	echo "linker candidate $i"
	cp $i .
done

# make the new file that will be modified
cp "$1" "$1.patched"

# if the expected linker isn't present, use whatever was found
if [ ! -f "$LINKER_NAME" ]; then
	echo "Couldn't find expected linker, using first available"
	cp "${POSSIBLE_LINKERS[0]}" "$LINKER_NAME"
fi

patchelf --set-interpreter "$LINKER_NAME" "$1.patched"

rm -rf ./$LIB_DIR

echo ""
echo "created $1.patched"
echo "run with:"
echo "LD_LIBRARY_PATH=. ./$1.patched"
