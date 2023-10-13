#!/bin/bash
# run_job.sh
# using rocotoboot, point to a global-workflow experiment
# and run a specified job for a specified cycle

usage() {
  set +x
  echo
  echo "Usage: $0 -c /path/to/config.sh -t taskname"
  echo
  echo "  -c  path to config shell script to source"
  echo "  -t  name of workflow task to run"
  echo
  exit 1
}


while getopts ":c:t:h" opt; do
  case $opt in
    c)
      ConfigPath=$OPTARG
      ;;
    t)
      TaskName=$OPTARG
      ;;
  esac
done

if [ $# -ne 4 ]; then
  echo "Incorrect number of arguments"
  usage
fi

# first, source the config script
# this should be a shell script with the following variables defined
#
# EXPDIR=/path/to/EXPDIR/ do not include PSLOT
# PSLOT="gdas_eval_satwind"
# PDY=20210801
# cyc=00
#
#
source $ConfigPath

ROCOTOEXP="-w ${EXPDIR}/${PSLOT}/${PSLOT}.xml -d ${EXPDIR}/${PSLOT}/${PSLOT}.db"
echo "==============================================================================="
echo "==============================================================================="
# rewind and reboot the specified job
echo "Rewinding and booting $TaskName for cycle=${PDY}${cyc}"
rocotorewind $ROCOTOEXP -c ${PDY}${cyc}00 -t $TaskName
rocotoboot $ROCOTOEXP -c ${PDY}${cyc}00 -t $TaskName
echo "==============================================================================="
echo "==============================================================================="
# check the status of the rebooted job
rocotocheck $ROCOTOEXP -c ${PDY}${cyc}00 -t $TaskName
echo "==============================================================================="
echo "==============================================================================="
