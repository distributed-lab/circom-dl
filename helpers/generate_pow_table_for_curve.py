import math
import sys

P = 0xfffffffffffffffffffffffffffffffeffffffffffffffff
A = 0xfffffffffffffffffffffffffffffffefffffffffffffffc
B = 0x64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1
Gx = 0x188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012
Gy = 0x07192b95ffc8da78631011ed6b24cdd573f977a11e794811

def egcd(a, b):
    if a == 0:
        return (b, 0, 1)
    else:
        g, y, x = egcd(b % a, a)
        return (g, x - (b // a) * y, y)


def modinv(a, m):
    g, x, y = egcd(a, m)
    if g != 1:
        raise Exception('modular inverse does not exist')
    else:
        return x % m


def double(x, y):
    lamb = ((3 * (x ** 2) + A) * modinv(2 * y, P)) % P
    retx = (lamb ** 2 - 2 * x) % P
    rety = (lamb * (x - retx) - y) % P
    return retx, rety


def add(x1, y1, x2, y2):
    lamb = ((y2 - y1) * modinv(P + x2 - x1, P)) % P
    retx = (P + lamb ** 2 - x1 - x2) % P
    rety = (P + lamb * (x1 - retx) - y1) % P
    return retx, rety


def get_g_pows(exp):
    g_pows = []
    curr_x, curr_y = Gx, Gy
    for idx in range(exp):
        g_pows.append((curr_x, curr_y))
        curr_x, curr_y = double(curr_x, curr_y)
    return g_pows


def get_long(n, k, x):
    ret = []
    for idx in range(k):
        ret.append(x % (2 ** n))
        x = x // (2 ** n)
    return ret


def get_long_g_pows(exp, n, k):
    g_pows = get_g_pows(exp)
    long_g_pows = []
    for x, y in g_pows:
        long_x, long_y = get_long(n, k, x), get_long(n, k, y)
        long_g_pows.append((long_x, long_y))
    return long_g_pows


def get_binary(x):
    ret = []
    while x > 0:
        ret.append(x % 2)
        x = x // 2
    return ret

def get_g_pow_val(g_pows, exp):
    binary = get_binary(exp)
    is_nonzero = False
    curr_sum = None
    for idx, val in enumerate(binary):
        if val != 0:
            if not is_nonzero:
                is_nonzero = True
                curr_sum = g_pows[idx]
            else:
                curr_sum = add(curr_sum[0], curr_sum[1],
                               g_pows[idx][0], g_pows[idx][1])
    return curr_sum


def get_cache_str(n, k, stride, curve_name):
    num_strides = math.ceil(n * k / stride)
    stride_cache_size = 2 ** stride
    ret_str = '''
function get_g_pow_stride{stride}_table_{curve}(n, k) '''.format(stride = stride, curve = curve_name)
    ret_str = ret_str + '{'
    ret_str = ret_str + '''
    assert(n == {} && k == {});
    var powers[{}][{}][2][{}];
'''.format(n, k, num_strides, 2 ** stride, k)
    EXP = 521 + stride
    g_pows = get_g_pows(EXP)

    for stride_idx in range(num_strides):
        for idx in range(2 ** stride):
            exp = idx * (2 ** (stride_idx * stride))
            ret_append = '\n'
            if exp > 0:
                g_pow = get_g_pow_val(g_pows, exp)
                long_g_pow = get_long(n, k, g_pow[0]), get_long(n, k, g_pow[1])
                for reg_idx in range(k):
                    ret_append += '    powers[{}][{}][0][{}] = {};\n'.format(
                        stride_idx, idx, reg_idx, long_g_pow[0][reg_idx])
                for reg_idx in range(k):
                    ret_append += '    powers[{}][{}][1][{}] = {};\n'.format(
                        stride_idx, idx, reg_idx, long_g_pow[1][reg_idx])
            elif exp == 0:
                for reg_idx in range(k):
                    ret_append += '    powers[{}][{}][0][{}] = 0;\n'.format(
                        stride_idx, idx, reg_idx)
                for reg_idx in range(k):
                    ret_append += '    powers[{}][{}][1][{}] = 0;\n'.format(
                        stride_idx, idx, reg_idx)
            ret_str = ret_str + ret_append
    ret_str = ret_str + '''
    return powers;
}
'''
    return ret_str


def get_ecdsa_func_str(n, k, stride_list, curve_name):
    ret_str = '''pragma circom 2.1.6;
'''
    for stride in stride_list:
        cache_str = get_cache_str(n, k, stride, curve_name)
        ret_str = ret_str + cache_str
    return ret_str


def write_to_file(curve_name):
    stride_list = [8]
    ecdsa_func_str = get_ecdsa_func_str(64, 4, stride_list)
    with open('./tmp.circom', 'w') as file:
        file.write(ecdsa_func_str)

write_to_file()
