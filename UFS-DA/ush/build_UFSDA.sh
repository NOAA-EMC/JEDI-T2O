#!/bin/bash
# build_UFSDA.sh
# 1 - determine if on supported host, load modules if so
# 2 - run ecbuild
# 3 - build
# 4 - optional, run unit tests

set -eux

dir_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"

dir_modules=$dir_root/modulefiles

if [ ${BUILD_TARGET:-} = "orion" -o ${BUILD_TARGET:-} = "hera" ]; then
    set +x
    source $MODULESHOME/init/sh
    module purge
    module use $dir_modules
    module load UFSDA/${BUILD_TARGET}
    module list
    set -x
fi

# remove/create directories
[ -d $dir_root/bin ] || mkdir -p $dir_root/bin

rm -rf $dir_root/build
mkdir -p $dir_root/build
cd $dir_root/build

# run ecbuild
ecbuild -DMPIEXEC_EXECUTABLE=$MPIEXEC_EXEC -DMPIEXEC_NUMPROC_FLAG=$MPIEXEC_NPROC ../src/

# run make
make -j ${BUILD_JOBS:-8} VERBOSE=${BUILD_VERBOSE:-}

# link executables to exec dir
ln -sf $dir_root/build/bin/fv3jedi* $dir_root/bin/.

exit 0
