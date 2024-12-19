pragma circom 2.1.6;

include "./bigInt.circom";
include "./bigIntOverflow.circom";
include "./bigModOptimisation.circom";

// Here are wrappers for templates that support optimisation for edge cases, use them.
//----------------------------------------------------------------------------------------------------------------------------------
// in[0] * in[1] % modulus, all have same CHUNK_NUMBER
template BigMultModPWrapper(CHUNK_SIZE, CHUNK_NUMBER){
    var isPowerOfTwo = 0;
    for (var i = 0; i < CHUNK_NUMBER; i++){
        if (CHUNK_NUMBER == 2 ** i){
            isPowerOfTwo = 1;
        }
    }
    signal input in[2][CHUNK_NUMBER];
    signal input modulus[CHUNK_NUMBER];
    signal input dummy;

    signal output mod[CHUNK_NUMBER];
    signal output div[CHUNK_NUMBER + 1];
    
    if (isPowerOfTwo == 1 && CHUNK_NUMBER >= 8){
        component bigMultModPKaratsubaOpt = BigMultModPKaratsubaOpt(CHUNK_SIZE, CHUNK_NUMBER);
        bigMultModPKaratsubaOpt.in <== in;
        bigMultModPKaratsubaOpt.modulus <== modulus;
        bigMultModPKaratsubaOpt.dummy <== dummy;
        
        bigMultModPKaratsubaOpt.mod ==> mod;
        bigMultModPKaratsubaOpt.div ==> div;
    } else {
        component bigMultModPOpt = BigMultModPOpt(CHUNK_SIZE, CHUNK_NUMBER);
        bigMultModPOpt.in <== in;
        bigMultModPOpt.modulus <== modulus;
        bigMultModPOpt.dummy <== dummy;
        
        bigMultModPOpt.mod ==> mod;
        bigMultModPOpt.div ==> div;
    }
}

// in[0] * in[1] % modulus, all have different CHUNK_NUMBER
template BigMultModPNonEqualWrapper(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS, CHUNK_NUMBER_MODULUS){
    
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input modulus[CHUNK_NUMBER_MODULUS];
    signal input dummy;
    
    var CHUNK_NUMBER_BASE = CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS;
    var CHUNK_NUMBER_DIV = CHUNK_NUMBER_BASE - CHUNK_NUMBER_MODULUS + 1;

    signal output div[CHUNK_NUMBER_DIV];
    signal output mod[CHUNK_NUMBER_MODULUS];
    
    component bigMultModPOptNonEqual = BigMultModPOptNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS, CHUNK_NUMBER_MODULUS);
    bigMultModPOptNonEqual.in1 <== in1;
    bigMultModPOptNonEqual.in2 <== in2;
    bigMultModPOptNonEqual.modulus <== modulus;
    bigMultModPOptNonEqual.dummy <== dummy;
    
    bigMultModPOptNonEqual.mod ==> mod;
    bigMultModPOptNonEqual.div ==> div;
    
}

// in[0] * in[1] without overflows
template BigMultWrapper(CHUNK_SIZE, CHUNK_NUMBER) {
    var isPowerOfTwo = 0;
    for (var i = 0; i < CHUNK_NUMBER; i++){
        if (CHUNK_NUMBER == 2 ** i){
            isPowerOfTwo = 1;
        }
    }
    signal input dummy;
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER * 2];
    
    if (isPowerOfTwo != 1){
        component bigMult = BigMult(CHUNK_SIZE, CHUNK_NUMBER);
        bigMult.in <== in;
        bigMult.dummy <== dummy;
        bigMult.out ==> out;
    } else {
        component bigMultOptimised = BigMultOptimised(CHUNK_SIZE, CHUNK_NUMBER);
        bigMultOptimised.in <== in;
        bigMultOptimised.dummy <== dummy;
        bigMultOptimised.out ==> out;
    }
}

// in[0] * in[1] with overflow
template BigMultOverflowWrapper(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    signal output out[CHUNK_NUMBER * 2 - 1];

    var isPowerOfTwo = 0;
    for (var i = 0; i < CHUNK_NUMBER; i++){
        if (CHUNK_NUMBER == 2 ** i){
            isPowerOfTwo = 1;
        }
    }

    if (isPowerOfTwo == 1) {
        component bigMultOptimisedOverflow = BigMultOptimisedOverflow(CHUNK_SIZE, CHUNK_NUMBER);
        bigMultOptimisedOverflow.in <== in;
        bigMultOptimisedOverflow.dummy <== dummy;
        bigMultOptimisedOverflow.out ==> out;
    } else {
        component bigMultOverflow = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
        bigMultOverflow.in <== in;
        bigMultOverflow.dummy <== dummy;
        bigMultOverflow.out ==> out;
    }
}