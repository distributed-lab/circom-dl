# circom-dl

circom-dl is a a library implementing zk cryptographic primitives.

Currently, it supports:
- *bitInt* arithmetic. Used to implement operation of field that is larger than the field size of the underlying curve (e.g. bn128).
- *ec* arithmetic. Weierstrass elliptic curve over prime field operations. Non supported Weierstrass curves over prime field can be easily added by following instructions in curve.circom. Currently supports:
    - brainpool224r1
    - brainpoolP256r1
    - brainpoolP320r1
    - brainpoolP384r1
    - brainpoolP512r1
    - secp192r1
    - secp224r1
    - secp256r1
    - secp256k1
    - secp384r1
    - secp521r1
    - *to be continued*

- *babyjubjub* arithmetic. Used for curve with the same field as circom field (subgroup of bn128).
- *hasher*. Implemets different hash functions. Currently supports:
    - SHA1
    - SHA224
    - SHA256
    - SHA384
    - SHA512
    - Keccak256
    - Poseidon
    - *to be continued*

- *signatures*. Implemets different signature schemes. Currently supports:
    - ECDSA (on supported curves ^)
    - RSA with Pkcs1v15 padding for any field size, supported hash functions (Only sha1 and sha2-256 for now) and any exponent
    - RSA-PSS
        - SHA384 && SALT_LEN == 48
        - SHA256 && SALT_LEN == 64
        - SHA256 && SALT_LEN == 32
        - SHA512 && SALT_LEN == 64
    - *to be continued*

- *eth*. Impements exracting eth address from public key.
- *float*. Implements fixed point float numbers.  Currently supports:
    - Multiplication (both with and without ceiling)
    - Inverse
    - Exp
    - Switch precision.

- *matrix*. Implements matrix arithmetic. Currently supports:
    - Multiplication
    - Scalar multiplication
    - Hadamard product
    - Addition
    - Transposition
    - Determinant
    - Matrix Power

- *utils*. Some helper templates to make some base operations easier. Currently supports:
    - Switcher

- *int*. Implements some int arithmetic for nums < underlying field(e.g. bn128). Currently supports:
    - Inverse
    - Log
    - Sum of n elements
    - Other templates can be unsecure, never use them in produnction!

## SETUP

```
npm install
```

## TESTS

```
npm test
```
