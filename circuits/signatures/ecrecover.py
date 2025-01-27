import random
import math
from dataclasses import dataclass

def bigint_to_array(n, k, x):
    # Initialize mod to 1 (Python's int can handle arbitrarily large numbers)
    mod = 1
    for idx in range(n):
        mod *= 2

    # Initialize the return list
    ret = []
    x_temp = x
    for idx in range(k):
        # Append x_temp mod mod to the list
        ret.append(str(x_temp % mod))
        # Divide x_temp by mod for the next iteration
        x_temp //= mod  # Use integer division in Python

    return ret

def on_curve(x1, y1, a,b,p):
    return (x1**3 + a*x1 + b)% p == y1**2%p

def point_double(x1, y1, a, p):
    if y1 == 0:
        # Point at infinity (edge case for doubling)
        return None, None

    # Calculate λ (lambda)
    lambda_num = (3 * x1 * x1 + a) % p
    lambda_den = mod_inverse(2 * y1, p)  # Modular inverse of 2*y1 mod p
    lam = (lambda_num * lambda_den) % p

    # Calculate x3 and y3
    x3 = (lam * lam - 2 * x1) % p
    y3 = (lam * (x1 - x3) - y1) % p

    return x3, y3

def point_scalar_mul(x, y, k, a, p):
    x_res, y_res = None, None  

    x_cur, y_cur = x, y

    while k > 0:
        if k & 1:
            if x_res is None and y_res is None:
                x_res, y_res = x_cur, y_cur
            else:
                x_res, y_res = point_add(x_res, y_res, x_cur, y_cur, p)

        x_cur, y_cur = point_double(x_cur, y_cur, a, p)

        k >>= 1

    return x_res, y_res

def mod_inverse(a, m):
    m0, x0, x1 = m, 0, 1
    while a > 1:
        q = a // m
        m, a = a % m, m
        x0, x1 = x1 - q * x0, x0
    if x1 < 0:
        x1 += m0
    return x1

#new
def point_add(x1, y1, x2, y2, p: int):
    # Handle point at infinity
    if x1 == x2 and y1 != y2:
        return None
        
    if (x1 != x2 and y1 != y2):
        # Point addition formula
        lam = ((y2 - y1) * pow(x2 - x1, -1, p)) % p
    else:
        # Point doubling formula
        lam = ((3 * x1 * x1) * pow(2 * y1, -1, p)) % p
        
    x3 = (lam * lam - x1 - x2) % p
    y3 = (lam * (x1 - x3) - y1) % p
    
    return x3, y3

def point_neg(x, y, p: int):
    return (x, (-y) % p)

def recover_public_key(z: int, r: int, s: int, Rx: int, Ry: int, Gx: int, Gy: int, n: int, p: int):
    # Check inputs are in valid range
    if not (0 < r < n and 0 < s < n):
        raise ValueError("Invalid signature values")
    
    # 1. Calculate r⁻¹ mod n
    r_inv = pow(r, -1, n)
    
    # 2. Calculate sR
    sR_x, sR_y = point_scalar_mul( Rx, Ry, s, a, p)
    
    # 3. Calculate zG
    zG_x, zG_y = point_scalar_mul(Gx, Gy, z, a, p)
    
    # 4. Calculate sR - zG
    # We need to subtract zG, which means adding its negative
    neg_zG_x, neg_zG_y = point_neg(zG_x, zG_y, p)

    sR_minus_zG_x, sR_minus_zG_y = point_add(sR_x, sR_y, neg_zG_x, neg_zG_y, p) 
    
    # 5. Finally multiply by r⁻¹
    Qx, Qy = point_scalar_mul(sR_minus_zG_x, sR_minus_zG_y, r_inv, a, p)
    
    return Qx, Qy

