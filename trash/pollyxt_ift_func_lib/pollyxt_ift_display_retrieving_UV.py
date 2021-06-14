import os
import sys
import scipy.io as spio
import numpy as np
from datetime import datetime, timedelta
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator, FormatStrFormatter
from matplotlib.colors import ListedColormap
from matplotlib.dates import DateFormatter, DayLocator, HourLocator, \
    MinuteLocator, date2num
plt.switch_backend('Agg')


def celltolist(xtickstr):
    """
    convert list of list to list of string.

    Examples
    --------

    [['2010-10-11'], [], ['2011-10-12]] =>
    ['2010-10-11], '', '2011-10-12']
    """

    tmp = []
    for iElement in range(0, len(xtickstr)):
        if not len(xtickstr[iElement][0]):
            tmp.append('')
        else:
            tmp.append(xtickstr[iElement][0][0])

    return tmp


def datenum_to_datetime(datenum):
    """
    Convert Matlab datenum into Python datetime.

    Parameters
    ----------
    Date: float

    Returns
    -------
    dtObj: datetime object

    """
    days = datenum % 1
    hours = days % 1 * 24
    minutes = hours % 1 * 60
    seconds = minutes % 1 * 60

    dtObj = datetime.fromordinal(int(datenum)) + \
        timedelta(days=int(days)) + \
        timedelta(hours=int(hours)) + \
        timedelta(minutes=int(minutes)) + \
        timedelta(seconds=round(seconds)) - timedelta(days=366)

    return dtObj


def rmext(filename):
    """
    remove the file extension.

    Parameters
    ----------
    filename: str
    """

    file, _ = os.path.splitext(filename)
    return file


