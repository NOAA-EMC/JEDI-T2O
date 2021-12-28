from r2d2 import fetch
from solo.basic_files import mkdir
from solo.date import Hour, DateIncrement
from solo.logger import Logger
from solo.stage import Stage
import os
import shutil
import datetime as dt

__all__ = ['background', 'fv3jedi', 'obs']


def background(config):
    """
    Stage backgrounds
    NOTE: for now just a symlink to the RESTART directory
    """
    rst_dir = os.path.join(config['background_dir'], 'RESTART')
    bkg_dir = os.path.join(config['COMOUT'], 'analysis', 'bkg')
    try:
        os.symlink(rst_dir, bkg_dir)
    except FileExistsError:
        os.remove(bkg_dir)
        os.symlink(rst_dir, bkg_dir)


def obs(config):
    """
    Stage observations using R2D2
    based on input `config` dict
    """
    # create directory
    obs_dir = os.path.join(config['COMOUT'], 'analysis', 'obs')
    mkdir(obs_dir)
    for ob in config['observations']:
        obname = ob['obs space']['name'].lower()
        outfile = ob['obs space']['obsdatain']['obsfile']
        # the above path is what 'FV3-JEDI' expects, need to modify it
        outpath = outfile.split('/')
        outpath[0] = 'analysis'
        outpath = '/'.join(outpath)
        outfile = os.path.join(config['COMOUT'], outpath)
        # grab obs using R2D2
        fetch(
            type='ob',
            provider=config['r2d2_obs_src'],
            experiment=config['r2d2_obs_dump'],
            date=config['window begin'],
            obs_type=obname,
            time_window=config['window length'],
            target_file=outfile,
            ignore_missing=True,
            database=config['r2d2_obs_db'],
        )
        # if the ob type has them specified in YAML
        # try to grab bias correction files too
        if 'obs bias' in ob:
            bkg_time = config['background_time']
            satbias = ob['obs bias']['input file']
            # the above path is what 'FV3-JEDI' expects, need to modify it
            satbias = satbias.split('/')
            satbias[0] = 'analysis'
            satbias = '/'.join(satbias)
            satbias = os.path.join(config['COMOUT'], satbias)
            # try to grab bc files using R2D2
            fetch(
                type='bc',
                provider=config['r2d2_bc_src'],
                experiment=config['r2d2_bc_dump'],
                date=bkg_time,
                obs_type=obname,
                target_file=satbias,
                file_type='satbias',
                ignore_missing=True,
                database=config['r2d2_obs_db'],
            )
            # below is lazy but good for now...
            tlapse = satbias.replace('satbias.nc4', 'tlapse.txt')
            fetch(
                type='bc',
                provider=config['r2d2_bc_src'],
                experiment=config['r2d2_bc_dump'],
                date=bkg_time,
                obs_type=obname,
                target_file=tlapse,
                file_type='tlapse',
                ignore_missing=True,
                database=config['r2d2_obs_db'],
            )
