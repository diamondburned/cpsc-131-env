#!/usr/bin/env bash
set -e

flagfile() {
	tr $'\n' ' ' < "$PROJECT_ROOT/$1"
}

executableFileName=$(basename "$PWD")
readarray -t sourceFiles < <(find ./ -path ./.\* -prune -o -name "*.cpp" -print)

[[ $PROJECT_SYSTEM != *"darwin" ]] &&
	# TODO: check libcxx instead of OS. Linux might be libcxx too.
	clang++ \
		$(flagfile compile_flags.txt) \
		-o "${executableFileName}_clang++" "${sourceFiles[@]}"

g++ \
	$(flagfile compile_flags_g++.txt) \
	-o "${executableFileName}_g++" "${sourceFiles[@]}"
