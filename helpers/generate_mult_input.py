import math
import json

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



def get_long_str(n, k, x):
    ret = []
    for idx in range(k):
        ret.append(str(x % (2 ** n)))
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

def get_cache_json(n, k, stride):
    num_strides = math.ceil(n * k / stride)
    stride_cache_size = 2 ** stride
    EXP = 512 + stride
    g_pows = get_g_pows(EXP)

    powers = {"powers": [], "dummy": 0, "in":[get_long_str(n, k, Gx), get_long_str(n, k, Gy)], "scalar": get_long_str(n, k, scalar)}

    for stride_idx in range(num_strides):
        stride_data = []
        for idx in range(2 ** stride):
            exp = idx * (2 ** (stride_idx * stride))
            if exp > 0:
                g_pow = get_g_pow_val(g_pows, exp)
                long_g_pow = get_long(n, k, g_pow[0]), get_long(n, k, g_pow[1])
                stride_entry = [
                    [str(long_g_pow[0][reg_idx]) for reg_idx in range(k)],
                    [str(long_g_pow[1][reg_idx]) for reg_idx in range(k)]
                ]
            elif exp == 0:
                stride_entry = [
                    [0 for _ in range(k)], 
                    [0 for _ in range(k)]  
                ]
            stride_data.append(stride_entry)
        powers["powers"].append(stride_data)

    return json.dumps(powers, indent=4)


def write_to_file():
    ecdsa_func_str = get_cache_json(64, 6, 8)
    file_name = "input_mult.json"

    with open(file_name, "w") as file:
        file.write(ecdsa_func_str)


P = 0x8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b412b1da197fb71123acd3a729901d1a71874700133107ec53
A = 0x7bc382c63d8c150c3c72080ace05afa0c2bea28e4fb22787139165efba91f90f8aa5814a503ad4eb04a8c7dd22ce2826
B = 0x4a8c7dd22ce28268b39b55416f0447c2fb77de107dcd2a62e880ea53eeb62d57cb4390295dbc9943ab78696fa504c11
Gx = 0x1d1c64f068cf45ffa2a63a81b7c13f6b8847a3e77ef14fe3db7fcafe0cbd10e8e826e03436d646aaef87b2e247d4af1e
Gy = 0x8abe1d7520f9c2a45cb1eb8e95cfd55262b70b29feec5864e19c054ff99129280e4646217791811142820341263c5315
scalar = 0x2364528376458237645823648273648232342342342342342342342342341233
write_to_file()