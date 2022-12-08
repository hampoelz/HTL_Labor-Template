import numpy as np
from scipy import signal


class Bode:
    def __init__(self, expr, freq_start, freq_stop, freq_steps):
        self.expr = expr
        self.freq = np.linspace(freq_start, freq_stop,
            num=round((freq_stop-freq_start)/freq_steps))
        self.omeg = 2*np.pi*self.freq
        self.sys = self.expr_to_system()
        self.data = signal.bode(self.sys, self.omeg)

    def expr_to_system(self):
        expr = self.expr    # eg. (L*s)/(R+L*s)

        # convert expression to a fraction with real numbers for numerical evaluation
        expr = expr._convert(FractionField(RR))

        # extract numerator and denominator
        expr_u = expr.numerator()    # -> (L*s+0)
        expr_v = expr.denominator()  # -> (R+L*s)

        # convert expressions to complex numbers
        expr_u = expr_u.substitute(s=I)
        expr_v = expr_v.substitute(s=I)
        expr_u = expr_u._convert(CC)
        expr_v = expr_v._convert(CC)

        # separate the real and imaginary parts and convert to floats
        u_imag = float(expr_u.imag())
        v_imag = float(expr_v.imag())
        u_real = float(expr_u.real())
        v_real = float(expr_v.real())

        # create a linear time invariant system
        return signal.TransferFunction([u_imag, u_real], [v_imag, v_real])

    def plot_data_omeg_mag(self):
        w, mag_dB, pha = self.data
        return list(zip(w, mag_dB))

    def plot_data_omeg_pha(self):
        w, mag_dB, pha = self.data
        return list(zip(w, pha))

    def plot_data_freq_mag(self):
        f = self.freq
        w, mag_dB, pha = self.data
        return list(zip(f, mag_dB))

    def plot_data_freq_pha(self):
        f = self.freq
        w, mag_dB, pha = self.data
        return list(zip(f, pha))
