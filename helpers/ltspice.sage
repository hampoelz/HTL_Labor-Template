#
# Copyright (c) 2023 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

# usage: https://github.com/hampoelz/LaTeX-Science-Template/wiki/02-Usage#import-ltspice-simulations

import numpy as np
from os import path

class LTSpice:
    @staticmethod
    def get_waveforms(filepath):
        file = open(filepath, "r", encoding="latin-1")
        header = file.readline().strip()
        file.close()
        waveforms = header.split('\t')[1:]
        return waveforms

    @staticmethod
    def plot_data(filename):
        filepath = path.join('../', filename)
        waveforms = LTSpice.get_waveforms(filepath)
        x, y = [], [[] for _ in range(len(waveforms))]

        data = np.genfromtxt(filepath, skip_header=1,
                             delimiter='\t', encoding="latin-1")
        for entry in data:
            if np.isnan(entry[0]):
                continue

            for i in range(len(waveforms)):
                if np.isnan(entry[i + 1]):
                    break
            else:
                x.append(entry[0])
                for i in range(len(waveforms)):
                    y[i].append(entry[i + 1])

        def export(wave_index):
            return list(zip(x, y[wave_index]))

        plot_data = dict()
        for i in range(len(waveforms)):
            plot_data[waveforms[i]] = export(i)
        return plot_data

    @staticmethod
    def plot_data_polar(filename):
        filepath = path.join('../', filename)
        waveforms = LTSpice.get_waveforms(filepath)

        x = []
        mag = [[] for _ in range(len(waveforms))]
        pha = [[] for _ in range(len(waveforms))]

        with open(filepath, "r", encoding="latin-1") as file:
            next(file)  # skip header
            for line in file:
                line = line.strip()
                if not line:
                    continue

                # example: 1.000e+000	(-2.9555e+001dB,8.8075e+001°)
                data = line.split('\t')

                try:
                    _x = float(data[0])
                    _mag = []
                    _pha = []

                    for i in range(len(waveforms)):
                        wave_data = data[i + 1].split(',')
                        _mag.append(float(wave_data[0][1:-2]))
                        _pha.append(float(wave_data[1][:-2]))
                except:
                    continue

                x.append(_x)
                for i in range(len(waveforms)):
                    mag[i].append(_mag[i])
                    pha[i].append(_pha[i])

        def export(wave_index):
            plot_data_mag = list(zip(x, mag[wave_index]))
            plot_data_pha = list(zip(x, pha[wave_index]))
            return plot_data_mag, plot_data_pha

        plot_data = dict()
        for i in range(len(waveforms)):
            plot_data[waveforms[i]] = export(i)
        return plot_data

    @staticmethod
    def plot_data_cartesian(filename):
        filepath = path.join('../', filename)
        waveforms = LTSpice.get_waveforms(filepath)

        x = []
        re = [[] for _ in range(len(waveforms))]
        im = [[] for _ in range(len(waveforms))]

        with open(filepath, "r", encoding="latin-1") as file:
            next(file)  # skip header
            for line in file:
                line = line.strip()
                if not line:
                    continue

                # example: 1.000e+000	1.117687e-003,3.32633e-002
                data = line.split('\t')

                try:
                    _x = float(data[0])
                    _re = []
                    _im = []

                    for i in range(len(waveforms)):
                        wave_data = data[i + 1].split(',')
                        _re.append(float(wave_data[0]))
                        _im.append(float(wave_data[1]))
                except:
                    continue

                x.append(_x)
                for i in range(len(waveforms)):
                    re[i].append(_re[i])
                    im[i].append(_im[i])

        def export(wave_index):
            data_complex = np.array(re[wave_index]) + \
                1j * np.array(im[wave_index])
            data_mag = np.abs(data_complex)
            data_pha = np.angle(data_complex, deg=True)
            plot_data_mag = list(zip(x, data_mag))
            plot_data_pha = list(zip(x, data_pha))
            return plot_data_mag, plot_data_pha

        plot_data = dict()
        for i in range(len(waveforms)):
            plot_data[waveforms[i]] = export(i)
        return plot_data
