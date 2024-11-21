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

    powers = {"powers": [], "dummy": 0, "in":[get_long_str(64, 4, Gx), get_long_str(64, 4, Gy)], "scalar": get_long_str(64, 4, scalar)}

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
    ecdsa_func_str = get_cache_json(64, 4, 8)
    file_name = "input_mult.json"

    with open(file_name, "w") as file:
        file.write(ecdsa_func_str)


Gx = 52575969560191351534542091466380106041028581718640875237441073011616025668110
Gy = 24843789797109572893402439557748964186754677981311543350228155441542769376468
P = 0xa9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377
A = 0x7d5a0975fc2c3057eef67530417affe7fb8055c126dc5c6ce94a4b44f330b5d9
B = 0x26dc5c6ce94a4b44f330b5d9bbd77cbf958416295cf7e1ce6bccdc18ff8c07b6
scalar = 0x2364528376458237645823648273648232342342342342342342342342341233
write_to_file()