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
import argparse
import pypolly_readout as readout
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


def pollyDisplayWVMR(nc_dict,config_dict,polly_conf_dict,saveFolder):
    """
    Description
    -----------
    Display the water vapor mixing ratio WVMR from level1 polly nc-file.

    Parameters
    ----------
    nc_dict: dict
        dict wich stores the WV data.

    Usage
    -----
    pollyDisplayWVMR(nc_dict,config_dict,polly_conf_dict)
    History
    -------
    2022-09-01. First edition by Andi
    """

    ## read from config file
    figDPI = config_dict['figDPI']
    flagWatermarkOn = config_dict['flagWatermarkOn']
    fontname = config_dict['fontname']


    ## read from global config file
    yLim = polly_conf_dict['yLim_WV_RH']
    zLim = polly_conf_dict['xLim_Profi_WVMR']
    partnerLabel = polly_conf_dict['partnerLabel']
    colormap_basic = polly_conf_dict['colormap_basic']
    imgFormat = polly_conf_dict['imgFormat']

    ## read from nc-file
    WVMR = nc_dict['WVMR']
    quality_mask = nc_dict['quality_mask_WVMR']
    height = nc_dict['height']
    time = nc_dict['time']

    pollyVersion = nc_dict['PollyVersion']
    location = nc_dict['location']
    version = nc_dict['PicassoVersion']
    dataFilename = re.split(r'_WVMR_RH',nc_dict['PollyDataFile'])[0]
    # set the default font
    matplotlib.rcParams['font.sans-serif'] = fontname
    matplotlib.rcParams['font.family'] = "sans-serif"

    plotfile = f'{dataFilename}_WVMR.{imgFormat}'

    ## fill time gaps in att_bsc matrix
    WVMR, quality_mask = readout.fill_time_gaps_of_matrix(time, WVMR, quality_mask)

    ## get date and convert to datetime object
    date_00 = datetime.strptime(nc_dict['m_date'], '%Y-%m-%d')
    date_00 = date_00.timestamp()

    ## set x_lims for 24hours by creating a list of datetime.datetime objects using map.
    x_lims = list(map(datetime.fromtimestamp, [date_00, date_00+24*60*60]))

    ## convert these datetime.datetime objects to the correct format for matplotlib to work with.
    x_lims = date2num(x_lims)

    ## set max_height
    y_max = yLim[1]
    max_height = [ h/1000 for h in height if h < y_max ]

    ## set plot-region for imshow
    extent = [ x_lims[0], x_lims[-1], max_height[0], max_height[-1] ]

    ## mask matrix
    WVMR = np.ma.masked_where(quality_mask> 0, WVMR)
    
    ## slice matrix to max_height
    WVMR = WVMR[:,0:len(max_height)]

    ## transpose and flip for correct plotting
    WVMR= np.ma.transpose(WVMR)  ## matrix has to be transposed for usage with pcolormesh!
    WVMR= np.flip(WVMR,0)

    # define the colormap
    #cmap = load_colormap(name=colormap_basic)
    colormap_basic = "turbo"
    import copy
    cmap =copy.copy(plt.cm.get_cmap(colormap_basic))
    ## set color of nan-values
    cmap.set_bad(color='black')

    print(f"plotting {plotfile} ... ")
    # display attenuate backscatter
    fig = plt.figure(figsize=[12, 6])
    ax = fig.add_axes([0.11, 0.15, 0.79, 0.75])
    pcmesh = ax.imshow(
            WVMR,
            cmap=cmap,
            vmin=zLim[0],
            vmax=zLim[1],
            interpolation='none',
            aspect='auto',
            extent=extent,
            )
    # convert the datetime data from a float (which is the output of date2num into a nice datetime string.
    ax.xaxis_date()

    ax.set_xlabel('Time [UTC]', fontsize=15)
    ax.set_ylabel('Height [km]', fontsize=15)

    ax.xaxis.set_minor_locator(HourLocator(interval=1))    # every hour
    ax.xaxis.set_major_locator(HourLocator(byhour = [4,8,12,16,20,24]))
    ax.xaxis.set_major_formatter(DateFormatter('%H:%M'))
#    
    ax.tick_params(
        axis='both', which='major', labelsize=15, right=True,
        top=True, width=2, length=5)
    ax.tick_params(
        axis='both', which='minor', width=1.5, length=3.5,
        right=True, top=True)

    ax.set_title(
        'Water vapour mixing ratio of {instrument} at {location}'.format(
            instrument=pollyVersion,
            location=location),
        fontsize=15)

    cb_ax = fig.add_axes([0.92, 0.25, 0.02, 0.55])
    cbar = fig.colorbar(
        pcmesh,
        cax=cb_ax,
        ticks=np.linspace(zLim[0], zLim[1], 5),
        orientation='vertical')
    cbar.ax.tick_params(direction='in', labelsize=15, pad=5)
    cbar.ax.set_title('      [$\mathrm{g\, kg^{-1}}$]\n', fontsize=10)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.getcwd()
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.58, 0.006, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.72, 0.003, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.84, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(
        0.05, 0.02,
        '{0}'.format(
#            datenum_to_datetime(time[0]).strftime("%Y-%m-%d"),
            nc_dict['m_date']),
            fontsize=12)
    fig.text(
        0.2, 0.02,
        'Version: {version}'.format(
            version=version),
        fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            plotfile),
        dpi=figDPI)

    plt.close()


