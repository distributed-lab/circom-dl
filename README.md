# circom-dl

circom-dl is a a library implementing zk cryptographic primitives.

Currently, it supports:
- *bitInt* arithmetic. Used to implement operation of field that is larger than the field size of the underlying curve (e.g. bn128).
- *ec* arithmetic. Weierstrass elliptic curve operations. Non supported Weierstrass curves can be easily added by following instructions in curve.circom. Currently supports:
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
<<<<<<< HEAD
    - secp521r1
=======
>>>>>>> origin/dev
    - *to be continued*


- *hasher*. Implemets different hash functions. Currently supports:
    - SHA1
    - SHA224
    - SHA256
    - SHA384
    - SHA512
<<<<<<< HEAD
    - Keccak256
    - Poseidon
=======
    - Poseidon (fixed missing constraints)
>>>>>>> origin/dev
    - *to be continued*

- *signatures*. Implemets different signature schemes. Currently supports:
    - ECDSA (on supported curves ^)
    - RSA for any field size, supported hash functions (Only sha1 and sha2-256 for now) and exponent
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