# circom-dl

circom-dl is a a library implementing zk cryptographic primitives.

Currently, it supports:
- *bitInt* arithmetic. Used to implement operation of field that is larger than the field size of the underlying curve (e.g. bn128).
- *ec* arithmetic. Elliptic curve operations. Currently supports:
    - brainpoolP256r1
    - brainpoolP384r1
    - secp256r1
    - secp256k1
    - secp384r1
    - *to be continued*

- *hasher*. Implemets different hash functions. Currently supports:
    - SHA1
    - SHA224
    - SHA256
    - SHA384
    - SHA512
    - Poseidon (fixed missing constraints)
    - *to be continued*

- *signatures*. Implemets different signature schemes. Currently supports:
    - ECDSA (on supported curves ^)
    - RSA for any field size, supported hash functions and exponent
    - RSA-PSS
        - SHA384 && SALT_LEN == 48
        - SHA256 && SALT_LEN == 64
        - SHA256 && SALT_LEN == 32
    - *to be continued*


## SETUP

```
npm install
```

## TESTS

```
npm test
```