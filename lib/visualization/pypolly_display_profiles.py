import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap, LogNorm
from matplotlib.ticker import MultipleLocator, FormatStrFormatter
from matplotlib.dates import DateFormatter, \
                             DayLocator, HourLocator, MinuteLocator, date2num
#import matplotlib.dates as dates
import os
import re
import sys
import time
import scipy.io as spio
import numpy as np
from datetime import datetime, timedelta
import matplotlib
import json
from pathlib import Path
import argparse
import pypolly_readout_profiles as readout_profiles
import statistics
from statistics import mode

# load colormap
dirname = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(dirname)
try:
    from python_colormap import *
except Exception as e:
    raise ImportError('python_colormap module is necessary.')

# generating figure without X server
plt.switch_backend('Agg')



def pollyDisplayWVMR_profile(nc_dict_profile,config_dict,polly_conf_dict,outdir):
    """
    Description
    -----------
    Display the water vapor mixing ratio WVMR from level1 polly nc-file.

    Parameters
    ----------
    nc_dict_profile: dict
        dict wich stores the WV data.

    Usage
    -----
    pollyDisplayWVMR_profile(nc_dict_profile,config_dict,polly_conf_dict)

    History
    -------
    2022-09-01. First edition by Andi
    """

    ## read from config file
    figDPI = config_dict['figDPI']
    flagWatermarkOn = config_dict['flagWatermarkOn']
    fontname = config_dict['fontname']

    ## read from global config file
    yLim_WV = polly_conf_dict['yLim_att_beta_NR']
    xLim_WV = polly_conf_dict['xLim_Profi_WVMR']
    partnerLabel = polly_conf_dict['partnerLabel']
    imgFormat = polly_conf_dict['imgFormat']

    ## read from nc-file
    starttime = nc_dict_profile['start_time']
    endtime = nc_dict_profile['end_time']
    WVMR = nc_dict_profile['WVMR']
    WVMR_rel_error = nc_dict_profile['WVMR_rel_error']
#    quality_mask = nc_dict_profile['quality_mask_WVMR']
    height = nc_dict_profile['height']
#    time = nc_dict_profile['time']
#    LCUsed = np.array([nc_dict_profile[f'LCUsed{wavelength}']])
#    cRange = nc_dict_profile['WVMR_cRange']

#    flagLC = nc_dict_profile[f'flagLC{wavelength}']
    pollyVersion = nc_dict_profile['PollyVersion']
    location = nc_dict_profile['location']
    version = nc_dict_profile['PicassoVersion']
    dataFilename = re.split(r'_profiles',nc_dict_profile['PollyDataFile'])[0]
    # set the default font
    matplotlib.rcParams['font.sans-serif'] = fontname
    matplotlib.rcParams['font.family'] = "sans-serif"

    saveFolder = outdir
    plotfile = f'{dataFilename}_WVMR.{imgFormat}'

    # display WVMR-profile
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
#    p1, = ax.plot(WVMR_rel_error, height, color='#2492ff', linestyle='-', zorder=2)
#    p1 = ax.plot(WVMR, height, color='#2492ff', linestyle='-', zorder=2)
    p1 = ax.errorbar(WVMR, height, xerr=WVMR_rel_error, color='#2492ff', linestyle='-', zorder=2)

    ax.set_xlabel('Water Vapor Mixing Ratio ($g*kg^{-1}$)', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)

#    ax.set_ylim(yLim_Profi_WV_RH.tolist())
    ax.set_ylim(yLim_WV)
    ax.yaxis.set_major_locator(MultipleLocator(1500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
#    ax.set_xlim(xLim_Profi_WV_RH.tolist())
    ax.set_xlim(xLim_WV)
    ax.grid(True)
    ax.tick_params(axis='both', which='major', labelsize=15,
                   right=True, top=True, width=2, length=5)
    ax.tick_params(axis='both', which='minor', width=1.5,
                   length=3.5, right=True, top=True)

#    starttime = time[startInd - 1]
#    endtime = time[endInd - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datetime.utcfromtimestamp(int(starttime)).strftime('%Y%m%d %H:%M'),
            endtime=datetime.utcfromtimestamp(int(endtime)).strftime('%H:%M'),
#            starttime=starttime.strftime('%Y%m%d %H:%M'),
#            endtime=endtime.strftime('%H:%M')
            ),
        fontsize=14
        )


    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        rootDir = os.getcwd()
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.58, 0.006, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.05, 0.01, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.84, 0.01,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

#    fig.text(
#        0.05, 0.02,
#        '{0}'.format(
##            datenum_to_datetime(time[0]).strftime("%Y-%m-%d"),
#            args.timestamp),
#            fontsize=12)
    fig.text(
        0.3, 0.02,
        'Version: {version}'.format(
            version=version),
        fontsize=12)
    print(f"plotting {plotfile} ... ")
    fig.savefig(
        os.path.join(
            saveFolder,
            plotfile),
        dpi=figDPI)

    plt.close()

