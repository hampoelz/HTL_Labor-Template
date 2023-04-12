#
# Copyright (c) 2023 Rene Hampölz
#
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file under
# https://github.com/hampoelz/LaTeX-Template.
#

# usage: https://github.com/hampoelz/LaTeX-Science-Template/wiki/02-Usage#printformat-numbers-objects-and-variables

if not 'sage' in globals():
    from sage.all import *

from sage.structure.element import is_Vector, is_Matrix
from sage.libs.pari.convert_sage import gen_to_sage

# beautify and format a number, vector or matrix for the siunitx latex package
def format_object(x, ndigits=None, latexify=True):
    def float_auto_notation(x):
        value = '{:e}'.format(x)
        exponent = value.split('e')[1]
        exponent = int(exponent)
        formatter = 'f'
        if exponent > config_exponent_thresholds_max or exponent < config_exponent_thresholds_min:
            formatter = 'e'
        return formatter

    def strip_float(value):
        if '.' in value:
            value = value.rstrip('0').rstrip('.')
        return value

    def beautify_float(x):
        x = float(x)
        notation = float_auto_notation(x)

        if ndigits != None and ndigits >= 0:
            return '{:.{}{}}'.format(x, ndigits, notation)
        
        value = '{:{}}'.format(x, notation)

        if 'e' in value:
            value_split = value.split('e')
            return strip_float(value_split[0]) + 'e' + value_split[1]
        else:
            return strip_float(value)
    
    def format(x):
        if hasattr(x, 'real') and hasattr(x, 'imag') and x.imag():
            real_format = beautify_float(x.real())
            imag_format = beautify_float(x.imag())
            if float(imag_format) >= 0: imag_format = "+" + imag_format
            
            if not latexify: return real_format + imag_format + "i"
            return "\\num{" + real_format + "}\\num[print-mantissa-implicit-plus]{" + imag_format + "}\\complexnum{i}"

        if not latexify: return beautify_float(x)
        return "\\num{" + beautify_float(x) + "}"
    
    # convert input to sage object
    if not type(x).__module__.startswith('sage'):
        try: x = gen_to_sage(pari(f'{x}'))
        except: return str(x)
    
    if is_Vector(x):
        v = []
        v_latex = ""
        for i in range(len(x)):
            v.append(format(x[i]))
            v_latex += format(x[i])
            v_latex += ',\\,' if i < len(x)-1 else ''
        if not latexify: return str(v)
        return f"\\left({v_latex}\\right)"
    
    if is_Matrix(x):
        m = []
        m_latex = ""
        rows = range(x.nrows())
        cols = range(x.ncols())
        for i in rows:
            m.append([])
            for j in cols:
                m[i].append(format(x[i][j]))
                m_latex += format(x[i][j])
                m_latex += '&' if j < len(cols)-1 else ''
            m_latex += r"\\" if i < len(rows)-1 else ''
        if not latexify: return str(m)
        return "\\left(\\begin{array}{" + 'r'*len(cols) + "}" + m_latex + "\\end{array}\\right)"
    
    if x in ZZ or x in RR or x in QQ or x in CC:
        return format(x)
    
    return latex(x)