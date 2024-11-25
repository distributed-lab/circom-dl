pragma circom 2.1.6;

include "./sha1/sha1.circom";
include "./sha2/sha224/sha224HashChunks.circom";
include "./sha2/sha256/sha256HashChunks.circom";
include "./sha2/sha384/sha384HashChunks.circom";
include "./sha2/sha512/sha512HashChunks.circom";


template ShaHash(BLOCK_SIZE, BLOCK_NUM, ALGO){

    assert(ALGO == 160 || ALGO == 224 || ALGO == 256 || ALGO == 384 || ALGO == 512);

    signal input in[BLOCK_SIZE * BLOCK_NUM];
    signal input dummy;
    signal output out[ALGO];

    if (ALGO == 160) {
        component hash160 = Sha1HashChunks(BLOCK_NUM);
        hash160.in <== in;
        hash160.dummy <== dummy;
        hash160.out ==> out;
        for (var i = 0; i < 160; i++){
            log(out[i]);
        }
    }
    if (ALGO == 224) {
        component hash224 = Sha224HashChunks(BLOCK_NUM);
        hash224.in <== in;
        hash224.dummy <== dummy;
        hash224.out ==> out;
        for (var i = 0; i < 224; i++){
            log(out[i]);
        }
    }
    if (ALGO == 256) {
        component hash256 = Sha256HashChunks(BLOCK_NUM);
        hash256.in <== in;
        hash256.dummy <== dummy;
        hash256.out ==> out;

        for (var i = 0; i < 256; i++){
            log(out[i]);
        }
    }
    if (ALGO == 384) {
        component hash384 = Sha384HashChunks(BLOCK_NUM);
        hash384.in <== in;
        hash384.dummy <== dummy;
        hash384.out ==> out;
        for (var i = 0; i < 384; i++){
            log(out[i]);
        }
    }
    if (ALGO == 512) {
        component hash512 = Sha512HashChunks(BLOCK_NUM);
        hash512.in <== in;
        hash512.dummy <== dummy;
        hash512.out ==> out;
        for (var i = 0; i < 512; i++){
            log(out[i]);
        }
    }

}