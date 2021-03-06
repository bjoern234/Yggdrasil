using BinaryBuilder

# Collection of sources required to build FastTransforms
name = "FastTransforms"
version = v"0.3.1"
sources = [
    ArchiveSource("https://github.com/MikaelSlevinsky/FastTransforms/archive/v$(version).tar.gz",
                  "2b41f69b176cf1fc0a69f8d4b5ec62f5e20426eeb13ddf85a0b406d9e581758f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FastTransforms-*
if [[ ${target} == x86_64-w64-mingw32 ]]; then
    export CFLAGS="-O3 -mavx -fno-asynchronous-unwind-tables "
else
    export CFLAGS="-O3 -mavx "
fi
if [[ ${nbits} == 64 ]]; then
    SYMBOL_DEFS=()
    SYMBOLS=(dgemm dtrmm dtrmv dtrsm sgemm strmm strsm ztrmm)
    for sym in ${SYMBOLS[@]}; do
        SYMBOL_DEFS+=("-Dcblas_${sym}=cblas_${sym}64_")
    done
    CFLAGS+=${SYMBOL_DEFS[@]}
    BLAS=openblas64_
else
    BLAS=openblas
fi
make assembly CC=gcc
make lib CC=gcc FT_PREFIX=${prefix} FT_BLAS=${BLAS} FT_FFTW_WITH_COMBINED_THREADS=1
mv -f libfasttransforms.${dlext} ${libdir}
"""

platforms = expand_gfortran_versions(supported_platforms())
platforms = [p for p in platforms if BinaryBuilder.proc_family(p) == :intel]

# The products that we will ensure are always built
products = [
    LibraryProduct("libfasttransforms", :libfasttransforms),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("FFTW_jll"),
    Dependency("MPFR_jll"),
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
