#!/bin/bash
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:         exufsda_global_atmos_analysis_run.sh
# Script description:  Runs the global atmospheric analysis with FV3-JEDI
#
# Author: Cory Martin        Org: NCEP/EMC     Date: 2021-12-28
#
# Abstract: This script makes a global model atmospheric analysis using FV3-JEDI
#
# $Id$
#
# Attributes:
#   Language: POSIX shell
#   Machine: Orion
#
################################################################################

#  Set environment.
export VERBOSE=${VERBOSE:-"YES"}
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXECUTING $0 $* >&2
   set -x
fi

#  Directories
pwd=$(pwd)

#  Utilities
export NLN=${NLN:-"/bin/ln -sf"}

################################################################################
#  Link COMOUT/analysis to $DATA/Data
$NLN $COMOUT/analysis $DATA/Data

#  Link YAML to $DATA
$NLN $COMOUT/analysis/fv3jedi_var.yaml $DATA/fv3jedi_var.yaml

#  Link executable to $DATA
$NLN $JEDIVAREXE $DATA/fv3jedi_var.x

################################################################################
# run executable
export pgm=$JEDIVAREXE
. prep_step
$APRUN_ATMANAL $DATA/fv3jedi_var.x $DATA/fv3jedi_var.yaml 1>&1 2>&2
export err=$?; err_chk

################################################################################
set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err

################################################################################
