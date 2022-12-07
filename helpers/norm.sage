from sage.structure.element import is_Vector, is_Matrix


def norm(x, n=None):
    # convert number to decimal or scientific format based on complexity
    def general_format(x): return '{:g}'.format(float(x))

    # calculate digits of a number to the right and left of the decimal point
    def numerical_approx_length(x):
        value = general_format(x)
        if 'e' in value:
            value = value.split('e')[0]
        length = [len(value), 1]  # 1 = default number of decimal places
        if '.' in value:
            value = value.split('.')
            r_len = 0 if value[0] == '0' else len(value[0])
            l_len = n or len(value[1])  # Use custom 'n' decimals if defined
            length = [r_len, l_len]
        return length

    # calculate digits of a complex number or a number
    def approx_length(x):
        if hasattr(x, 'real') and hasattr(x, 'imag') and x.imag():
            # The real and imaginary parts of a complex number have the same number of decimal places,
            # so that no decimals are truncated later, the part with the most digits is used
            len_real = numerical_approx_length(x.real())
            len_imag = numerical_approx_length(x.imag())
            return max(len_real[0], len_imag[0]) + max(len_real[1], len_imag[1])
        return sum(numerical_approx_length(x))

    # format a number for better readability
    def approx(x, length=None, allow_str=False):
        if not length:
            length = approx_length(x)

        # handle complex numbers
        if hasattr(x, 'real') and hasattr(x, 'imag') and x.imag():
            return numerical_approx(x, digits=length)

        # handle numbers
        # converting to the general format has some disadvantages:
        # - accepts only data types that can be cast to float
        # - causes problems with vectors and matrices, which do not accept strings
        # - decimals are truncated depending on complexity (problematic when 'n' of decimals are desired)
        # - the scientific form of numbers is not correctly rendered in LaTeX
        # therefore, the number is only converted if the above problems do not apply
        value = general_format(x)
        if allow_str and not n and 'e' not in value:
            return value

        return numerical_approx(x, digits=length)

    # handle vectors
    if is_Vector(x):
        v, v_len = [], []
        # use the point with the most digits since each point will have the same number of decimal places in the vector
        for i in range(len(x)):
            v_len.append(approx_length(x[i]))
        # beautify every point of the vector and create a new vector
        for i in range(len(x)):
            v.append(approx(x[i], length=max(v_len)))
        return vector(v)

    # handle matrices
    if is_Matrix(x):
        m, m_len = [], []
        # use the point with the most digits since each point will have the same number of decimal places in the matrix
        for i in range(x.nrows()):
            for j in range(x.ncols()):
                m_len.append(approx_length(x[i][j]))
        # beautify every point of the matrix and create a new matrix
        for i in range(x.nrows()):
            m.append([])
            for j in range(x.ncols()):
                m[i].append(approx(x[i][j], length=max(m_len)))
        return matrix(m)

    # handle numbers
    return approx(x, allow_str=True)