def ecrecover(r, s, z, v, a, b, p, n, Gx, Gy):
    if not (0 < r < p):
        raise ValueError("Wrong r")

    Rx = r

    alpha = (pow(Rx, 3, p) + Rx * a + b) % p

    # Calculate y using Fermat's little theorem
    # Since p ≡ 3 (mod 4), we can use (p+1)/4 exponent
    Ry = pow(alpha, (p + 1) // 4, p)

    # Check if we found valid solution
    if (Ry * Ry) % p != alpha:
        return None

    if (Ry % 2) != v:
        Ry = p - Ry

    print(bigint_to_array(64, 4, Rx), bigint_to_array(64, 4, p - Ry))

    Qx, Qy = recover_public_key(z, r, s, Rx, Ry, Gx, Gy, n, p)

    return Qx, Qy

def verify_signature(r, s, z, Px, Py, a, p, n, Gx, Gy):
    if not (1 <= r < n and 1 <= s < n):
        return False  # Invalid signature components

    # Step 1: Compute w = s^-1 mod n
    w = mod_inverse(s, n)

    # Step 2: Compute u1 and u2
    u1 = (z * w) % n
    u2 = (r * w) % n

    # Step 3: Calculate u1 * G and u2 * P
    x1, y1 = point_scalar_mul(Gx, Gy, u1, a, p)
    x2, y2 = point_scalar_mul(Px, Py, u2, a, p)

    # Step 4: Add the results to get X
    Xx, Xy = point_add(x1, y1, x2, y2, p)

    # Step 5: Verify r ≡ Xx mod n
    return Xx % n == r

def ecdsa_sign(z, d, a, p, n, Gx, Gy):
    while True:
        k = random.randint(1, n - 1)

        # Step 2: Compute R = k * G and r = Rx mod n
        Rx, Ry = point_scalar_mul(Gx, Gy, k, a, p)

        #if Ry is even, v is 1, 0 otherwise
        v = 1 - Ry % 2

        r = Rx % n

        # If r == 0, restart the process
        if r == 0:
            continue

        # Step 3: Compute k^-1 mod n
        k_inv = mod_inverse(k, n)

        # Step 4: Compute s = k^-1 * (z + r * d) mod n
        s = (k_inv * (z + r * d)) % n

        # If s == 0, restart the process
        if s == 0:
            continue

        # Return the signature (v, r, s)
        return v, r, s

# Curve params
p = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
a = 0x0000000000000000000000000000000000000000000000000000000000000000
b = 0x0000000000000000000000000000000000000000000000000000000000000007
Gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
Gy = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141

priv = 0xaa9ba9e840d90f125898594beeabd258eb7834d6b19aba6ae81e8ce35a168e8d
addr = 0x3ba50ab507a9fc3b1e2b3cdfaf82cf3ab2cb1360

# message hash
h = 0xb71de80778f2783383f5d5a3028af84eab2f18a4eb38968172ca41724dd4b3f4


c1 = 0
c2 = 0
c3 = 0

# for i in range(2 ** 4):
#     v, r, s = ecdsa_sign(h, priv, a, p, n, Gx, Gy)

x = 0xe3c268f54bbccbc1394d632631d6c0c9bd545c2beb697f3ac6aee7b79e92d033
y = 0x20d88d223a33af0770a1abb704703d9f38b6be3d5ce703916f7bd1005e3e294e
#     print(v)
#     print(bigint_to_array(64, 4, r))
#     print(bigint_to_array(64, 4, s))

#     if verify_signature(r, s, h, x, y, a, p, n, Gx, Gy):
#         c1 += 1


#     s_inverse = (-s)+n

#     Px2, Py2 = ecrecover(r, s_inverse, h, v, a, b, p, n, Gx, Gy)

#     print(hex(Px2), hex(Py2))

#     if verify_signature(r, s, h, Px2, Py2, a, p, n, Gx, Gy): 
#         c2 += 1

#     if Px2 == x:
#         c3 += 1

# print("Correct signature for real pubkey: ", c1)
# print("Correct signature for recovered pubkey: ", c2)
# print("Same pubkeys: ", c3)

r0 = [11764402101905465638, 9938196456302562730, 6253620195890046865, 15351490062046210307]
r0 = r0[0] + r0[1] * 2 ** 64 + r0[2] * 2**128 + r0[3] * 2**192

s0 = [18261103155045323801, 18289651814321197529, 13151725195261714974, 2860684551577994836]
s0 = s0[0] + s0[1] * 2 ** 64 + s0[2] * 2**128 + s0[3] * 2**192

r1 = [532805251999948763, 14509534743349949197, 6939508870230086889, 17024273808959028591]
r1 = r1[0] + r1[1] * 2 ** 64 + r1[2] * 2**128 + r1[3] * 2**192

s1 = [12457118677736780357, 16913942446463045717, 4125971028903520594, 10501105102363837523]
s1 = s1[0] + s1[1] * 2 ** 64 + s1[2] * 2**128 + s1[3] * 2**192

s_inverse = (-s0)+n
Px0, Py0 = ecrecover(r0, s_inverse, h, 0, a, b, p, n, Gx, Gy)

s_inverse = (-s1)+n
Px1, Py1 = ecrecover(r1, s_inverse, h, 1, a, b, p, n, Gx, Gy)

# print(verify_signature(r0, s0, h, Px0, Py0, a, p, n, Gx, Gy))
# print(verify_signature(r1, s1, h, Px1, Py1, a, p, n, Gx, Gy))

print(bigint_to_array(64, 4, x))
print(bigint_to_array(64, 4, y))
