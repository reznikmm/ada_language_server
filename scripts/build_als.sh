#!/bin/bash

set -e -x

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

# Extra arguments for gprbuild in ALS build
ALS_GARGS=""

# Install custom Alire with missing crates
function install_index()
{
    alr index --del=als || true
    alr index --add=$PWD --name=als
}

# Clone dependencies
function pin_crates()
{
    for crate in $PINS ; do
	    declare -n repo=repo_${crate}
	    declare -n branch=branch_${crate}
        GIT="git clone --depth=1"
	    $GIT -b ${branch:-master} https://github.com/AdaCore/${repo:-$crate}.git subprojects/${crate}
	    cp -v subprojects/$crate.toml subprojects/${crate}/alire.toml
	    alr --force --non-interactive pin $crate --use=$PWD/subprojects/${crate}
    done
    alr action -r post-fetch # Configure XmlAda, etc
}

# Build langkit shared libraries required to generate libadalang.
# Export setenv to $SETENV
# Clean `.ali` and `.o` to avoid static vis relocatable mess
function build_so_raw()
{
    cd subprojects/langkit_support
    sed -i.bak -e 's/GPR_BUILD/GPR_LIBRARY_TYPE/' ./langkit/libmanage.py
    pip install .
    unset OS
    LIBRARY_PATH=relocatable \
		python manage.py make --no-mypy \
		--library-types=relocatable --gargs "-cargs -fPIC"
    python manage.py setenv > $SETENV
    cd -
    find . -name '*.o' -delete
    find . -name '*.ali' -delete
}

# Run build_so_raw in Alire environment
function build_so()
{
    alr exec $0 -- build_so_raw
}

# Build ALS with alire
function build_als()
{
    unset OS
    LIBRARY_TYPE=static STANDALONE=no alr build -- $ALS_GARGS
}

# Setup venv for python
[ -d venv ] || python3 -m venv venv
. venv/bin/activate

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
