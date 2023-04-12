#
# Copyright (c) 2023 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

# usage: https://github.com/hampoelz/LaTeX-Science-Template/wiki/02-Usage#measurement-data-analysis

if not 'sage' in globals():
    from sage.all import *

import numpy as np
from scipy import interpolate
from scipy import ndimage

class Measures:
    def __init__(self, titles, values, ndigits=None):
        self.titles = titles
        self.rows = values
        self.columns = list(zip(*values))
        n = ndigits
        if ndigits is None:
            n = [None for _ in range(0, len(values[0]))]
        elif ndigits in ZZ:
            n = [ndigits for _ in range(0, len(values[0]))]
        formatted_values = [[format_object(row[value], ndigits=n[value]) for value in range(0, len(row))] for row in values]
        self.table = table(formatted_values, header_row=titles,
                           frame=True, align='center')

    def plot_data(self, x_index, y_index):
        x = self.columns[x_index]
        y = self.columns[y_index]
        data = list(zip(x, y))
        return data

    def g1d_filter(self, x_index, y_index, sigma=2):
        x_column, y_column = zip(*self.plot_data(x_index, y_index))
        x = [float(x) for x in x_column]
        y = [float(y) for y in y_column]
        x_sm = np.array(x)
        y_sm = np.array(y)
        x_g1d = ndimage.gaussian_filter1d(x_sm, sigma)
        y_g1d = ndimage.gaussian_filter1d(y_sm, sigma)
        g1d_data = list(zip(x_g1d, y_g1d))
        return g1d_data

    def smooth_data(self, data, filter_data, num=300, connect=False):
        x_filter, y_filter = zip(*filter_data)
        x_sm = np.array(x_filter)
        y_sm = np.array(y_filter)
        g1d_smooth = np.linspace(x_sm.min(), x_sm.max(), num)
        g1d_spline = interpolate.InterpolatedUnivariateSpline(x_sm, y_sm)
        data_smooth = list(zip(g1d_smooth, g1d_spline(g1d_smooth)))
        if connect:
            data_smooth.insert(0, data[0])
            data_smooth.append(data[-1])
        return data_smooth

    def g1d_smooth(self, x_index, y_index, sigma=2, num=300, connect=False):
        x_column, y_column = zip(*self.plot_data(x_index, y_index))
        x = [float(x) for x in x_column]
        y = [float(y) for y in y_column]
        data = list(zip(x, y))
        filter_data = self.g1d_filter(x_index, y_index, sigma)
        smooth_data = self.smooth_data(data, filter_data, num, connect)
        return smooth_data
