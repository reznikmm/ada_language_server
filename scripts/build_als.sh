#!/bin/bash

set -e -x

TAG=$2 # For master it's 24.0.999, while for tag it's the tag itself

# Crates to pin from GitHub repo

PINS="
adasat
gnatcoll
gnatdoc
lal_refactor
langkit_support
libadalang
libadalang_tools
libgpr
libgpr2
markdown
prettier_ada
spawn
vss
"

# Pins repo names (crate name by default)

repo_adasat=AdaSAT
repo_gnatcoll=gnatcoll-core
repo_lal_refactor=lal-refactor
repo_langkit_support=langkit
repo_libadalang_tools=libadalang-tools
repo_libgpr=gprbuild
repo_libgpr2=gpr
repo_prettier_ada=prettier-ada
repo_vss=VSS

# Pins branches (master by default)

branch_gnatdoc=edge
branch_lal_refactor=edge
branch_libgpr2=next
branch_prettier_ada=main

# A temporary file for langkit setevn
SETENV=$PWD/subprojects/libadalang/setenv.sh

# Set `prod` build mode
########################
# for adasat,lal,langkit,lal_refactor,laltools,markdown,spawn
export BUILD_MODE=prod
# for others
export GNATCOLL_BUILD_MODE=PROD
export GPR_BUILD=production
export GPR2_BUILD=release
export VSS_BUILD_PROFILE=release
export PRETTIER_ADA_BUILD_MODE=prod

# Install custom Alire index with missing crates
function install_index() {
    alr index --del=als || true
    alr index --add=$PWD --name=als
}

# Clone dependencies
function pin_crates() {
    for crate in $PINS; do
        repo_var=repo_$crate
        branch_var=branch_$crate

        repo=${!repo_var}
        branch=${!branch_var}

        URL="https://github.com/AdaCore/${repo:-$crate}.git"
        GIT="git clone --depth=1"
        $GIT -b ${branch:-master} $URL subprojects/$crate
        cp -v subprojects/$crate.toml subprojects/$crate/alire.toml
        alr --force --non-interactive pin $crate --use=$PWD/subprojects/$crate
    done
    # Install gprbuild from our index. We need it for Mac OS X ARM64
    alr toolchain --select gprbuild^24
    alr action -r post-fetch # Configure XmlAda, etc
}

# Build langkit shared libraries required to generate libadalang.
# Export setenv to $SETENV
# Clean `.ali` and `.o` to avoid static vis relocatable mess
function build_so_raw() {
    cd subprojects/langkit_support
    sed -i.bak -e 's/GPR_BUILD/GPR_LIBRARY_TYPE/' ./langkit/libmanage.py
    pip install .
    python manage.py make --no-mypy \
        --library-types=relocatable --gargs "-cargs -fPIC"
    python manage.py setenv >$SETENV
    cd -
    find . -name '*.o' -delete
    find . -name '*.ali' -delete
}

# Run build_so_raw in Alire environment
function build_so() {
    LIBRARY_PATH=relocatable alr exec $0 -- build_so_raw
}

# Build ALS with alire
function build_als() {
    ADALIB=$(dirname "$(alr exec gcc -- -print-libgcc-file-name)")/adalib
    LIBGCC=$(dirname "$(alr exec gcc -- -print-file-name=libgcc_s.so.1)")

    export DYLD_LIBRARY_PATH=$ADALIB:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$LIBGCC:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/subprojects/prettier_ada/lib/relocatable/prod:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/subprojects/vss/.libs/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/alire/cache/dependencies/gnatcoll_iconv_24.0.0_e90c5b4d/iconv/lib/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/alire/cache/dependencies/gnatcoll_gmp_24.0.0_e90c5b4d/gmp/lib/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/subprojects/gnatcoll/projects/lib/gnatcoll_projects/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/subprojects/libgpr/gpr/lib/production/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/alire/cache/dependencies/xmlada_24.0.0_ae5a015b/schema/lib/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/alire/cache/dependencies/xmlada_24.0.0_ae5a015b/dom/lib/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/alire/cache/dependencies/xmlada_24.0.0_ae5a015b/sax/lib/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/alire/cache/dependencies/xmlada_24.0.0_ae5a015b/input_sources/lib/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/alire/cache/dependencies/xmlada_24.0.0_ae5a015b/unicode/lib/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/subprojects/gnatcoll/core/lib/gnatcoll_core/relocatable:$DYLD_LIBRARY_PATH
    export DYLD_LIBRARY_PATH=$PWD/subprojects/gnatcoll/minimal/lib/gnatcoll_core/relocatable:$DYLD_LIBRARY_PATH

    LIBRARY_TYPE=static STANDALONE=no alr exec make -- VERSION=$TAG check
}

# Setup venv for python
[ -d venv ] || python3 -m venv venv
. venv/bin/activate
pip3 install e3-testsuite

case ${1:-all} in
all)
    install_index
    pin_crates
    build_so
    build_als
    ;;

install_index)
    install_index
    ;;

pin_crates)
    pin_crates
    ;;

build_so)
    build_so
    ;;

build_so_raw)
    build_so_raw
    ;;

build_als)
    build_als
    ;;

esac
