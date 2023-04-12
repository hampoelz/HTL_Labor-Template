#
# Copyright (c) 2023 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

# usage: https://github.com/hampoelz/LaTeX-Science-Template/wiki/02-Usage#transfer-function-analysis

if not 'sage' in globals():
    from sage.all import *

import numpy as np
from scipy import signal

class TransferFunction:
    def __init__(self, expr, freq_start, freq_stop, freq_steps):
        self.expr = expr
        self.freq = np.linspace(freq_start, freq_stop,
            num=round((freq_stop-freq_start)/freq_steps))
        self.omeg = 2*np.pi*self.freq
        self.sys = self.expr_to_system()
        self.data = signal.bode(self.sys, self.omeg)
        self.step = signal.step(self.sys)

        self.get_group_delay = self.expr_to_gd()

    def expr_to_system(self):
        expr = self.expr    # eg. (L*s)/(R+L*s)

        # convert expression to a fraction with real numbers for numerical evaluation
        expr = expr._convert(FractionField(RR))

        # extract numerator and denominator
        expr_u = expr.numerator()    # -> (L*s+0)
        expr_v = expr.denominator()  # -> (R+L*s)

        # convert expressions to polynomial ring
        expr_u = expr_u._convert(QQ)
        expr_v = expr_v._convert(QQ)

        expr_u = expr_u.list()
        expr_v = expr_v.list()

        # reverse polynomial list because scipy signal takes a different order ( [x^0, x^1, x^2] to [x^2, x^1, x^0] )
        expr_u = expr_u[::-1] 
        expr_v = expr_v[::-1] 

        # convert to floats
        expr_u = np.array(expr_u, dtype=float)
        expr_v = np.array(expr_v, dtype=float)

        # create a linear time invariant system
        return signal.TransferFunction(expr_u, expr_v)

    def expr_to_gd(self):
        w = var('w')
        expr = self.expr.subs(s=I*w)
        phi = arctan(expr.real()/expr.imag())
        phi_dw = derivative(phi, w).full_simplify()
        return fast_callable(phi_dw, vars=[w])

    def plot_data_omeg_mag_bode(self):
        w, mag_dB, pha = self.data
        return list(zip(w, mag_dB))

    def plot_data_omeg_pha_bode(self):
        w, mag_dB, pha = self.data
        return list(zip(w, pha))

    def plot_data_omeg_gd(self, w_start=None, w_stop=None):
        get_gd = self.get_group_delay
        w = self.omeg

        if w_start:
            w_filter_start = w >= w_start
            w = w[w_filter_start]
        if w_stop:
            w_filter_stop = w <= w_stop
            w = w[w_filter_stop]

        t = get_gd(w)
        return list(zip(w, t))

    def plot_data_freq_mag_bode(self):
        f = self.freq
        w, mag_dB, pha = self.data
        return list(zip(f, mag_dB))

    def plot_data_freq_pha_bode(self):
        f = self.freq
        w, mag_dB, pha = self.data
        return list(zip(f, pha))

    def plot_data_freq_gd(self, f_start=None, f_stop=None):
        get_gd = self.get_group_delay
        f = self.freq

        if f_start:
            f_filter_start = f >= f_start
            f = f[f_filter_start]
        if f_stop:
            f_filter_stop = f <= f_stop
            f = f[f_filter_stop]

        w = 2*np.pi*f
        t = get_gd(w)
        return list(zip(f, t))

    def plot_data_step(self):
        t, y = self.step
        return list(zip(t, y))