def pollyDisplayRH(nc_dict,config_dict,polly_conf_dict,saveFolder):
    """
    Description
    -----------
    Display the relative humidity RH from level1 polly nc-file.

    Parameters
    ----------
    nc_dict: dict
        dict wich stores the WV data.

    Usage
    -----
    pollyDisplayRH(nc_dict,config_dict,polly_conf_dict)

    History
    -------
    2022-09-01. First edition by Andi
    """
    ## read from config file
    figDPI = config_dict['figDPI']
    flagWatermarkOn = config_dict['flagWatermarkOn']
    fontname = config_dict['fontname']


    ## read from global config file
    yLim = polly_conf_dict['yLim_WV_RH']
    zLim = [0,100]
    partnerLabel = polly_conf_dict['partnerLabel']
    colormap_basic = polly_conf_dict['colormap_basic']
    imgFormat = polly_conf_dict['imgFormat']

    RH = nc_dict['RH']
    quality_mask = nc_dict['quality_mask_RH']
    height = nc_dict['height']
    time = nc_dict['time']

    pollyVersion = nc_dict['PollyVersion']
    location = nc_dict['location']
    version = nc_dict['PicassoVersion']
    dataFilename = re.split(r'_WVMR_RH',nc_dict['PollyDataFile'])[0]
    # set the default font
    matplotlib.rcParams['font.sans-serif'] = fontname
    matplotlib.rcParams['font.family'] = "sans-serif"

    plotfile = f'{dataFilename}_RH.{imgFormat}'

    ## fill time gaps in att_bsc matrix
    RH, quality_mask = readout.fill_time_gaps_of_matrix(time, RH, quality_mask)

    ## get date and convert to datetime object
    date_00 = datetime.strptime(nc_dict['m_date'], '%Y-%m-%d')
    date_00 = date_00.timestamp()

    ## set x_lims for 24hours by creating a list of datetime.datetime objects using map.
    x_lims = list(map(datetime.fromtimestamp, [date_00, date_00+24*60*60]))

    ## convert these datetime.datetime objects to the correct format for matplotlib to work with.
    x_lims = date2num(x_lims)

    ## set max_height
    y_max = yLim[1]
    max_height = [ h/1000 for h in height if h < y_max ]

    ## set plot-region for imshow
    extent = [ x_lims[0], x_lims[-1], max_height[0], max_height[-1] ]

    ## mask matrix
    RH = np.ma.masked_where(quality_mask> 0, RH)
    
    ## slice matrix to max_height
    RH = RH[:,0:len(max_height)]

    ## transpose and flip for correct plotting
    RH = np.ma.transpose(RH)  ## matrix has to be transposed for usage with pcolormesh!
    RH = np.flip(RH,0)

    # define the colormap
    #cmap = load_colormap(name=colormap_basic)
    colormap_basic = "turbo"
    import copy
    cmap =copy.copy(plt.cm.get_cmap(colormap_basic))
    ## set color of nan-values
    cmap.set_bad(color='black')

    print(f"plotting {plotfile} ... ")
    # display attenuate backscatter
    fig = plt.figure(figsize=[12, 6])
    ax = fig.add_axes([0.11, 0.15, 0.79, 0.75])
    pcmesh = ax.imshow(
            RH,
            cmap=cmap,
            vmin=zLim[0],
            vmax=zLim[1],
            interpolation='none',
            aspect='auto',
            extent=extent,
            )
    # convert the datetime data from a float (which is the output of date2num into a nice datetime string.
    ax.xaxis_date()

    ax.set_xlabel('Time [UTC]', fontsize=15)
    ax.set_ylabel('Height [km]', fontsize=15)

    ax.xaxis.set_minor_locator(HourLocator(interval=1))    # every hour
    ax.xaxis.set_major_locator(HourLocator(byhour = [4,8,12,16,20,24]))
    ax.xaxis.set_major_formatter(DateFormatter('%H:%M'))
#    
    ax.tick_params(
        axis='both', which='major', labelsize=15, right=True,
        top=True, width=2, length=5)
    ax.tick_params(
        axis='both', which='minor', width=1.5, length=3.5,
        right=True, top=True)

    ax.set_title(
        'Relative humidity of {instrument} at {location}'.format(
            instrument=pollyVersion,
            location=location),
        fontsize=15)

    cb_ax = fig.add_axes([0.92, 0.25, 0.02, 0.55])
    cbar = fig.colorbar(
        pcmesh,
        cax=cb_ax,
        ticks=np.linspace(zLim[0], zLim[1], 5),
        orientation='vertical')
    cbar.ax.tick_params(direction='in', labelsize=15, pad=5)
    cbar.ax.set_title('      [$\mathrm{\%}$]\n', fontsize=10)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.getcwd()
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.58, 0.006, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.72, 0.003, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.84, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(
        0.05, 0.02,
        '{0}'.format(
#            datenum_to_datetime(time[0]).strftime("%Y-%m-%d"),
            nc_dict['m_date']),
            fontsize=12)
    fig.text(
        0.2, 0.02,
        'Version: {version}'.format(
            version=version),
        fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            plotfile),
        dpi=figDPI)

    plt.close()