def pollyxt_ift_display_retrieving_UV(tmpFile, saveFolder):
    '''
    Description
    -----------
    Display the profiles of aerosol optical properties and meteorological data.

    Parameters
    ----------
    tmpFile: str
    the .mat file which stores the data.

    saveFolder: str

    Usage
    -----
    pollyxt_ift_display_retrieving_UV(tmpFile)

    History
    -------
    2019-01-10. First edition by Zhenping
    '''

    if not os.path.exists(tmpFile):
        print('{filename} does not exists.'.format(filename=tmpFile))
        return

    # read data
    try:
        mat = spio.loadmat(tmpFile, struct_as_record=True)
        figDPI = mat['figDPI'][0][0]
        flagWatermarkOn = mat['flagWatermarkOn'][0][0]
        if mat['partnerLabel'].size:
            partnerLabel = mat['partnerLabel'][0]
        else:
            partnerLabel = ''
        startIndx = mat['startIndx'][:][0][0]
        endIndx = mat['endIndx'][:][0][0]
        rcs355 = mat['rcs355'][:][0]
        rcs532 = mat['rcs532'][:][0]
        rcs1064 = mat['rcs1064'][:][0]
        height = mat['height'][:][0]
        time = mat['time'][:][0]
        molRCS355 = mat['molRCS355'][:][0]
        molRCS532 = mat['molRCS532'][:][0]
        molRCS1064 = mat['molRCS1064'][:][0]
        refHIndx355 = mat['refHIndx355'][:][0]
        refHIndx532 = mat['refHIndx532'][:][0]
        refHIndx1064 = mat['refHIndx1064'][:][0]
        aerBsc_355_klett = mat['aerBsc_355_klett'][:][0]
        aerBsc_532_klett = mat['aerBsc_532_klett'][:][0]
        aerBsc_1064_klett = mat['aerBsc_1064_klett'][:][0]
        aerBsc_355_raman = mat['aerBsc_355_raman'][:][0]
        aerBsc_532_raman = mat['aerBsc_532_raman'][:][0]
        aerBsc_1064_raman = mat['aerBsc_1064_raman'][:][0]
        aerBsc_355_aeronet = mat['aerBsc_355_aeronet'][:][0]
        aerBsc_532_aeronet = mat['aerBsc_532_aeronet'][:][0]
        aerBsc_1064_aeronet = mat['aerBsc_1064_aeronet'][:][0]
        aerExt_355_klett = mat['aerExt_355_klett'][:][0]
        aerExt_532_klett = mat['aerExt_532_klett'][:][0]
        aerExt_1064_klett = mat['aerExt_1064_klett'][:][0]
        aerExt_355_raman = mat['aerExt_355_raman'][:][0]
        aerExt_532_raman = mat['aerExt_532_raman'][:][0]
        aerExt_1064_raman = mat['aerExt_1064_raman'][:][0]
        aerExt_355_aeronet = mat['aerExt_355_aeronet'][:][0]
        aerExt_532_aeronet = mat['aerExt_532_aeronet'][:][0]
        aerExt_1064_aeronet = mat['aerExt_1064_aeronet'][:][0]
        LR355_raman = mat['LR355_raman'][:][0]
        LR532_raman = mat['LR532_raman'][:][0]
        ang_bsc_355_532_klett = mat['ang_bsc_355_532_klett'][:][0]
        ang_bsc_532_1064_klett = mat['ang_bsc_532_1064_klett'][:][0]
        ang_bsc_355_532_raman = mat['ang_bsc_355_532_raman'][:][0]
        ang_bsc_532_1064_raman = mat['ang_bsc_532_1064_raman'][:][0]
        ang_ext_355_532_raman = mat['ang_ext_355_532_raman'][:][0]
        voldepol355_klett = mat['voldepol355_klett'][:][0]
        voldepol355_raman = mat['voldepol355_raman'][:][0]
        pardepol355_klett = mat['pardepol355_klett'][:][0]
        pardepolStd355_klett = mat['pardepolStd355_klett'][:][0]
        pardepol355_raman = mat['pardepol355_raman'][:][0]
        pardepolStd355_raman = mat['pardepolStd355_raman'][:][0]
        meteorSource = mat['meteorSource'][:][0]
        temperature = mat['temperature'][:][0]
        pressure = mat['pressure'][:][0]
        pollyVersion = mat['campaignInfo']['name'][0][0][0]
        location = mat['campaignInfo']['location'][0][0][0]
        version = mat['processInfo']['programVersion'][0][0][0]
        fontname = mat['processInfo']['fontname'][0][0][0]
        dataFilename = mat['taskInfo']['dataFilename'][0][0][0]
        yLim_Profi_Ext = mat['yLim_Profi_Ext'][:][0]
        yLim_Profi_LR = mat['yLim_Profi_LR'][:][0]
        yLim_Profi_DR = mat['yLim_Profi_DR'][:][0]
        yLim_Profi_Bsc = mat['yLim_Profi_Bsc'][:][0]
        yLim_FR_RCS = mat['yLim_FR_RCS'][:][0]
        yLim_NR_RCS = mat['yLim_NR_RCS'][:][0]
        xLim_Profi_Bsc = mat['xLim_Profi_Bsc'][:][0]
        xLim_Profi_NR_Bsc = mat['xLim_Profi_NR_Bsc'][:][0]
        xLim_Profi_Ext = mat['xLim_Profi_Ext'][:][0]
        xLim_Profi_NR_Ext = mat['xLim_Profi_NR_Ext'][:][0]
        xLim_Profi_RCS = mat['xLim_Profi_RCS'][:][0]
        xLim_Profi_LR = mat['xLim_Profi_LR'][:][0]
        imgFormat = mat['imgFormat'][:][0]

    except Exception as e:
        print(e)
        print('Failed reading %s' % (tmpFile))
        return

    # set the default font
    matplotlib.rcParams['font.sans-serif'] = fontname
    matplotlib.rcParams['font.family'] = "sans-serif"

    # display signal
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.semilogx(rcs355 * 1e6, height, color='#0080ff',
                      linestyle='-', label='FR 355 nm', zorder=3)
    p2, = ax.semilogx(rcs532 * 6e6, height, color='#80ff00',
                      linestyle='-', label='FR 532 nm (X6)', zorder=2)
    p3, = ax.semilogx(rcs1064 * 1.2e8, height, color='#ff6060',
                      linestyle='-', label='FR 1064 nm (X120)', zorder=1)
    p4, = ax.semilogx(molRCS355 * 1e6, height, color='#0000ff',
                      linestyle='--', label='mol 355 nm', zorder=4)
    p5, = ax.semilogx(molRCS532 * 6e6, height, color='#00b300',
                      linestyle='--', label='mol 532 nm (X6)', zorder=5)
    p6, = ax.semilogx(molRCS1064 * 1.2e8, height, color='#e60000',
                      linestyle='--', label='mol 1064 nm (X120)', zorder=6)

    p7, = ax.semilogx([1], [1], color='#000000',
                      linestyle='-', label='Reference Height')
    if not np.isnan(refHIndx355[0]):
        ax.semilogx(
            rcs355[refHIndx355[0]:refHIndx355[1]] * 1e6,
            height[refHIndx355[0]:refHIndx355[1]], color='#000000', zorder=9)
    if not np.isnan(refHIndx532[0]):
        ax.semilogx(
            rcs532[refHIndx532[0]:refHIndx532[1]] * 6e6,
            height[refHIndx532[0]:refHIndx532[1]], color='#000000', zorder=8)
    if not np.isnan(refHIndx1064[0]):
        ax.semilogx(
            rcs1064[refHIndx1064[0]:refHIndx1064[1]] * 1.2e8,
            height[refHIndx1064[0]:refHIndx1064[1]], color='#000000', zorder=7)

    ax.set_xlabel('Range-Corrected Signal [$Mm^{-1}*sr^{-1}$]', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2, p3, p4, p5, p6, p7],
        loc='upper right', fontsize=10)

    ax.set_ylim(yLim_FR_RCS.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(2500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
    ax.set_xlim(xLim_Profi_RCS.tolist())
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.27, 0.002, 0.17, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.71, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.01, 0.02, 'Version: {version}'.format(
        version=version), fontsize=15)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_SIG.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display backscatter with klett method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(aerBsc_355_klett * 1e6, height, color='#0000ff',
                  linestyle='-', label='355 nm', zorder=2)
    p2, = ax.plot(aerBsc_532_klett * 1e6, height, color='#00b300',
                  linestyle='-', label='532 nm', zorder=2)
    p3, = ax.plot(aerBsc_1064_klett * 1e6, height, color='#e60000',
                  linestyle='-', label='1064 nm', zorder=3)

    ax.set_xlabel('Backscatter Coefficient [$Mm^{-1}*sr^{-1}$]', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2, p3], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_Bsc.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(2500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
    ax.set_xlim(xLim_Profi_Bsc.tolist())
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Klett'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_Bsc_Klett.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display backscatter with raman method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(aerBsc_355_raman * 1e6, height, color='#0000ff',
                  linestyle='-', label='355 nm', zorder=2)
    p2, = ax.plot(aerBsc_532_raman * 1e6, height, color='#00b300',
                  linestyle='-', label='532 nm', zorder=2)
    p3, = ax.plot(aerBsc_1064_raman * 1e6, height, color='#e60000',
                  linestyle='-', label='1064 nm', zorder=3)

    ax.set_xlabel('Backscatter Coefficient [$Mm^{-1}*sr^{-1}$]', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2, p3], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_Bsc.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(2500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
    ax.set_xlim(xLim_Profi_Bsc.tolist())
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Raman'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_Bsc_Raman.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display backscatter with Constrained-AOD method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(aerBsc_355_aeronet * 1e6, height, color='#0000ff',
                  linestyle='-', label='355 nm', zorder=2)
    p2, = ax.plot(aerBsc_532_aeronet * 1e6, height, color='#00b300',
                  linestyle='-', label='532 nm', zorder=2)
    p3, = ax.plot(aerBsc_1064_aeronet * 1e6, height,
                  color='#e60000', linestyle='-', label='1064 nm', zorder=3)

    ax.set_xlabel('Backscatter Coefficient [$Mm^{-1}*sr^{-1}$]', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2, p3], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_Bsc.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(2500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
    ax.set_xlim(xLim_Profi_Bsc.tolist())
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.01, 0.02, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='AERONET'), fontsize=10)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_Bsc_Aeronet.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display extinction with klett method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(aerExt_355_klett * 1e6, height, color='#0000ff',
                  linestyle='-', label='355 nm', zorder=2)
    p2, = ax.plot(aerExt_532_klett * 1e6, height, color='#00b300',
                  linestyle='-', label='532 nm', zorder=2)
    p3, = ax.plot(aerExt_1064_klett * 1e6, height, color='#e60000',
                  linestyle='-', label='1064 nm', zorder=3)

    ax.set_xlabel('Extinction Coefficient [$Mm^{-1}$]', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2, p3], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_Ext.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(1000))
    ax.yaxis.set_minor_locator(MultipleLocator(200))
    ax.set_xlim(xLim_Profi_Ext.tolist())
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Klett'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_Ext_Klett.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display extinction with raman method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(aerExt_355_raman * 1e6, height, color='#0000ff',
                  linestyle='-', label='355 nm', zorder=2)
    p2, = ax.plot(aerExt_532_raman * 1e6, height, color='#00b300',
                  linestyle='-', label='532 nm', zorder=2)
    p3, = ax.plot(aerExt_1064_raman * 1e6, height, color='#e60000',
                  linestyle='-', label='1064 nm', zorder=3)

    ax.set_xlabel('Extinction Coefficient [$Mm^{-1}$]', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2, p3], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_Ext.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(1000))
    ax.yaxis.set_minor_locator(MultipleLocator(200))
    ax.set_xlim(xLim_Profi_Ext.tolist())
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Raman'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_Ext_Raman.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display extinction with Constrained-AOD method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(aerExt_355_aeronet * 1e6, height, color='#0000ff',
                  linestyle='-', label='355 nm', zorder=2)
    p2, = ax.plot(aerExt_532_aeronet * 1e6, height, color='#00b300',
                  linestyle='-', label='532 nm', zorder=2)
    p3, = ax.plot(aerExt_1064_aeronet * 1e6, height,
                  color='#e60000', linestyle='-', label='1064 nm', zorder=3)

    ax.set_xlabel('Extinction Coefficient [$Mm^{-1}$]', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2, p3], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_Ext.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(1000))
    ax.yaxis.set_minor_locator(MultipleLocator(200))
    ax.set_xlim(xLim_Profi_Ext.tolist())
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.01, 0.02, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='AERONET'), fontsize=10)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_Ext_Aeronet.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display LR with raman method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(LR355_raman, height, color='#0000ff',
                  linestyle='-', label='355 nm', zorder=2)
    p2, = ax.plot(LR532_raman, height, color='#00b300',
                  linestyle='-', label='532 nm', zorder=2)

    ax.set_xlabel('Lidar Ratio [$Sr$]', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_LR.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(1000))
    ax.yaxis.set_minor_locator(MultipleLocator(200))
    ax.set_xlim(xLim_Profi_LR.tolist())
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Raman'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_LR_Raman.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display angstroem exponent with klett method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(ang_bsc_355_532_klett, height, color='#ff8000',
                  linestyle='-', label='BSC 355-532', zorder=2)
    p2, = ax.plot(ang_bsc_532_1064_klett, height, color='#ff00ff',
                  linestyle='-', label='BSC 532-1064', zorder=2)

    ax.set_xlabel('Angstroem Exponent', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_Ext.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(1000))
    ax.yaxis.set_minor_locator(MultipleLocator(200))
    ax.set_xlim([-1, 2])
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Klett'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_ANGEXP_Klett.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display angstroem exponent with raman method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(ang_bsc_355_532_raman, height, color='#ff8000',
                  linestyle='-', label='BSC 355-532', zorder=2)
    p2, = ax.plot(ang_bsc_532_1064_raman, height, color='#ff00ff',
                  linestyle='-', label='BSC 532-1064', zorder=2)
    p3, = ax.plot(ang_ext_355_532_raman, height, color='#000000',
                  linestyle='-', label='EXT 355-532', zorder=2)

    ax.set_xlabel('Angstroem Exponent', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2, p3], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_Ext.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(1000))
    ax.yaxis.set_minor_locator(MultipleLocator(200))
    ax.set_xlim([-1, 2])
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Raman'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_ANGEXP_Raman.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display depol ratio with klett method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(voldepol355_klett, height, color='#80ff00',
                  linestyle='-', label='$\delta_{vol, 355}$', zorder=2)
    p2, = ax.plot(pardepol355_klett, height, color='#008040',
                  linestyle='--', label='$\delta_{par, 355}$', zorder=3)

    ax.set_xlabel('Depolarization Ratio', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_DR.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(2500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
    ax.set_xlim([-0.01, 0.4])
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Klett'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_DepRatio_Klett.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display depol ratio with raman method
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(voldepol355_raman, height, color='#80ff00',
                  linestyle='-', label='$\delta_{vol, 355}$', zorder=2)
    p2, = ax.plot(pardepol355_raman, height, color='#008040',
                  linestyle='--', label='$\delta_{par, 355}$', zorder=3)

    ax.set_xlabel('Depolarization Ratio', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)
    ax.legend(
        handles=[p1, p2], loc='upper right', fontsize=10)

    ax.set_ylim(yLim_Profi_DR.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(2500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
    ax.set_xlim([-0.01, 0.4])
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        '{instrument} at {location}\n[Averaged] {starttime}-{endtime}'.format(
            instrument=pollyVersion,
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.003,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nMethod: {method}'.format(
        version=version, method='Raman'), fontsize=12)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_DepRatio_Raman.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display meteorological paramters
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(temperature, height, color='#ff0000',
                  linestyle='-', zorder=2)

    ax.set_xlabel('Temperature ($^\circ C$)', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)

    ax.set_ylim(yLim_FR_RCS.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(2500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
    ax.set_xlim([-100, 50])
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        'Meteorological Parameters at ' +
        '{location}\n {starttime}-{endtime}'.format(
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.004, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.014, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.005,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nFrom: {source}'.format(
        version=version, source=meteorSource), fontsize=10)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_Meteor_T.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()

    # display meteorological paramters
    fig = plt.figure(figsize=[5, 8])
    ax = fig.add_axes([0.21, 0.15, 0.74, 0.75])
    p1, = ax.plot(pressure, height, color='#ff0000', linestyle='-', zorder=2)

    ax.set_xlabel('Pressure ($hPa$)', fontsize=15)
    ax.set_ylabel('Height (m)', fontsize=15)

    ax.set_ylim(yLim_FR_RCS.tolist())
    ax.yaxis.set_major_locator(MultipleLocator(2500))
    ax.yaxis.set_minor_locator(MultipleLocator(500))
    ax.set_xlim([0, 1000])
    ax.grid(True)

    starttime = time[startIndx - 1]
    endtime = time[endIndx - 1]
    ax.set_title(
        'Meteorological Parameters at ' +
        '{location}\n {starttime}-{endtime}'.format(
            location=location,
            starttime=datenum_to_datetime(starttime).strftime('%Y%m%d %H:%M'),
            endtime=datenum_to_datetime(endtime).strftime('%H:%M')),
        fontsize=15)

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.3, 0.004, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.46, 0.014, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.69, 0.005,
            u"\u00A9 {1} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(0.02, 0.01, 'Version: {version}\nFrom: {source}'.format(
        version=version, source=meteorSource), fontsize=10)

    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFile}_{starttime}_{endtime}_Meteor_P.{imgFmt}'.format(
                dataFile=rmext(dataFilename),
                starttime=datenum_to_datetime(starttime).strftime('%H%M'),
                endtime=datenum_to_datetime(endtime).strftime('%H%M'),
                imgFmt=imgFormat)),
        dpi=figDPI)
    plt.close()


def main():
    pollyxt_ift_display_retrieving_UV(
        'C:\\Users\\zhenping\\Desktop\\Picasso\\tmp\\tmp.mat',
        'C:\\Users\\zhenping\\Desktop\\Picasso\\recent_plots\\' +
        'pollyxt_ift\\20180517')


if __name__ == '__main__':
    # main()
    pollyxt_ift_display_retrieving_UV(sys.argv[1], sys.argv[2])
