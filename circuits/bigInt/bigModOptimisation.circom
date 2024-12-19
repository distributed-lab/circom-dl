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

// for CHUNK_NUMBER != 2 ** n
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

    var long_division[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, reduced, modulus);
    
    for (var i = 0; i < CHUNK_NUMBER + 1; i++){
        div[i] <-- long_division[0][i];

    }
    component modChecks[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        mod[i] <-- long_division[1][i];
        // Check to avoid negative numbers
        modChecks[i] = Num2Bits(CHUNK_SIZE);
        modChecks[i].in <== mod[i];

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

// for CHUNK_NUMBER == 2 ** n
template BigMultModPKaratsubaOpt(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    signal input modulus[CHUNK_NUMBER];
    signal input dummy;
    
    signal output div[CHUNK_NUMBER + 1];
    signal output mod[CHUNK_NUMBER];
    
    component mult = KaratsubaNoCarry(CHUNK_NUMBER);
    mult.in <== in;
    mult.dummy <== dummy;

    var reduced[200] = reduce_overflow(CHUNK_SIZE, 2 * CHUNK_NUMBER - 1, CHUNK_NUMBER * 2, mult.out);

    var long_division[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, reduced, modulus);
    
    for (var i = 0; i < CHUNK_NUMBER + 1; i++){
        div[i] <-- long_division[0][i];

    }
    component modChecks[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        mod[i] <-- long_division[1][i];
        // Check to avoid negative numbers
        modChecks[i] = Num2Bits(CHUNK_SIZE);
        modChecks[i].in <== mod[i];

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

// for different CHUNK_NUMBER
template BigMultModPOptNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS, CHUNK_NUMBER_MODULUS){
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input modulus[CHUNK_NUMBER_MODULUS];
    signal input dummy;
    
    var CHUNK_NUMBER_BASE = CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS;
    var CHUNK_NUMBER_DIV = CHUNK_NUMBER_BASE - CHUNK_NUMBER_MODULUS + 1;

    signal output div[CHUNK_NUMBER_DIV];
    signal output mod[CHUNK_NUMBER_MODULUS];
    
    
    component mult = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS);
    mult.in1 <== in1;
    mult.in2 <== in2;
    mult.dummy <== dummy;


    
    var reduced[200] = reduce_overflow(CHUNK_SIZE, CHUNK_NUMBER_BASE - 1, CHUNK_NUMBER_BASE, mult.out);

    var long_division[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV - 1, reduced, modulus);
    
    for (var i = 0; i < CHUNK_NUMBER_DIV; i++){
        div[i] <-- long_division[0][i];

    }
    component modChecks[CHUNK_NUMBER_MODULUS];
    for (var i = 0; i < CHUNK_NUMBER_MODULUS; i++){
        mod[i] <-- long_division[1][i];
        // Check to avoid negative numbers
        modChecks[i] = Num2Bits(CHUNK_SIZE);
        modChecks[i].in <== mod[i];

    }
    
    component greaterThan = BigGreaterThan(CHUNK_SIZE, CHUNK_NUMBER_MODULUS);
    
    greaterThan.in[0] <== modulus;
    greaterThan.in[1] <== mod;
    greaterThan.out === 1;
    
    component mult2;
    if (CHUNK_NUMBER_DIV >= CHUNK_NUMBER_MODULUS){
        mult2 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER_DIV, CHUNK_NUMBER_MODULUS);
        
        mult2.in1 <== div;
        mult2.in2 <== modulus;
        mult2.dummy <== dummy;
    } else {
        mult2 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV);
        
        mult2.in2 <== div;
        mult2.in1 <== modulus;
        mult2.dummy <== dummy;
    }

    for (var i = CHUNK_NUMBER_BASE - 1; i < CHUNK_NUMBER_MODULUS + CHUNK_NUMBER_DIV - 1; i++){
        mult2.out[i] === 0;
    }
    
    component checkCarry = CheckCarryToZero(CHUNK_SIZE, CHUNK_SIZE * 2 + log_ceil(CHUNK_NUMBER_MODULUS + CHUNK_NUMBER_DIV - 1), CHUNK_NUMBER_BASE - 1);
    for (var i = 0; i < CHUNK_NUMBER_MODULUS; i++) {
        checkCarry.in[i] <== mult.out[i] - mult2.out[i] - mod[i];
    }
    for (var i = CHUNK_NUMBER_MODULUS; i < CHUNK_NUMBER_BASE - 1; i++) {
        checkCarry.in[i] <== mult.out[i] - mult2.out[i];
    }
}

