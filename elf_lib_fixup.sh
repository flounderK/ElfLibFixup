#!/bin/bash

# if [ $# -lt 3 ]; then
#     echo "Usage: $0 <elf> <.deb> <output_elf>"
#     echo ""
#     exit 1
# fi
# ORIGINAL_DIR=$(pwd)

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

rm -rf ./lib
