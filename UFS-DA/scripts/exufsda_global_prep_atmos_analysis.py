#!/usr/bin/env python3
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:         exufsda_global_prep_atmos_analysis.py
# Script description:  Stages files and generates YAML for UFS Global Atmosphere Analysis
#
# Author: Cory Martin      Org: NCEP/EMC     Date: 2021-12-21
#
# Abstract: This script stages necessary input files and produces YAML
#           configuration input file for FV3-JEDI executable(s) needed
#           to produce a UFS Global Atmospheric Analysis.
#
# $Id$
#
# Attributes:
#   Language: Python3
#
################################################################################

# import os and sys to add ush to path
import os
import sys

# get absolute path of ush/ directory either from env or relative to this file
my_dir = os.path.dirname(__file__)
my_home = os.path.dirname(os.path.dirname(my_dir))
sys.path.append(os.path.join(os.getenv('HOMEgfs', my_home), 'ush'))
print(f"sys.path={sys.path}")

# import UFSDA utilities
import ufsda

# get COMOUT from env
COMOUT = os.getenv('COMOUT', './')

# create analysis directory for files
anl_dir = os.path.join(COMOUT, 'analysis')
ufsda.mkdir(anl_dir)

# stage observations from R2D2 to COMIN_OBS and then link to analysis subdir

# stage backgrounds from COMIN_GES to analysis subdir

# stage background error parameters files

# stage additional needed files

# generate YAML file for fv3jedi_var
var_yaml = os.path.join(anl_dir, 'fv3jedi_var.yaml')
yaml_template = os.getenv('ATMANALYAML',
                          os.path.join(my_home,
                                       'parm',
                                       'templates',
                                       'ufsda_global_atm_3dvar.yaml'))
ufsda.gen_yaml(var_yaml, yaml_template)
