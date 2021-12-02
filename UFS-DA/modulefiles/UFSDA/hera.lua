-- NOAA RDHPCS Hera Modulefile for UFS-DA
help([[
]])

local pkgName    = myModuleName()
local pkgVersion = myModuleVersion()
local pkgNameVer = myModuleFullName()

local jedi_opt = '/scratch1/NCEPDEV/jcsda/jedipara/opt/modules'
setenv('JEDI_OPT', jedi_opt)
local jedi_core = pathJoin(jedi_opt, 'modulefiles/core')
prepend_path("MODULEPATH", jedi_core)

load('jedi/intel-impi/2020.2')

local ecbuild_cmd = 'ecbuild -DMPIEXEC_EXECUTABLE=`which srun` -DMPIEXEC_NUMPROC_FLAG="-n"'
setenv('ECBUILD_CMD', ecbuild_cmd)

whatis("Name: ".. pkgName)
whatis("Version: " .. pkgVersion)
whatis("Category: UFS-DA")
whatis("Description: Load JEDI-Stack for UFS-DA")
