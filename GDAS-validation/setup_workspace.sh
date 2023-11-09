#!/bin/bash
# setup_workspace.sh
# this script:
# - creates working directory
# - clones global-workflow
# - clones GDASApp
# - clones GSI
# - builds GDASApp + GSI
# - creates an experiment for a specified cycle/period
# - links input background files

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
EXPNAME="gdas_eval_satwind"
machine=${machine:-orion}
workdir=""
ICSDir=""

#-------------- User should not modify below here ----------
mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#--- machine dependent paths
if [ $machine = orion ]; then
  workdir=${workdir:-/work2/noaa/da/$LOGNAME/gdas-validation}
  ICSDir=${ICSDir:-/work2/noaa/da/cmartin/UFO_eval/data/para/output_ufo_eval_aug2021}
elif [ $machine = hera ]; then
  workdir=${workdir:-/scratch1/NCEPDEV/stmp2/$LOGNAME/gdas-validation}
  ICSDir=${ICSDir:-/scratch1/NCEPDEV/da/Cory.R.Martin/blah/blah}
else
   echo "Machine " $machine "not found"
   exit 1
fi

#--- create working directory
mkdir -p $workdir

#--- clone repositories ---
if [ $clone = "YES" ]; then
  cd $workdir
  echo "Cloning global-workflow at $workdir/global-workflow"
  git clone https://github.com/noaa-emc/global-workflow.git
  cd global-workflow/sorc
  ./checkout.sh -g
  rm -rf gsi_enkf.fd
  git clone --recursive https://github.com/NOAA-EMC/GSI.git gsi_enkf.fd
  cd gsi_enkf.fd
  git checkout feature/gdas-validation
  cd ../
  [[ -d gdas.cd ]] && rm -rf gdas.cd
  git clone --recursive https://github.com/NOAA-EMC/GDASApp.git gdas.cd
  cd gdas.cd
  git checkout feature/gdas-validation
fi

