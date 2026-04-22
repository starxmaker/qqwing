#!/usr/bin/env bash
# qqwing - Sudoku solver and generator
# Copyright (C) 2026 Stephen Ostermiller
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="$(sed -n 's/^AC_INIT(qqwing, *\([^,]*\),.*/\1/p' "$SCRIPT_DIR/configure.ac")"

TARGET_DIR="$REPO_ROOT/target/wasm"
BUILD_DIR="$TARGET_DIR/build"
SRC_DIR="$REPO_ROOT/src/cpp"
EMSDK_DIR="${EMSDK_DIR:-$HOME/Git/emsdk}"

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "Error: required command not found: $1" >&2
		exit 1
	}
}

resolve_emcc() {
	if command -v emcc >/dev/null 2>&1; then
		printf '%s\n' "$(command -v emcc)"
		return 0
	fi

	if [ -x "$EMSDK_DIR/upstream/emscripten/emcc" ]; then
		printf '%s\n' "$EMSDK_DIR/upstream/emscripten/emcc"
		return 0
	fi

	echo "Error: emcc not found. Install/activate Emscripten or set EMSDK_DIR correctly." >&2
	exit 1
}

generate_config() {
	cat > "$BUILD_DIR/config.h" <<EOF
#define HAVE_GETTIMEOFDAY 1
#define VERSION "$VERSION"
#define PACKAGE_STRING "qqwing $VERSION"
EOF
}

patch_main() {
	local main_cpp="$BUILD_DIR/main.cpp"
	local tmpfile

	if ! grep -q '^#include <emscripten.h>' "$main_cpp"; then
		tmpfile="$(mktemp)"
		{
			echo '#include <stdio.h>'
			echo '#include <emscripten.h>'
			cat "$main_cpp"
		} > "$tmpfile"
		mv "$tmpfile" "$main_cpp"
	fi

	if ! grep -q 'EMSCRIPTEN_KEEPALIVE' "$main_cpp"; then
		tmpfile="$(mktemp)"
		awk '
			{
				if ($0 ~ /^int main[[:space:]]*\(int argc, char \*argv\[\]\)[[:space:]]*\{/ && !done) {
					print "EMSCRIPTEN_KEEPALIVE"
					done=1
				}
				print
			}
		' "$main_cpp" > "$tmpfile"
		mv "$tmpfile" "$main_cpp"
	fi
}

require_cmd awk
require_cmd grep
require_cmd mktemp
require_cmd node

if [ ! -d "$EMSDK_DIR" ]; then
	echo "Error: EMSDK_DIR does not exist: $EMSDK_DIR" >&2
	exit 1
fi

EMCC="$(resolve_emcc)"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cp "$SRC_DIR/main.cpp" "$BUILD_DIR/main.cpp"
cp "$SRC_DIR/qqwing.cpp" "$BUILD_DIR/qqwing.cpp"
cp "$SRC_DIR/qqwing.hpp" "$BUILD_DIR/qqwing.hpp"

generate_config
patch_main

echo "Compiling to WASM with: $EMCC"
"$EMCC" "$BUILD_DIR/main.cpp" "$BUILD_DIR/qqwing.cpp" \
	-I"$BUILD_DIR" \
	-o "$BUILD_DIR/main.js" \
	-sMODULARIZE \
	-sEXPORTED_RUNTIME_METHODS=ccall,callMain \
	-sINVOKE_RUN=0 \
	-sENVIRONMENT=node

mkdir -p "$TARGET_DIR"
cp "$BUILD_DIR/main.js" "$TARGET_DIR/main.js"
cp "$BUILD_DIR/main.wasm" "$TARGET_DIR/main.wasm"

rm -rf "$BUILD_DIR"

echo
echo "Build complete:"
