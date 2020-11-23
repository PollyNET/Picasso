import matplotlib
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
from matplotlib.dates import DateFormatter, DayLocator, HourLocator, \
    MinuteLocator, date2num
from matplotlib.ticker import MultipleLocator, FormatStrFormatter
import os
import sys
import scipy.io as spio
import numpy as np
from datetime import datetime, timedelta
import re
plt.switch_backend('Agg')


def parse_polly_filename(pollyFile):
    """
    parse the datetime from the polly data filename.
    """

    psFmt = r"^(\d{4})_(\d{2})_(\d{2}).*_(\d{2})_(\d{2})_(\d{2})*.*"
    items = re.search(psFmt, pollyFile)

    dt = datetime(
        int(items[1]),
        int(items[2]),
        int(items[3]),
        int(items[4]),
        int(items[5]),
        int(items[6])
    )

    return dt


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


def pollyxt_display_overlap(tmpFile, saveFolder):
    """
    Description
    -----------
    Display the housekeeping data from laserlogbook file.

    Parameters
    ----------
    tmpFile: str
    the .mat file which stores the housekeeping data.

    saveFolder: str

    Usage
    -----
    pollyxt_display_overlap(tmpFile, saveFolder)

    History
    -------
    2019-01-10. First edition by Zhenping
    """

    if not os.path.exists(tmpFile):
        print('{filename} does not exists.'.format(filename=tmpFile))
        return

    # read matlab .mat data
    try:
        mat = spio.loadmat(tmpFile, struct_as_record=True)
        figDPI = mat['figDPI'][0][0]
        flagWatermarkOn = mat['flagWatermarkOn'][0][0]
        if mat['partnerLabel'].size:
            partnerLabel = mat['partnerLabel'][0]
        else:
            partnerLabel = ''
        overlap355 = mat['overlap355'].reshape(-1)
        overlap532 = mat['overlap532'].reshape(-1)
        overlap355Defaults = mat['overlap355Defaults'].reshape(-1)
        overlap532Defaults = mat['overlap532Defaults'].reshape(-1)
        sig355FR = mat['sig355FR'].reshape(-1)
        sig355NR = mat['sig355NR'].reshape(-1)
        sig532FR = mat['sig532FR'].reshape(-1)
        sig532NR = mat['sig532NR'].reshape(-1)
        sig355Gl = mat['sig355Gl'].reshape(-1)
        sig532Gl = mat['sig532Gl'].reshape(-1)
        sigRatio355 = mat['sigRatio355'].reshape(-1)
        sigRatio532 = mat['sigRatio532'].reshape(-1)
        normRange355 = mat['normRange355'].reshape(-1)
        normRange532 = mat['normRange532'].reshape(-1)
        height = mat['height'].reshape(-1)
        pollyVersion = mat['campaignInfo']['name'][0][0][0]
        location = mat['campaignInfo']['location'][0][0][0]
        version = mat['processInfo']['programVersion'][0][0][0]
        fontname = mat['processInfo']['fontname'][0][0][0]
        dataFilename = mat['taskInfo']['dataFilename'][0][0][0]
        imgFormat = mat['imgFormat'][:][0]
    except Exception as e:
        print(e)
        print('Failed reading %s' % (tmpFile))
        return

    # set the default font
    matplotlib.rcParams['font.sans-serif'] = fontname
    matplotlib.rcParams['font.family'] = "sans-serif"

    # display
    fig, (ax1, ax2) = plt.subplots(
        1, 2, figsize=(8, 8),
        sharey=True,
        gridspec_kw={
            'width_ratios': [1.2, 1],
            'wspace': 0.05, 'top': 0.94, 'right': 0.97}
        )

    # display signal
    p1, = ax1.plot(overlap355, height, color='#1544E9',
                   linestyle='-', label=r'overlap 355 FR')
    p2, = ax1.plot(overlap532, height, color='#58B13F',
                   linestyle='-', label=r'overlap 532 FR')
    p3, = ax1.plot(overlap355Defaults, height, color='#1544E9',
                   linestyle='--', label=r'default overlap 355 FR')
    p4, = ax1.plot(overlap532Defaults, height, color='#58B13F',
                   linestyle='--', label=r'default overlap 532 FR')
    ax1.set_ylim([0, 3000])
    ax1.set_xlim([-0.05, 1.1])
    ax1.set_ylabel('Height (m)', fontsize=15)
    ax1.set_xlabel('Overlap', fontsize=15)
    ax1.tick_params(axis='both', which='major', labelsize=15,
                    right=True, top=True, width=2, length=5)
    ax1.tick_params(axis='both', which='minor', width=1.5,
                    length=3.5, right=True, top=True)
    ax1.grid(True)
    ax1.yaxis.set_major_locator(MultipleLocator(500))
    ax1.yaxis.set_minor_locator(MultipleLocator(100))
    start = parse_polly_filename(dataFilename)
    fig.text(
        0.55, 0.96,
        'Overlap for {instrument} at {location}, {time}'.format(
            instrument=pollyVersion,
            location=location,
            time=start.strftime('%Y%m%d %H:%M')
            ),
        horizontalalignment='center',
        fontsize=15
        )
    ax1.legend(handles=[p1, p2, p3, p4], loc='upper left', fontsize=15)

    sig355FR = np.ma.masked_where(sig355FR <= 0, sig355FR)
    sig355NR = np.ma.masked_where(sig355NR <= 0, sig355NR)
    sig355Gl = np.ma.masked_where(sig355Gl <= 0, sig355Gl)
    sig532FR = np.ma.masked_where(sig532FR <= 0, sig532FR)
    sig532NR = np.ma.masked_where(sig532NR <= 0, sig532NR)
    sig532Gl = np.ma.masked_where(sig532Gl <= 0, sig532Gl)
    p1, = ax2.semilogx(sig355FR, height, color='#1544E9',
                       linestyle='-.', label=r'FR 355')
    p2, = ax2.semilogx(sig355NR, height, color='#1544E9',
                       linestyle=':', label=r'NR 355')
    p3, = ax2.semilogx(sig355Gl, height, color='#1544E9',
                       linestyle='-', label=r'FR Glued 355')
    p4, = ax2.semilogx(sig532FR, height, color='#58B13F',
                       linestyle='-.', label=r'FR 532')
    p5, = ax2.semilogx(sig532NR, height, color='#58B13F',
                       linestyle=':', label=r'NR 532')
    p6, = ax2.semilogx(sig532Gl, height, color='#58B13F',
                       linestyle='-', label=r'FR Glued 532')

    if normRange355.size != 0:
        ax2.plot(
            [1e-10, 1e10],
            [height[normRange355[0] - 1], height[normRange355[0] - 1]],
            linestyle='--',
            color='#1544E9'
            )
        ax2.plot(
            [1e-10, 1e10],
            [height[normRange355[-1] - 1], height[normRange355[-1] - 1]],
            linestyle='--',
            color='#1544E9'
            )
    if normRange532.size != 0:
        ax2.plot(
            [1e-10, 1e10],
            [height[normRange532[0] - 1], height[normRange532[0] - 1]],
            linestyle='--',
            color='#58B13F'
            )
        ax2.plot(
            [1e-10, 1e10],
            [height[normRange532[-1] - 1], height[normRange532[-1] - 1]],
            linestyle='--',
            color='#58B13F'
            )

    ax2.set_xlim([1e-2, 1e3])
    ax2.set_xlabel('Signal [MHz]', fontsize=15)
    ax2.tick_params(axis='both', which='major', labelsize=15,
                    right=True, top=True, width=2, length=5)
    ax2.tick_params(axis='both', which='minor', width=1.5,
                    length=3.5, right=True, top=True)
    ax2.grid(False)
    ax2.legend(
        handles=[p1, p2, p3, p4, p5, p6],
        loc='upper right', fontsize=15
        )

    # add watermark
    if flagWatermarkOn:
        rootDir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        im_license = matplotlib.image.imread(
            os.path.join(rootDir, 'img', 'by-sa.png'))

        newax_license = fig.add_axes([0.01, 0.002, 0.14, 0.07], zorder=10)
        newax_license.imshow(im_license, alpha=0.8, aspect='equal')
        newax_license.axis('off')

        fig.text(0.16, 0.012, 'Preliminary\nResults.',
                 fontweight='bold', fontsize=12, color='red',
                 ha='left', va='bottom', alpha=0.8, zorder=10)

        fig.text(
            0.47, 0.003,
            u"\u00A9 {1} & {2} {0}.\nCC BY SA 4.0 License.".format(
                datetime.now().strftime('%Y'), 'TROPOS', partnerLabel),
            fontweight='bold', fontsize=7, color='black', ha='left',
            va='bottom', alpha=1, zorder=10)

    fig.text(
        0.82, 0.01, 'Version {version}'.format(version=version), fontsize=15)
    # plt.tight_layout()
    fig.savefig(
        os.path.join(
            saveFolder,
            '{dataFilename}_overlap.{imgFmt}'.format(
                dataFilename=rmext(dataFilename),
                imgFmt=imgFormat)), dpi=figDPI)

    plt.close()


def main():
    pollyxt_display_overlap(
        'D:\\coding\\matlab\\pollynet_Processing_Chain\\tmp\\',
        'C:\\Users\\zpyin\\Desktop')


if __name__ == '__main__':
    # main()
    pollyxt_display_overlap(sys.argv[1], sys.argv[2])
