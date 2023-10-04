#!/bin/bash
# setup_workspace.sh
# this script:
# - creates working directory
# - clones global-workflow
# - clones GDASApp
# - clones GSI
# - builds GDASApp + GSI
# - creates an experiment for a specified cycle/period

usage() {
  set +x
  echo
  echo "Usage: $0 [-c] [-b] [-s]"
  echo
  echo "  -c  clone necessary repositories"
  echo "  -b  build GDASApp and GSI"
  echo "  -s  setup default experiment"
  echo "  -h  display this message and quit"
  echo
  exit 1
}

clone=NO
build=NO
setup=NO

while getopts "cbsh" opt; do
  case $opt in
    c)
      clone=YES
      ;;
    b)
      build=YES
      ;;
    s)
      setup=YES
      ;;
    h|\?|:)
      usage
      ;;
  esac
done

#--------------- User modified options below -----------------

machine=${machine:-orion}

if [ $machine = orion ]; then
  workdir=/work2/noaa/da/$LOGNAME/gdas-validation/
  ICSDir=/work2/noaa/da/cmartin/blah/blah
elif [ $machine = hera ]; then
  workdir=/scratch1/NCEPDEV/stmp2/$LOGNAME/gdas-validation/
  ICSDir=/scratch1/NCEPDEV/da/Cory.R.Martin/blah/blah
else
   echo "Machine " $machine "not found"
   exit 1
fi

EXPNAME="gdas_eval_satwind"
mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


#-------------- User should not modify below here ----------
mkdir -p $workdir

#--- clone repositories ---
if [ $clone = "YES" ]; then
  cd $workdir
  git clone https://github.com/noaa-emc/global-workflow.git
  cd global-workflow/sorc
  ./checkout.sh -g
  rm -rf gsi_enkf.fd
  git clone --recursive https://github.com/CoryMartin-NOAA/GSI.git gsi_enkf.fd
  git clone --recursive https://github.com/NOAA-EMC/GDASApp.git gdas.cd
  # note below is not perfect, due to gsi/fix changing from gerrit to hosted locally
  cd gsi_enkf.fd
  git checkout gfsda.v16.3.8
fi

#--- build GDASApp and GSI ---
if [ $build = "YES" ]; then
  cd $workdir/global-workflow/sorc/gsi_enkf.fd/ush
  ./build.sh
  cd $workdir/global-workflow/sorc/gdas.cd
  WORKFLOW_BUILD="ON" ./build.sh
  cd $workdir/global-workflow/sorc/
  ./link_workflow.sh
  # copy workflow default config files
  mkdir -p $workdir/gdas_config
  cp -rf $workdir/global-workflow/parm/config/gfs/* $workdir/gdas_config/.
  # copy files that need to be overwritted from default
  cp -rf $mydir/gdas_config/* $workdir/gdas_config/.
fi

#--- setup default experiment within workflow
if [ $setup = "YES" ]; then
  module use $workdir/global-workflow/sorc/gdas.cd/modulefiles
  module load GDAS/$machine
  cd $workdir/global-workflow/workflow
  # setup_expt variables
  IDATE=2021080100
  EDATE=2021080200
  RESDET=768
  CDUMP=gdas
  PSLOT=${EXPNAME:-"gdas_eval"}
  CONFIGDIR=$workdir/gdas_config
  COMROT=$workdir/comrot
  EXPDIR=$workdir/expdir
  rm -rf $EXPDIR/${PSLOT}*
  rm -rf $COMROT/${PSLOT}*
  # make two experiments, one GSI, one JEDI
  ./setup_expt.py gfs cycled --idate $IDATE --edate $EDATE --app ATM --start warm --gfs_cyc 0 \
    --resdet $RESDET  --nens 0 --cdump $CDUMP --pslot ${PSLOT}_GSI --configdir $CONFIGDIR \
    --comrot $COMROT --expdir $EXPDIR --yaml $CONFIGDIR/config_gsi.yaml
  ./setup_expt.py gfs cycled --idate $IDATE --edate $EDATE --app ATM --start warm --gfs_cyc 0 \
    --resdet $RESDET  --nens 0 --cdump $CDUMP --pslot ${PSLOT}_JEDI --configdir $CONFIGDIR \
    --comrot $COMROT --expdir $EXPDIR --yaml $CONFIGDIR/config_jedi.yaml
  # setup the two XMLs
  ./setup_xml.py $EXPDIR/${PSLOT}_GSI
  ./setup_xml.py $EXPDIR/${PSLOT}_JEDI
fi