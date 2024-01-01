#!/bin/sh

target_directory=$1

if [ "$target_directory" = "" ]; then
	echo "Usage: $0 TARGET_DIRECTORY"
	exit 1
fi

projects=$(ls -d "$target_directory/*/")

for project in $projects; do
	path=$(realpath "$project")
	(
		cd "$path" || exit
		git init
	)
done
