# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ThinASLBuilder"
version = v"0.1.0"

# Collection of sources required to build ThinASLBuilder
sources = [
    "http://netlib.org/ampl/solvers.tgz" =>
    "16495404313c54c462c806a4b3e5c80805b23d36cabc12d7796d7a1b6be08c20",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd solvers/
mkdir $prefix/lib

so="so"
all_load="--whole-archive"
noall_load="--no-whole-archive"
makefile="makefile.u"
cflags=""

if [ -f $WORKSPACE/srcdir/asl-extra/arith.h.$target ]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.$target ./arith.h
fi
if [ $target = "arm-linux-musleabihf" ]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.arm-linux-gnueabihf ./arith.h
fi
if [ $target = "i686-linux-musl" ]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.i686-linux-gnu ./arith.h
fi
if [ $target = "aarch64-linux-musl" ]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.aarch64-linux-gnu ./arith.h
fi
if [ $target = "x86_64-unknown-freebsd11.1" ]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.x86_64-linux-gnu ./arith.h
    cflags="-D__XSI_VISIBLE=1"
fi

if [ $target = "x86_64-w64-mingw32" || $target = "i686-w64-mingw32" ]; then
    so="dll"
    makefile="$WORKSPACE/srcdir/asl-extra/makefile.mingw"
fi
if [ $target = "x86_64-apple-darwin14" ]; then
    so="dylib"
    all_load="-all_load"
    noall_load="-noall_load"
fi

make -f $makefile CC=gcc CFLAGS="-O -fPIC $cflags"
g++ -fPIC -shared -I$WORKSPACE/srcdir/asl-extra -I. $WORKSPACE/srcdir/asl-extra/aslinterface.cc -Wl,${all_load} amplsolver.a -Wl,${noall_load} -o libasl.$so
mv libasl.$so $prefix/lib

exit

# macOS build fails with message
# ld: file not found: /usr/lib/system/libcache.dylib for architecture x86_64
# if [ $target = "x86_64-apple-darwin14" ]; then
# fi

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libasl", :libasl)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