// for base chunk number = 2 * CHUNK_NUMBER
template BigModOpt(CHUNK_SIZE, CHUNK_NUMBER){
    signal input base[CHUNK_NUMBER * 2];
    signal input modulus[CHUNK_NUMBER];
    signal input dummy;

    signal output div[CHUNK_NUMBER + 1];
    signal output mod[CHUNK_NUMBER];
    
    
    component modNonEqual = BigModNonEqualOpt(CHUNK_SIZE, CHUNK_NUMBER * 2, CHUNK_NUMBER);
    modNonEqual.base <== base;
    modNonEqual.modulus <== modulus;
    modNonEqual.dummy <== dummy;
    modNonEqual.div ==> div;
    modNonEqual.mod ==> mod;

}

// for any CHUNK_NUMBER for base and modulus
template BigModNonEqualOpt(CHUNK_SIZE, CHUNK_NUMBER_BASE, CHUNK_NUMBER_MODULUS){
    
    assert(CHUNK_NUMBER_BASE <= 253);
    assert(CHUNK_NUMBER_MODULUS <= 253);
    assert(CHUNK_NUMBER_MODULUS <= CHUNK_NUMBER_BASE);
    
    var CHUNK_NUMBER_DIV = CHUNK_NUMBER_BASE - CHUNK_NUMBER_MODULUS + 1;
    
    signal input base[CHUNK_NUMBER_BASE];
    signal input modulus[CHUNK_NUMBER_MODULUS];
    signal input dummy;

    signal output div[CHUNK_NUMBER_DIV];
    signal output mod[CHUNK_NUMBER_MODULUS];
    
    
    var long_division[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV - 1, base, modulus);
    
    for (var i = 0; i < CHUNK_NUMBER_DIV; i++){
        div[i] <-- long_division[0][i];

    }
    component modChecks[CHUNK_NUMBER_MODULUS];
    for (var i = 0; i < CHUNK_NUMBER_MODULUS; i++){
        mod[i] <-- long_division[1][i];
        // Check to avoid negative numbers
        modChecks[i] = Num2Bits(CHUNK_SIZE);
        modChecks[i].in <== mod[i];

    }
    
    component greaterThan = BigGreaterThan(CHUNK_SIZE, CHUNK_NUMBER_MODULUS);
    
    greaterThan.in[0] <== modulus;
    greaterThan.in[1] <== mod;
    greaterThan.out === 1;
    
    component mult;
    if (CHUNK_NUMBER_DIV >= CHUNK_NUMBER_MODULUS){
        mult = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER_DIV, CHUNK_NUMBER_MODULUS);
        
        mult.in1 <== div;
        mult.in2 <== modulus;
        mult.dummy <== dummy;
    } else {
        mult = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV);
        
        mult.in2 <== div;
        mult.in1 <== modulus;
        mult.dummy <== dummy;
    }

    for (var i = CHUNK_NUMBER_BASE - 1; i < CHUNK_NUMBER_MODULUS + CHUNK_NUMBER_DIV - 1; i++){
        mult.out[i] === 0;
    }

    component checkCarry = CheckCarryToZero(CHUNK_SIZE, CHUNK_SIZE * 2 + log_ceil(CHUNK_NUMBER_MODULUS + CHUNK_NUMBER_DIV - 1), CHUNK_NUMBER_BASE);
    for (var i = 0; i < CHUNK_NUMBER_MODULUS; i++) {
        checkCarry.in[i] <== base[i] - mult.out[i] - mod[i];
    }
    for (var i = CHUNK_NUMBER_MODULUS; i < CHUNK_NUMBER_BASE; i++) {
        checkCarry.in[i] <== base[i] - mult.out[i];
    }

}