pragma circom 2.1.6;

include "../bigInt/bigInt.circom";
include "../bitify/bitify.circom";


template RsaVerifyPkcs1v15(CHUNK_SIZE, CHUNK_NUMBER, E_BITS, HASH_TYPE) {
    signal input signature[CHUNK_NUMBER];
    signal input pubkey[CHUNK_NUMBER]; 
    signal input hashed[HASH_TYPE];
    
    signal input dummy;
    dummy * dummy === 0;
    
    // signature ** exp mod modulus
    component pm = PowerMod(CHUNK_SIZE, CHUNK_NUMBER, E_BITS);
    pm.dummy <== dummy;
    for (var i = 0; i < CHUNK_NUMBER; i++) {
        pm.base[i] <== signature[i];
        pm.modulus[i] <== pubkey[i];
    }
    
    signal hashed_chunks[4];
    
    component bits2num[4];
    for (var i = 0; i < 4; i++){
        bits2num[3 - i] = Bits2Num(64);
        for (var j = 0; j < 64; j++){
            bits2num[3 - i].in[j] <== hashed[i * 64 + 63 - j];
        }
        bits2num[3 - i].out ==> hashed_chunks[3 - i];
    }
    
    // 1. Check hashed data
    for (var i = 0; i < 4; i++) {
        hashed_chunks[i] === pm.out[i];
    }
    
    // 2. Check hash prefix and 1 byte 0x00
    pm.out[4] === 217300885422736416;
    pm.out[5] === 938447882527703397;
    
    // remain 24 bit
    component num2bits_6 = Num2Bits(CHUNK_SIZE);
    num2bits_6.in <== pm.out[6];
    var remainsBits[32] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0];
    for (var i = 0; i < 32; i++) {
        num2bits_6.out[i] === remainsBits[31 - i];
    }
    
    // 3. Check PS and em[1] = 1
    for (var i = 32; i < CHUNK_SIZE; i++) {
        num2bits_6.out[i] === 1;
    }
    
    for (var i = 7; i < CHUNK_NUMBER - 1; i++) {
        pm.out[i] === 18446744073709551615; 
    }
}
