# SYNOPSIS
#
#   AX_PYTHON_GI(gi_module, version[, python])
#
# DESCRIPTION
#
#   Checks for Python GObject Introspection and GI module with the given
#   version.
#
# LICENSE
#
#    Copyright (C) 2015 Igor Gnatenko <ignatenko@src.gnome.org>
#
#    Copying and distribution of this file, with or without modification, are
#    permitted in any medium without royalty provided the copyright notice
#    and this notice are preserved. This file is offered as-is, without any
#    warranty.
#
#    From
#    https://blogs.gnome.org/ignatenko/2015/07/18/how-to-check-for-python-gobject-introspection-modules-in-autotools/
 
AC_DEFUN([AX_PYTHON_GI], [
    dnl XXX: We do it once manually. Using AC_REQUIRE would be nice, but we
    dnl can't pass arguments...
    dnl AC_MSG_CHECKING([for bindings for GObject Introspection])
    dnl AX_PYTHON_MODULE([gi], [required], [$3])
    AC_MSG_CHECKING([for version $2 of $1 GObject Introspection module])
    $PYTHON -c "import gi; gi.require_version('$1', '$2')" 2> /dev/null
    AS_IF([test $? -eq 0],
    [
        HAVE_PYTHON_GI_$1=$2
        AC_MSG_RESULT([yes])
    ],
    [
        HAVE_PYTHON_GI_$1=no
        AC_MSG_RESULT([no])
    ])
])
