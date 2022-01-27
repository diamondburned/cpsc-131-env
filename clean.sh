#!/usr/bin/env bash
set -e

for exec in $(find ./ -path ./.\* -prune -o -print -executable); {
	[[ $exec == *"_clang++" || $exec == *"_g++" ]] && {
		rm $exec
	}
}
