#!/usr/bin/env bash
set -e

flagfile() {
	tr $'\n' ' ' < "$PROJECT_ROOT/$1"
}

executableFileName=$(basename "$PWD")
sourceFiles=( $(find ./ -path ./.\* -prune -o -name "*.cpp" -print) )

clang++ \
	$(flagfile compile_flags.txt) \
	-o "${executableFileName}_clang++" "${sourceFiles[@]}"

g++ \
	$(flagfile compile_flags_g++.txt) \
	-o "${executableFileName}_g++" "${sourceFiles[@]}"