#--- build GDASApp and GSI ---
if [ $build = "YES" ]; then
  cd $workdir/global-workflow/sorc/gsi_enkf.fd/ush
  echo "Building GSI in $workdir/global-workflow/sorc/gsi_enkf.fd/"
  echo "Build begin: `date`"
  echo "Build log: $workdir/build_gsi.log"
  ./build.sh > $workdir/build_gsi.log 2>&1
  err=$?
  if (( err != 0 )); then
      echo "GSI build abnormal exit $err.  Check $workdir/build_gsi.log"
      exit $err
  fi
  echo "Build complete: `date`"
  cd $workdir/global-workflow/sorc/gdas.cd
  echo "Building GDASApp in $workdir/global-workflow/sorc/gdas.cd"
  echo "Build begin: `date`"
  echo "Build log: $workdir/build_gdasapp.log"
  WORKFLOW_BUILD="ON" ./build.sh > $workdir/build_gdasapp.log 2>&1
  err=$?
  if (( err != 0 )); then
      echo "GDASApp build abnormal exit $err.  Check $workdir/build_gdasapp.log"
      exit $err
  fi
  echo "Build complete: `date`"
  cd $workdir/global-workflow/sorc/
  echo "Link workflow"
  ./link_workflow.sh
  # copy workflow default config files
  echo "Staging configuration files"
  mkdir -p $workdir/gdas_config
  cp -rf $workdir/global-workflow/parm/config/gfs/* $workdir/gdas_config/.
  # copy files that need to be overwritted from default
  cp -rf $mydir/gdas_config/* $workdir/gdas_config/.
  # copy yamls that need to be overwritten for JEDI gdas-validation
  cp -rf $mydir/gdas_config/3dvar_dripcg.yaml $workdir/global-workflow/sorc/gdas.cd/parm/atm/variational/
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
  ICSDIR=$ICSDir/$IDATE
  rm -rf $EXPDIR/${PSLOT}*
  rm -rf $COMROT/${PSLOT}*
  # make two experiments, one GSI, one JEDI
  set -x
  ./setup_expt.py gfs cycled --idate $IDATE --edate $EDATE --app ATM --start warm --gfs_cyc 0 \
    --resdet $RESDET  --nens 0 --cdump $CDUMP --pslot ${PSLOT}_GSI --configdir $CONFIGDIR \
    --comrot $COMROT --expdir $EXPDIR --yaml $CONFIGDIR/config_gsi.yaml --icsdir $ICSDIR
  ./setup_expt.py gfs cycled --idate $IDATE --edate $EDATE --app ATM --start warm --gfs_cyc 0 \
    --resdet $RESDET  --nens 0 --cdump $CDUMP --pslot ${PSLOT}_JEDI --configdir $CONFIGDIR \
    --comrot $COMROT --expdir $EXPDIR --yaml $CONFIGDIR/config_jedi.yaml --icsdir $ICSDIR
  set +x
  # setup the two XMLs
  ./setup_xml.py $EXPDIR/${PSLOT}_GSI
  ./setup_xml.py $EXPDIR/${PSLOT}_JEDI
  # link run_job script to both EXPDIR
  ln -fs $mydir/run_job.sh $EXPDIR/${PSLOT}_GSI/run_job.sh
  ln -fs $mydir/run_job.sh $EXPDIR/${PSLOT}_JEDI/run_job.sh
  # copy run_job configuration to each EXPDIR
  cp $mydir/config_example_gsi.sh $EXPDIR/${PSLOT}_GSI/config_gsi.sh
  cp $mydir/config_example_jedi.sh $EXPDIR/${PSLOT}_JEDI/config_jedi.sh
  # link backgrounds
  # the ICSDIR links the restarts, we also need the GSI inputs
  PDY=${IDATE:0:8}
  cyc=${IDATE:8:2}
  FDATE=$(date --utc +%Y%m%d%H -d "${PDY} ${cyc} + 6 hours")
  sed -i "s/${FDATE}/${IDATE}/g" $EXPDIR/${PSLOT}_GSI/${PSLOT}_GSI.xml
  sed -i "s/${FDATE}/${IDATE}/g" $EXPDIR/${PSLOT}_JEDI/${PSLOT}_JEDI.xml
  GDATE=$(date --utc +%Y%m%d%H -d "${PDY} ${cyc} - 6 hours")
  gPDY=${GDATE:0:8}
  gcyc=${GDATE:8:2}
  mkdir -p ${COMROT}/${PSLOT}_GSI/gdas.${gPDY}/${gcyc}/model_data/atmos/history/
  mkdir -p ${COMROT}/${PSLOT}_GSI/gdas.${gPDY}/${gcyc}/analysis/atmos/
  # below assumes the old com structure for the input data
  echo "Linking backgrounds to ${COMROT}/${PSLOT}_GSI/"
  # only f006, no FGAT in JEDI
  #ln -sf $ICSDIR/gdas.${gPDY}/${gcyc}/atmos/gdas*atmf* ${COMROT}/${PSLOT}_GSI/gdas.${gPDY}/${gcyc}/model_data/atmos/history/.
  #ln -sf $ICSDIR/gdas.${gPDY}/${gcyc}/atmos/gdas*sfcf* ${COMROT}/${PSLOT}_GSI/gdas.${gPDY}/${gcyc}/model_data/atmos/history/.
  ln -sf $ICSDIR/gdas.${gPDY}/${gcyc}/atmos/gdas*atmf006* ${COMROT}/${PSLOT}_GSI/gdas.${gPDY}/${gcyc}/model_data/atmos/history/.
  ln -sf $ICSDIR/gdas.${gPDY}/${gcyc}/atmos/gdas*sfcf006* ${COMROT}/${PSLOT}_GSI/gdas.${gPDY}/${gcyc}/model_data/atmos/history/.
  ln -sf $ICSDIR/gdas.${gPDY}/${gcyc}/atmos/gdas*abias* ${COMROT}/${PSLOT}_GSI/gdas.${gPDY}/${gcyc}/analysis/atmos/.
  # this is so the gdasatmanlfinal job completes successfully
  sed -e '/self\.jedi2fv3inc/s/^/#/g' -i $workdir/global-workflow/ush/python/pygfs/task/atm_analysis.py
fi
