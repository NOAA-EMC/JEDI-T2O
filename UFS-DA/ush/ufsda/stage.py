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
    print(config)
    for ob in config['observations']:
        obname = ob['obs space']['name'].lower()
        print(obname)
