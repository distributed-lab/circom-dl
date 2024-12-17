pragma circom 2.1.6;

include "./bigIntFunc.circom";
include "../int/arithmetic.circom";



// Helper templates, don`t use them without understanding what are u doing!
template CheckCarryToZero(CHUNK_SIZE, MAX_CHUNK_SIZE, CHUNK_NUMBER) {
    assert(CHUNK_NUMBER >= 2);
    
    var EPSILON = 3;
    
    assert(MAX_CHUNK_SIZE + EPSILON <= 253);
    
    signal input in[CHUNK_NUMBER];
    
    signal carry[CHUNK_NUMBER];
    component carryRangeChecks[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER - 1; i++){
        carryRangeChecks[i] = Num2Bits(MAX_CHUNK_SIZE + EPSILON - CHUNK_SIZE);
        if (i == 0){
            carry[i] <== in[i] / 2 ** CHUNK_SIZE;
        }
        else {
            carry[i] <== (in[i] + carry[i - 1]) / 2 ** CHUNK_SIZE;
        }
        carryRangeChecks[i].in <== carry[i] + (2 ** (MAX_CHUNK_SIZE + EPSILON - CHUNK_SIZE - 1));
    }
    in[CHUNK_NUMBER - 1] + carry[CHUNK_NUMBER - 2] === 0;
}

// 

template BigMultModPOpt(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    signal input modulus[CHUNK_NUMBER];
    signal input dummy;
    
    signal output div[CHUNK_NUMBER + 1];
    signal output mod[CHUNK_NUMBER];
    
    
    component mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult.in <== in;
    mult.dummy <== dummy;


    
    var reduced[200] = reduce_overflow(CHUNK_SIZE, 2 * CHUNK_NUMBER - 1, CHUNK_NUMBER * 2, mult.out);
    for (var i = 0; i < 8; i++){
        log(reduced[i]);
    }
    var long_division[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, reduced, modulus);
    
    for (var i = 0; i < CHUNK_NUMBER + 1; i++){
        div[i] <-- long_division[0][i];
        log(div[i]);

    }
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        mod[i] <-- long_division[1][i];
        log(mod[i]);

    }
    
    component greaterThan = BigGreaterThan(CHUNK_SIZE, CHUNK_NUMBER);
    
    greaterThan.in[0] <== modulus;
    greaterThan.in[1] <== mod;
    greaterThan.out === 1;
    
    component mult2 = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER + 1);
    mult2.in[0] <== div;
    for (var i = 0; i < CHUNK_NUMBER; i++){
        mult2.in[1][i] <== modulus[i];
    }
    mult2.in[1][CHUNK_NUMBER] <== 0;
    mult2.dummy <== dummy;
    
    mult2.out[CHUNK_NUMBER * 2 - 1] === 0;
    mult2.out[CHUNK_NUMBER * 2] === 0;
    
    component checkCarry = CheckCarryToZero(CHUNK_SIZE, CHUNK_SIZE * 2 + log_ceil(CHUNK_NUMBER), CHUNK_NUMBER * 2 - 1);
    for (var i = 0; i < CHUNK_NUMBER; i++) {
        checkCarry.in[i] <== mult.out[i] - mult2.out[i] - mod[i];
    }
    for (var i = CHUNK_NUMBER; i < CHUNK_NUMBER * 2 - 1; i++) {
        checkCarry.in[i] <== mult.out[i] - mult2.out[i];
    }
}