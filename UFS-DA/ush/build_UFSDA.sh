#!/bin/bash
# build_UFSDA.sh
# 1 - determine if on supported host
# 2 - load modules
# 3 - run ecbuild
# 4 - build
# 5 - optional, run unit tests

set -ex

cd ..
pwd=$(pwd)

run_tests=${1:-"NO"}
dir_root=${2:-$pwd}

# determine machine
if [[ -d /scratch1 ]] ; then
    . /apps/lmod/lmod/init/sh
    target=hera
elif [[ -d /work ]]; then
    . $MODULESHOME/init/sh
    target=orion
else
    echo "unknown target = $target"
    exit 9
fi

dir_modules=$dir_root/modulefiles

# remove/create directories
[ -d $dir_root/exec ] || mkdir -p $dir_root/exec

rm -rf $dir_root/build
mkdir -p $dir_root/build
cd $dir_root/build

# load modules
module purge
module use $dir_modules
module load UFSDA/$target

# run ecbuild
ecbuild -DMPIEXEC_EXECUTABLE=$MPIEXEC_EXEC -DMPIEXEC_NUMPROC_FLAG=$MPIEXEC_NPROC ../sorc/

# run make
make -j8

# link executables to exec dir
ln -sf $dir_root/build/bin/fv3jedi* $dir_root/exec/.

# if option is set, run ctests
if [ $run_tests = "YES" ]; then
    ctest
fi
