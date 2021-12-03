#!/bin/bash
# build_UFSDA.sh
# 1 - determine if on supported host
# 2 - load modules
# 3 - run ecbuild
# 4 - build
# 5 - optional, run unit tests

set -eux

dir_root="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"

# determine machine
if [[ -d /scratch1 ]] ; then
    . $MODULESHOME/init/sh
    target=hera
elif [[ -d /work ]]; then
    . $MODULESHOME/init/sh
    target=orion
else
    echo "unknown target"
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
if [ ${run_tests:-"NO"} = "YES" ]; then
    if [ $target = hera -o $target = orion ]; then
        export SLURM_ACCOUNT=${SLURM_ACCOUNT:-"da-cpu"}
        export SALLOC_ACCOUNT=${SALLOC_ACCOUNT:-$SLURM_ACCOUNT}
        export SBATCH_ACCOUNT=${SBATCH_ACCOUNT:-$SLURM_ACCOUNT}
        export SLURM_QOS=${SLURM_QOS:-"debug"}
	  fi
    if [ $target = orion ]; then
        ulimit -s unlimited
    fi
    ctest --rerun-failed  --output-on-failure
fi
