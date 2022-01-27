{ pkgs ? import <nixpkgs> {} }:

let intel2GAS = pkgs.stdenv.mkDerivation rec {
		name = "intel2GAS";
	
		src = builtins.fetchurl {
			url    = "http://ftp.debian.org/debian/pool/main/i/intel2gas/intel2gas_1.3.3.orig.tar.gz";
			sha256 = "0f4mcs5z41n211g5mlrq1szgp3r0x25hrx4chy718k5igi1mbfwa";
		};
	
		# Required to build intel2gas. Compiling this may spew out some warnings,
		# but they're safe to ignore. The entire compilation should take a few
		# seconds.
		preBuild = ''
			export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -fpermissive"
		'';
	};

	# clangd hack.
	clangd = pkgs.writeScriptBin "clangd" ''
	    #!${pkgs.stdenv.shell}
		export CPATH="$(${pkgs.llvmPackages_latest.clang}/bin/clang -E - -v <<< "" \
			|& ${pkgs.gnugrep}/bin/grep '^ /nix' \
			|  ${pkgs.gawk}/bin/awk 'BEGIN{ORS=":"}{print substr($0, 2)}' \
			|  ${pkgs.gnused}/bin/sed 's/:$//')"
		export CPLUS_INCLUDE_PATH="$(${pkgs.llvmPackages_latest.clang}/bin/clang++ -E - -v <<< "" \
			|& ${pkgs.gnugrep}/bin/grep '^ /nix' \
			|  ${pkgs.gawk}/bin/awk 'BEGIN{ORS=":"}{print substr($0, 2)}' \
			|  ${pkgs.gnused}/bin/sed 's/:$//')"
	    ${pkgs.llvmPackages_latest.clang-unwrapped}/bin/clangd
	'';

	gccShell = pkgs.mkShell.override {
		# Use gcc11 for our shell environment. We don't have a clang13Stdenv.
		stdenv = pkgs.gcc11Stdenv;
	};

	PROJECT_ROOT = builtins.toString ./.;

	# Compliance_Workarounds is omitted because clang++ really doesn't want to
	# see chrono::hh_mm_ss.
	#
	#    -include ${PROJECT_ROOT}/Compliance_Workarounds.hpp

	clangFlags = ''
		-g0
		-O3
		-DNDEBUG
		-pthread
		-std=c++20
		-I./
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
		-g0
		-O3
		-DNDEBUG
		-pthread
		-std=c++20
		-I./
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

	writeText = name: text:
		let dst = pkgs.writeTextDir name text;
		in "${dst}/${name}";

in gccShell ((import ./secrets.nix) // {
	# Poke a PWD hole for our shell scripts to utilize.
	inherit PROJECT_ROOT;

	shellHook = ''
		# Prepare the project directory environment.
		cp -f ${writeText "compile_flags.txt" clangFlags} $PROJECT_ROOT/
		cp -f ${writeText "compile_flags_g++.txt" gccFlags} $PROJECT_ROOT/
	'';

	buildInputs = [ intel2GAS clangd ] ++ (with pkgs; [
		gcc11
		llvmPackages_latest.clang

		intel2GAS
		a2ps
		automake
		autoconf
		cimg
		cscope
		curl
		enscript
		gdb
		git
		gnupg
		gthumb
		readline
		lldb
		nasm
		nfs-utils
		subversion

		# Shell scripts.
		(pkgs.writeShellScriptBin "build.sh" (builtins.readFile ./build.sh))
		(pkgs.writeShellScriptBin "clean.sh" (builtins.readFile ./clean.sh))
		
		# Google Test Libraries.
		gtest
		gmock

		gnome3.seahorse
	]);
})
