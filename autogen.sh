#!/bin/sh -e

test -d .git && git submodule update --init

aclocal -I m4 --install
autoreconf -fvi
