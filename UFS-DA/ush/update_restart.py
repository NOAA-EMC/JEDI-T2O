#!/usr/bin/env python3
import click
import netCDF4 as nc

# list of fields to ignore
ignore_vars = [
    'xaxis_1',
    'yaxis_1',
    'zaxis_1',
    'xaxis_2',
    'yaxis_2',
    'zaxis_2',
    'Time',
    ]


@click.command()
@click.argument('analysis', type=click.Path(exists=True))
@click.argument('restart', type=click.Path(exists=True))
def run_update_restart(analysis, restart):
    """
    run_update_restart(analysis, restart)
    replace fields in `restart` with those
    from `analysis`
    Both arguments must be paths to FV3 tiled RESTART files
    """
    with nc.Dataset(analysis, 'r') as anl, nc.Dataset(restart, 'a') as rst:
        # check that dimensions match - disable for the time being
        # check_dims(anl, rst)

        # loop through variables now
        for ncv in anl.variables:
            if ncv in ignore_vars:
                continue

            ncv_ges = ncv
            if ncv not in rst.variables:
                if ncv.upper() not in rst.variables:
                    raise KeyError(f"Variable {ncv} not in both files")
                ncv_ges = ncv.upper()

            data = anl.variables[ncv][:]
            outvar = rst.variables[ncv_ges]
            outvar[:] = data
            print(f"update ges {ncv_ges} with anl {ncv}")


def check_dims(file1, file2):
    """
    check to ensure that dimensions of both files
    are the same name, quantity, and of equal size
    """
    for dim in file1.dimensions.values():
        if dim.name not in file2.dimensions:
            raise KeyError(f"Dimension {dim.name} not in both files")
        size1 = dim.size
        size2 = file2.dimensions[dim.name].size
        if size1 != size2:
            raise ValueError(f"Size mismatch for {dim.name}: {size1} != {size2}")


if __name__ == '__main__':
    run_update_restart()
