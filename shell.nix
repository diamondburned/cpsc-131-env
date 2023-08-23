{ systemPkgs ? import <nixpkgs> {} }:

let
	lib  = systemPkgs.lib;
	pkgs = import (systemPkgs.fetchFromGitHub {
			owner  = "NixOS";
			repo   = "nixpkgs";
			rev    = "3c13b0c82eaa9b490132413bb547e1bbf1402b3a";
			sha256 = "sha256-wEIlVlZk5+DNnNjelEGOrUFeG43n+1SeL37MYjvl1Xg=";
		}) {};

	llvmPackages = pkgs.llvmPackages_13;
	clang-unwrapped = llvmPackages.clang-unwrapped;
	clang = llvmPackages.clang;
	# clang = llvmPackages.libstdcxxClang;

	# clangd hack.
	clangd = pkgs.writeScriptBin "clangd" ''
	    #!${pkgs.stdenv.shell}
		export CPATH="$(${clang}/bin/clang -E - -v <<< "" \
			|& ${pkgs.gnugrep}/bin/grep '^ /nix' \
			|  ${pkgs.gawk}/bin/awk 'BEGIN{ORS=":"}{print substr($0, 2)}' \
			|  ${pkgs.gnused}/bin/sed 's/:$//')"
		export CPLUS_INCLUDE_PATH="$(${clang}/bin/clang++ -E - -v <<< "" \
			|& ${pkgs.gnugrep}/bin/grep '^ /nix' \
			|  ${pkgs.gawk}/bin/awk 'BEGIN{ORS=":"}{print substr($0, 2)}' \
			|  ${pkgs.gnused}/bin/sed 's/:$//')"
	    ${clang-unwrapped}/bin/clangd
	'';

	gccShell = pkgs.mkShell.override {
		# Use gcc11 for our shell environment. We don't have a clang13Stdenv.
		stdenv = pkgs.gcc13Stdenv;
	};

	PROJECT_ROOT   = builtins.toString ./.;
	PROJECT_SYSTEM = pkgs.system;

	clangFlags = ''
		-g
		-O1
		-DNDEBUG
		-pthread
		-std=c++20
		-I./
		-include ${PROJECT_ROOT}/Compliance_Workarounds.hpp
		-DUSING_TOMS_SUGGESTIONS
		-D__func__=__PRETTY_FUNCTION__
		-stdlib=libstdc++
		-Weverything
		-Wno-comma
		-Wno-unused-template
		-Wno-sign-conversion
		-Wno-exit-time-destructors
		-Wno-global-constructors
		-Wno-missing-prototypes
		-Wno-weak-vtables
		-Wno-padded
		-Wno-double-promotion
		-Wno-c++98-compat-pedantic
		-Wno-c++11-compat-pedantic
		-Wno-c++14-compat-pedantic
		-Wno-c++17-compat-pedantic
		-Wno-c++20-compat-pedantic
		-fdiagnostics-show-category=name
		-Wno-zero-as-null-pointer-constant
		-Wno-ctad-maybe-unsupported
	'';

	gccFlags = ''
		-g
		-O1
		-DNDEBUG
		-pthread
		-std=c++20
		-I./
		-include ${PROJECT_ROOT}/Compliance_Workarounds.hpp
		-DUSING_TOMS_SUGGESTIONS
		-D__func__=__PRETTY_FUNCTION__
		-Wall
		-Wextra
		-pedantic
		-Wdelete-non-virtual-dtor
		-Wduplicated-branches
		-Wduplicated-cond
		-Wextra-semi
		-Wfloat-equal
		-Winit-self
		-Wlogical-op
		-Wnoexcept
		-Wshadow
		-Wnon-virtual-dtor
		-Wold-style-cast
		-Wstrict-null-sentinel
		-Wsuggest-override
		-Wswitch-default
		-Wswitch-enum
		-Woverloaded-virtual
		-Wuseless-cast
	'';

	complianceWorkarounds = systemPkgs.fetchurl {
		url = "https://raw.githubusercontent.com/diamondburned/cpsc-131-env/5b6d59ed57552e7291557306f63bf1d17e44a767/Compliance_Workarounds.hpp";
		sha256 = "sha256-VP42u6jFOdQYawEKPSiS9OzBFkFcO9pP6+0oDIdn1Q0=";
	};

	writeText = name: text:
		let dst = pkgs.writeTextDir name text;
		in "${dst}/${name}";

	build_sh = ''
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
				-o "''${executableFileName}_clang++" "''${sourceFiles[@]}"

		g++ \
			$(flagfile compile_flags_g++.txt) \
			-o "''${executableFileName}_g++" "''${sourceFiles[@]}"
	'';

	clean_sh = ''
		for exec in $(find ./ -path ./.\* -prune -o -print -executable); {
			[[ $exec == *"_clang++" || $exec == *"_g++" ]] && {
				echo rm "$exec"
				rm "$exec"
			}
		}
	'';

	run_sh = ''
		set -e

		build.sh
		"./$(basename "$PWD")_g++" | tee output.txt
	'';

in gccShell {
	# Poke a PWD hole for our shell scripts to utilize.
	inherit PROJECT_ROOT PROJECT_SYSTEM;

	shellHook = ''
		# Prepare the project directory environment.
		cp -n ${writeText "compile_flags.txt" clangFlags} $PROJECT_ROOT/
		cp -n ${writeText "compile_flags_g++.txt" gccFlags} $PROJECT_ROOT/
		cp -n ${complianceWorkarounds} $PROJECT_ROOT/Compliance_Workarounds.hpp
	'';

	buildInputs = with pkgs; [
		# Shell scripts.
		(pkgs.writeShellScriptBin "build.sh" build_sh)
		(pkgs.writeShellScriptBin "Build.sh" build_sh)
		(pkgs.writeShellScriptBin "clean.sh" clean_sh)
		(pkgs.writeShellScriptBin "Clean.sh" clean_sh)
		(pkgs.writeShellScriptBin "run.sh"   run_sh)
		(pkgs.writeShellScriptBin "Run.sh"   run_sh)

		# Apparently we get a clang-format that doesn't fucking work. Using clang-format makes the
		# autograder flag the assignment to an F. Brilliant! Fucking lovely!
		(pkgs.writeShellScriptBin "clang-format" "")

		automake
		autoconf
		curl
		git
		lldb
	] ++ [
		clangd
		clang
	];
}
