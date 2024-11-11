pragma circom 2.1.6;

include "../bitify/comparators.circom";
include "../bitify/bitify.circom";
include "./bigIntFunc.circom";
include "../int/arithmetic.circom";
include "./karatsuba.circom";

//here will be explanation what our big int is and how to use it

//-------------------------------------------------------------------------------------------------------------------------------------------------
//Next templates are actual only for same chunk sizes of inputs, don`t use them without knowing what are u doing!!!

template BigAddNoCarry(CHUNK_SIZE, CHUNK_NUMBER){
    assert(CHUNK_SIZE <= 253);
    
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER];
    signal input dummy;
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[i] <== in[0][i] + in[1][i] + dummy * dummy;
    }
}

template BigAdd(CHUNK_SIZE, CHUNK_NUMBER){
    
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER + 1];
    signal input dummy;
    
    component bigAddNoCarry = BigAddNoCarry(CHUNK_SIZE, CHUNK_NUMBER);
    bigAddNoCarry.in <== in;
    bigAddNoCarry.dummy <== dummy;
    
    component num2bits[CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        num2bits[i] = Num2Bits(CHUNK_SIZE + 1);
        
        //if >= 2**CHUNK_SIZE, overflow
        if (i == 0){
            num2bits[i].in <== bigAddNoCarry.out[i];
        } else {
            num2bits[i].in <== bigAddNoCarry.out[i] + num2bits[i - 1].out[CHUNK_SIZE] + dummy * dummy;
        }
    }
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        if (i == 0) {
            out[i] <== bigAddNoCarry.out[i] - (num2bits[i].out[CHUNK_SIZE]) * (2 ** CHUNK_SIZE) + dummy * dummy;
        }
        else {
            out[i] <== bigAddNoCarry.out[i] - (num2bits[i].out[CHUNK_SIZE]) * (2 ** CHUNK_SIZE) + num2bits[i - 1].out[CHUNK_SIZE] + dummy * dummy;
        }
    }
    out[CHUNK_NUMBER] <== num2bits[CHUNK_NUMBER - 1].out[CHUNK_SIZE];
}

template BigMultNoCarry(CHUNK_SIZE, CHUNK_NUMBER){
    
    assert(CHUNK_SIZE <= 126);
    
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    signal output out[CHUNK_NUMBER * 2 - 1];
    
    
    // We can`t mult multiply 2 big nums without multiplying each chunks of first with each chunk of second
    
    signal tmpMults[CHUNK_NUMBER][CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        for (var j = 0; j < CHUNK_NUMBER; j++){
            tmpMults[i][j] <== in[0][i] * in[1][j];
        }
    }
    
    // left - in[0][idx], right - in[1][idx]
    // 0*0 0*1 ... 0*n
    // 1*0 1*1 ... 1*n
    //  ⋮   ⋮    \   ⋮
    // n*0 n*1 ... n*n
    //
    // result[idx].length = count(i+j === idx)
    // result[0].length = 1 (i = 0; j = 0)
    // result[1].length = 2 (i = 1; j = 0; i = 0; j = 1);
    // result[i].length = result[i-1].length + 1 if i <= CHUNK_NUMBER else result[i-1].length - 1 (middle, main diagonal)
    
    signal tmpResult[CHUNK_NUMBER * 2 - 1][CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER * 2 - 1; i++){
        
        if (i < CHUNK_NUMBER){
            for (var j = 0; j < i + 1; j++){
                if (j == 0){
                    tmpResult[i][j] <== tmpMults[i - j][j];
                } else {
                    tmpResult[i][j] <== tmpMults[i - j][j] + tmpResult[i][j - 1] + dummy * dummy;
                }
            }
            out[i] <== tmpResult[i][i];
            
        } else {
            for (var j = 0; j < 2 * CHUNK_NUMBER - 1 - i; j++){
                if (j == 0){
                    tmpResult[i][j] <== tmpMults[CHUNK_NUMBER - 1 - j][i + j - CHUNK_NUMBER + 1];
                } else {
                    tmpResult[i][j] <== tmpMults[CHUNK_NUMBER - 1 - j][i + j - CHUNK_NUMBER + 1] + tmpResult[i][j - 1] + dummy * dummy;
                }
            }
            out[i] <== tmpResult[i][2 * CHUNK_NUMBER - 2 - i];
            
        }
    }
}

template BigMult(CHUNK_SIZE, CHUNK_NUMBER){
    
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    
    dummy * dummy === 0;
    
    signal output out[CHUNK_NUMBER * 2];
    
    component bigMultNoCarry = BigMultNoCarry(CHUNK_SIZE, CHUNK_NUMBER);
    bigMultNoCarry.in <== in;
    bigMultNoCarry.dummy <== dummy;
    
    component num2bits[CHUNK_NUMBER * 2 - 1];
    component bits2numOverflow[CHUNK_NUMBER * 2 - 1];
    component bits2numModulus[CHUNK_NUMBER * 2 - 1];
    
    //overflow = no carry (multiplication result / 2 ** chunk_size) === chunk_size first bits in result
    for (var i = 0; i < 2 * CHUNK_NUMBER - 1; i++){
        //bigMultNoCarry = CHUNK_i * CHUNK_j (2 * CHUNK_SIZE) + CHUNK_i0 * CHUNK_j0 (2 * CHUNK_SIZE) + ..., up to len times,
        // => 2 * CHUNK_SIZE + ADDITIONAL_LEN
        var ADDITIONAL_LEN = i;
        if (i >= CHUNK_NUMBER){
            ADDITIONAL_LEN = 2 * CHUNK_NUMBER - 2 - i;
        }
        
        num2bits[i] = Num2Bits(CHUNK_SIZE * 2 + ADDITIONAL_LEN);
        
        if (i == 0){
            num2bits[i].in <== bigMultNoCarry.out[i];
        } else {
            num2bits[i].in <== dummy * dummy + bigMultNoCarry.out[i] + bits2numOverflow[i - 1].out;
        }
        
        bits2numOverflow[i] = Bits2Num(CHUNK_SIZE + ADDITIONAL_LEN);
        for (var j = 0; j < CHUNK_SIZE + ADDITIONAL_LEN; j++){
            bits2numOverflow[i].in[j] <== num2bits[i].out[CHUNK_SIZE + j];
        }
        
        bits2numModulus[i] = Bits2Num(CHUNK_SIZE);
        for (var j = 0; j < CHUNK_SIZE; j++){
            bits2numModulus[i].in[j] <== num2bits[i].out[j];
        }
    }
    for (var i = 0; i < 2 * CHUNK_NUMBER; i++){
        if (i == 2 * CHUNK_NUMBER - 1){
            out[i] <== bits2numOverflow[i - 1].out;
        } else {
            out[i] <== bits2numModulus[i].out;
        }
    }
}

//use only for CHUNK_NUMBER == 2 ** x
template BigMultOptimised(CHUNK_SIZE, CHUNK_NUMBER){
    
    signal input dummy;
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER * 2];
    
    component karatsuba = KaratsubaNoCarry(CHUNK_NUMBER);
    karatsuba.in <== in;
    karatsuba.dummy <== dummy;
    
    dummy * dummy === 0;
    
    component getLastNBits[CHUNK_NUMBER * 2 - 1];
    component bits2Num[CHUNK_NUMBER * 2 - 1];
    
    for (var i = 0; i < CHUNK_NUMBER * 2 - 1; i++){
        getLastNBits[i] = GetLastNBits(CHUNK_SIZE);
        bits2Num[i] = Bits2Num(CHUNK_SIZE);
        
        if (i == 0) {
            getLastNBits[i].in <== karatsuba.out[i];
        } else {
            getLastNBits[i].in <== karatsuba.out[i] + getLastNBits[i - 1].div;
        }
        bits2Num[i].in <== getLastNBits[i].out;
    }
    
    for (var i = 0; i < CHUNK_NUMBER * 2 - 1; i++){
        out[i] <== bits2Num[i].out;
    }
    out[CHUNK_NUMBER * 2 - 1] <== getLastNBits[CHUNK_NUMBER * 2 - 2].div;
}

template BigMod(CHUNK_SIZE, CHUNK_NUMBER){
    
    assert(CHUNK_SIZE <= 126);
    
    signal input base[CHUNK_NUMBER * 2];
    signal input modulus[CHUNK_NUMBER];
    signal input dummy;
    
    var long_division[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, base, modulus);
    
    signal output div[CHUNK_NUMBER];
    signal output mod[CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        div[i] <-- long_division[0][i];
        mod[i] <-- long_division[1][i];
    }
    
    component multChecks[2];
    multChecks[0] = BigMultOptimised(CHUNK_SIZE, CHUNK_NUMBER);
    multChecks[1] = BigMultOptimised(CHUNK_SIZE, CHUNK_NUMBER);
    
    multChecks[0].in[0] <== div;
    multChecks[0].in[1] <== modulus;
    multChecks[0].dummy <== dummy;
    
    for (var i = 0; i < CHUNK_NUMBER - 1; i++){
        multChecks[1].in[0][i] <== div[i];
    }
    multChecks[1].in[0][CHUNK_NUMBER - 1] <== div[CHUNK_NUMBER - 1] + 1 + dummy * dummy;
    multChecks[1].in[1] <== modulus;
    multChecks[1].dummy <== dummy;
    
    // div * modulus <= base
    // (div + 1) * modulus > base
    component lessEqThan = BigLessEqThan(CHUNK_SIZE, CHUNK_NUMBER * 2);
    component greaterThan = BigGreaterThan(CHUNK_SIZE, CHUNK_NUMBER * 2);
    
    lessEqThan.in[0] <== multChecks[0].out;
    lessEqThan.in[1] <== base;
    lessEqThan.out === 1;
    
    greaterThan.in[0] <== multChecks[1].out;
    greaterThan.in[1] <== base;
    greaterThan.out === 1;
    
    //div * modulus + mod === base
    
    component bigAddCheck = BigAdd(CHUNK_SIZE, CHUNK_NUMBER * 2);
    
    bigAddCheck.in[0] <== multChecks[0].out;
    for (var i = 0; i < CHUNK_NUMBER; i++){
        bigAddCheck.in[1][i] <== mod[i];
    }
    for (var i = CHUNK_NUMBER; i < 2 * CHUNK_NUMBER; i++){
        bigAddCheck.in[1][i] <== 0;
    }
    bigAddCheck.dummy <== dummy;
    
    component bigIsEqual = BigIsEqual(CHUNK_SIZE, CHUNK_NUMBER * 2 + 1);
    
    bigIsEqual.in[0] <== bigAddCheck.out;
    for (var i = 0; i < CHUNK_NUMBER * 2; i++){
        bigIsEqual.in[1][i] <== base[i];
    }
    bigIsEqual.in[1][CHUNK_NUMBER * 2] <== 0;
    
    bigIsEqual.out === 1;
}

//use only for CHUNK_NUMBER == 2 ** x
template BigMultModP(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[3][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER];
    signal input dummy;
    
    component bigMult = BigMultOptimised(CHUNK_SIZE, CHUNK_NUMBER);
    bigMult.in[0] <== in[0];
    bigMult.in[1] <== in[1];
    bigMult.dummy <== dummy;
    
    component bigMod = BigMod(CHUNK_SIZE, CHUNK_NUMBER);
    bigMod.base <== bigMult.out;
    bigMod.modulus <== in[2];
    bigMod.dummy <== dummy;
    
    out <== bigMod.mod;
}

template BigSubNoBorrow(CHUNK_SIZE, CHUNK_NUMBER){
    assert (CHUNK_SIZE < 252);
    
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER];
    signal input dummy;
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[i] <== in[0][i] - in[1][i] + dummy * dummy;
    }
}

//in[0] >= in[1], else will not work correctly, use only in this case!
template BigSub(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER];
    signal input dummy;
    component bigSubNoBorrow = BigSubNoBorrow(CHUNK_SIZE, CHUNK_NUMBER);
    bigSubNoBorrow.in <== in;
    bigSubNoBorrow.dummy <== dummy;
    
    component lessThan[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        lessThan[i] = LessThan(CHUNK_SIZE + 1);
        lessThan[i].in[1] <== 2 ** CHUNK_SIZE;
        
        if (i == 0){
            lessThan[i].in[0] <== bigSubNoBorrow.out[i] + 2 ** CHUNK_SIZE + dummy * dummy;
            out[i] <== bigSubNoBorrow.out[i] + (2 ** CHUNK_SIZE) * (lessThan[i].out) + dummy * dummy;
        } else {
            lessThan[i].in[0] <== bigSubNoBorrow.out[i] - lessThan[i - 1].out + 2 ** CHUNK_SIZE + dummy * dummy;
            out[i] <== bigSubNoBorrow.out[i] + (2 ** CHUNK_SIZE) * (lessThan[i].out) - lessThan[i - 1].out + dummy * dummy;
        }
    }
}

//USE THIS ONLY FOR EXP IN 10000000...01 FORMAT, EBITS = LEN OF EXP, MIN = 2 (11 in bit = 0x3)
template PowerMod(CHUNK_SIZE, CHUNK_NUMBER, E_BITS) {
    assert(E_BITS >= 2);
    
    signal input base[CHUNK_NUMBER];
    signal input modulus[CHUNK_NUMBER];
    signal input dummy;
    
    signal output out[CHUNK_NUMBER];
    
    component muls[E_BITS];
    
    for (var i = 0; i < E_BITS; i++) {
        muls[i] = BigMultModP(CHUNK_SIZE, CHUNK_NUMBER);
        muls[i].dummy <== dummy;
        for (var j = 0; j < CHUNK_NUMBER; j++) {
            muls[i].in[2][j] <== modulus[j];
        }
    }
    
    for (var i = 0; i < CHUNK_NUMBER; i++) {
        muls[0].in[0][i] <== base[i];
        muls[0].in[1][i] <== base[i];
    }
    
    for (var i = 1; i < E_BITS - 1; i++) {
        for (var j = 0; j < CHUNK_NUMBER; j++) {
            muls[i].in[0][j] <== muls[i - 1].out[j];
            muls[i].in[1][j] <== muls[i - 1].out[j];
        }
    }
    
    for (var i = 0; i < CHUNK_NUMBER; i++) {
        muls[E_BITS - 1].in[0][i] <== base[i];
        muls[E_BITS - 1].in[1][i] <== muls[E_BITS - 2].out[i];
    }
    
    for (var i = 0; i < CHUNK_NUMBER; i++) {
        out[i] <== muls[E_BITS - 1].out[i];
    }
}


//------------------------------------------------------------------------------------------------------------------------------------------------- 
// Next templates are for big numbers operations for any number of chunks in inputs

// Addition for non-equal chunks

template BigAddNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS){
    
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input dummy;
    
    signal output out[CHUNK_NUMBER_GREATER + 1];
    
    component bigAdd = BigAdd(CHUNK_SIZE, CHUNK_NUMBER_GREATER);
    for (var i = 0; i < CHUNK_NUMBER_LESS; i++){
        bigAdd.in[0][i] <== in1[i];
        bigAdd.in[1][i] <== in2[i];
    }
    for (var i = CHUNK_NUMBER_LESS; i < CHUNK_NUMBER_GREATER; i++){
        bigAdd.in[0][i] <== in1[i];
        bigAdd.in[1][i] <== 0;
    }
    bigAdd.dummy <== dummy;
    
    out <== bigAdd.out;
}

// Multiplication for non-equal chunk numbers

template BigMultNoCarryNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS){
    
    assert(CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS <= 252);
    assert(CHUNK_NUMBER_GREATER >= CHUNK_NUMBER_LESS);
    
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input dummy;
    signal output out[CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1];
    
    
    // We can`t mult multiply 2 big nums without multiplying each chunks of first with each chunk of second
    
    signal tmpMults[CHUNK_NUMBER_GREATER][CHUNK_NUMBER_LESS];
    for (var i = 0; i < CHUNK_NUMBER_GREATER; i++){
        for (var j = 0; j < CHUNK_NUMBER_LESS; j++){
            tmpMults[i][j] <== in1[i] * in2[j];
        }
    }
    
    // left - in1[idx], right - in2[idx]  || n - CHUNK_NUMBER_GREATER, m - CHUNK_NUMBER_LESS
    // 0*0 0*1 ... 0*n
    // 1*0 1*1 ... 1*n
    //  ⋮   ⋮    \   ⋮
    // m*0 m*1 ... m*n
    //
    // result[idx].length = count(i+j === idx)
    // result[0].length = 1 (i = 0; j = 0)
    // result[1].length = 2 (i = 1; j = 0; i = 0; j = 1);
    // result[i].length = { result[i-1].length + 1,  i <= CHUNK_NUMBER_LESS}
    //                    {  result[i-1].length - 1,  i > CHUNK_NUMBER_GREATER}
    //                    {  result[i-1].length,      CHUNK_NUMBER_LESS < i <= CHUNK_NUMBER_GREATER}
    
    signal tmpResult[CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1][CHUNK_NUMBER_LESS];
    
    for (var i = 0; i < CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1; i++){
        
        if (i < CHUNK_NUMBER_LESS){
            for (var j = 0; j < i + 1; j++){
                if (j == 0){
                    tmpResult[i][j] <== tmpMults[i - j][j];
                } else {
                    tmpResult[i][j] <== tmpMults[i - j][j] + tmpResult[i][j - 1] + dummy * dummy;
                }
            }
            out[i] <== tmpResult[i][i];
            
        } else {
            if (i < CHUNK_NUMBER_GREATER) {
                for (var j = 0; j < CHUNK_NUMBER_LESS; j++){
                    if (j == 0){
                        tmpResult[i][j] <== tmpMults[i - j][j];
                    } else {
                        tmpResult[i][j] <== tmpMults[i - j][j] + tmpResult[i][j - 1] + dummy * dummy;
                    }
                }
                out[i] <== tmpResult[i][CHUNK_NUMBER_LESS - 1];
            } else {
                for (var j = 0; j < CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1 - i; j++){
                    if (j == 0){
                        tmpResult[i][j] <== tmpMults[CHUNK_NUMBER_GREATER - 1 - j][i + j - CHUNK_NUMBER_GREATER + 1];
                    } else {
                        tmpResult[i][j] <== tmpMults[CHUNK_NUMBER_GREATER - 1 - j][i + j - CHUNK_NUMBER_GREATER + 1] + tmpResult[i][j - 1];
                    }
                }
                out[i] <== tmpResult[i][CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 2 - i];
            }
        }
    }
}

template BigMultNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS){
    
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input dummy;
    signal output out[CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS];
    var isPowerOfTwo = 0;
    for (var i = 0; i < CHUNK_NUMBER_GREATER; i++){
        if (CHUNK_NUMBER_GREATER == 2 ** i){
            isPowerOfTwo = 1;
        }
    }
    if (isPowerOfTwo == 0){
        dummy * dummy === 0;
        
        component bigMultNoCarry = BigMultNoCarryNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS);
        bigMultNoCarry.in1 <== in1;
        bigMultNoCarry.in2 <== in2;
        bigMultNoCarry.dummy <== dummy;
        
        component num2bits[CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1];
        component bits2numOverflow[CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1];
        component bits2numModulus[CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1];
        
        //overflow = no carry (multiplication result / 2 ** chunk_size) === chunk_size first bits in result
        for (var i = 0; i < CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1; i++){
            //bigMultNoCarry = CHUNK_i * CHUNK_j (2 * CHUNK_SIZE) + CHUNK_i0 * CHUNK_j0 (2 * CHUNK_SIZE) + ..., up to len times,
            // => 2 * CHUNK_SIZE + ADDITIONAL_LEN
            var ADDITIONAL_LEN = i;
            if (i >= CHUNK_NUMBER_LESS){
                ADDITIONAL_LEN = CHUNK_NUMBER_LESS - 1;
            }
            if (i >= CHUNK_NUMBER_GREATER){
                ADDITIONAL_LEN = CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1 - i;
            }
            
            
            num2bits[i] = Num2Bits(CHUNK_SIZE * 2 + ADDITIONAL_LEN);
            
            if (i == 0){
                num2bits[i].in <== bigMultNoCarry.out[i];
            } else {
                num2bits[i].in <== bigMultNoCarry.out[i] + bits2numOverflow[i - 1].out + dummy * dummy;
            }
            
            bits2numOverflow[i] = Bits2Num(CHUNK_SIZE + ADDITIONAL_LEN);
            for (var j = 0; j < CHUNK_SIZE + ADDITIONAL_LEN; j++){
                bits2numOverflow[i].in[j] <== num2bits[i].out[CHUNK_SIZE + j];
            }
            
            bits2numModulus[i] = Bits2Num(CHUNK_SIZE);
            for (var j = 0; j < CHUNK_SIZE; j++){
                bits2numModulus[i].in[j] <== num2bits[i].out[j];
            }
        }
        for (var i = 0; i < CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS; i++){
            if (i == CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS - 1){
                out[i] <== bits2numOverflow[i - 1].out;
            } else {
                out[i] <== bits2numModulus[i].out;
            }
        }
    } else {
        component bigMult = BigMultOptimised(CHUNK_SIZE, CHUNK_NUMBER_GREATER);
        for (var i = 0; i < CHUNK_NUMBER_LESS; i++){
            bigMult.in[0][i] <== in1[i];
            bigMult.in[1][i] <== in2[i];
        }
        for (var i = CHUNK_NUMBER_LESS; i < CHUNK_NUMBER_GREATER; i++){
            bigMult.in[0][i] <== in1[i];
            bigMult.in[1][i] <== 0;
        }
        bigMult.dummy <== dummy;
        for (var i = 0; i < CHUNK_NUMBER_LESS + CHUNK_NUMBER_GREATER; i++){
            out[i] <== bigMult.out[i];
        }
    }
}

template BigModNonEqual(CHUNK_SIZE, CHUNK_NUMBER_BASE, CHUNK_NUMBER_MODULUS){
    
    assert(CHUNK_NUMBER_BASE <= 253);
    assert(CHUNK_NUMBER_MODULUS <= 253);
    assert(CHUNK_NUMBER_MODULUS <= CHUNK_NUMBER_BASE);
    
    var CHUNK_NUMBER_DIV = CHUNK_NUMBER_BASE - CHUNK_NUMBER_MODULUS;
    
    signal input base[CHUNK_NUMBER_BASE];
    signal input modulus[CHUNK_NUMBER_MODULUS];
    signal input dummy;
    
    var long_division[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV, base, modulus);
    
    signal output div[CHUNK_NUMBER_DIV];
    signal output mod[CHUNK_NUMBER_MODULUS];
    
    for (var i = 0; i < CHUNK_NUMBER_DIV; i++){
        div[i] <-- long_division[0][i];
    }
    
    for (var i = 0; i < CHUNK_NUMBER_MODULUS; i++){
        mod[i] <-- long_division[1][i];
    }
    
    component multChecks[2];
    if (CHUNK_NUMBER_DIV >= CHUNK_NUMBER_MODULUS){
        multChecks[0] = BigMultNonEqual(CHUNK_SIZE, CHUNK_NUMBER_DIV, CHUNK_NUMBER_MODULUS);
        multChecks[1] = BigMultNonEqual(CHUNK_SIZE, CHUNK_NUMBER_DIV, CHUNK_NUMBER_MODULUS);
        
        multChecks[0].in1 <== div;
        multChecks[0].in2 <== modulus;
        
        for (var i = 0; i < CHUNK_NUMBER_DIV - 1; i++){
            multChecks[1].in1[i] <== div[i];
        }
        multChecks[1].in1[CHUNK_NUMBER_DIV - 1] <== div[CHUNK_NUMBER_DIV - 1] + 1;
        multChecks[1].in2 <== modulus;
    } else {
        multChecks[0] = BigMultNonEqual(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV);
        multChecks[1] = BigMultNonEqual(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV);
        
        multChecks[0].in2 <== div;
        multChecks[0].in1 <== modulus;
        
        for (var i = 0; i < CHUNK_NUMBER_DIV - 1; i++){
            multChecks[1].in2[i] <== div[i];
        }
        multChecks[1].in2[CHUNK_NUMBER_DIV - 1] <== div[CHUNK_NUMBER_DIV - 1] + 1;
        multChecks[1].in1 <== modulus;
    }
    multChecks[0].dummy <== dummy;
    multChecks[1].dummy <== dummy;
    
    
    
    // div * modulus <= base
    // (div + 1) * modulus > base
    component lessEqThan = BigLessEqThan(CHUNK_SIZE, CHUNK_NUMBER_BASE);
    component greaterThan = BigGreaterThan(CHUNK_SIZE, CHUNK_NUMBER_BASE);
    
    lessEqThan.in[0] <== multChecks[0].out;
    lessEqThan.in[1] <== base;
    
    lessEqThan.out === 1;
    
    greaterThan.in[0] <== multChecks[1].out;
    greaterThan.in[1] <== base;
    greaterThan.out === 1;
    
    //div * modulus + mod === base
    
    component bigAddCheck = BigAddNonEqual(CHUNK_SIZE, CHUNK_NUMBER_BASE, CHUNK_NUMBER_MODULUS);
    
    bigAddCheck.in1 <== multChecks[0].out;
    bigAddCheck.in2 <== mod;
    bigAddCheck.dummy <== dummy;
    
    component bigIsEqual = BigIsEqual(CHUNK_SIZE, CHUNK_NUMBER_BASE + 1);
    
    bigIsEqual.in[0] <== bigAddCheck.out;
    for (var i = 0; i < CHUNK_NUMBER_BASE; i++){
        bigIsEqual.in[1][i] <== base[i];
    }
    bigIsEqual.in[1][CHUNK_NUMBER_BASE] <== 0;
    
    bigIsEqual.out === 1;
}

template BigMultModPNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS, CHUNK_NUMBER_MODULUS){
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input modulus[CHUNK_NUMBER_MODULUS];
    signal input dummy;
    dummy * dummy === 0;
    
    signal output out[CHUNK_NUMBER_MODULUS];
    
    component bigMult = BigMultNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS);
    bigMult.in1 <== in1;
    bigMult.in2 <== in2;
    bigMult.dummy <== dummy;
    
    component bigMod = BigModNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS, CHUNK_NUMBER_MODULUS);
    bigMod.base <== bigMult.out;
    bigMod.modulus <== modulus;
    bigMod.dummy <== dummy;
    
    out <== bigMod.mod;
}

//in[0] >= in[1], else will not work correctly, use only in this case!
template BigSubNonEqual(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS){
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal output out[CHUNK_NUMBER_GREATER];
    
    component bigSub = BigSub(CHUNK_SIZE, CHUNK_NUMBER_GREATER);
    bigSub.in[0] <== in1;
    for (var i = 0; i < CHUNK_NUMBER_LESS; i++){
        bigSub.in[1][i] <== in2[i];
    }
    for (var i = CHUNK_NUMBER_LESS; i < CHUNK_NUMBER_GREATER; i++){
        bigSub.in[1][i] <== 0;
    }
    
    out <== bigSub.out;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
//comparators for big numbers

template BigLessThan(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    
    signal output out;
    
    component lessThan[CHUNK_NUMBER];
    component isEqual[CHUNK_NUMBER - 1];
    signal result[CHUNK_NUMBER - 1];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        lessThan[i] = LessThan(CHUNK_SIZE);
        lessThan[i].in[0] <== in[0][i];
        lessThan[i].in[1] <== in[1][i];
        
        if (i != 0){
            isEqual[i - 1] = IsEqual();
            isEqual[i - 1].in[0] <== in[0][i];
            isEqual[i - 1].in[1] <== in[1][i];
        }
    }
    
    for (var i = 1; i < CHUNK_NUMBER; i++){
        if (i == 1){
            result[i - 1] <== lessThan[i].out + isEqual[i - 1].out * lessThan[i - 1].out;
        } else {
            result[i - 1] <== lessThan[i].out + isEqual[i - 1].out * result[i - 2];
        }
    }
    out <== result[CHUNK_NUMBER - 2];
}

template BigLessEqThan(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    
    signal output out;
    
    component lessThan[CHUNK_NUMBER];
    component isEqual[CHUNK_NUMBER];
    signal result[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        lessThan[i] = LessThan(CHUNK_SIZE);
        lessThan[i].in[0] <== in[0][i];
        lessThan[i].in[1] <== in[1][i];
        
        isEqual[i] = IsEqual();
        isEqual[i].in[0] <== in[0][i];
        isEqual[i].in[1] <== in[1][i];
    }
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        if (i == 0){
            result[i] <== lessThan[i].out + isEqual[i].out;
        } else {
            result[i] <== lessThan[i].out + isEqual[i].out * result[i - 1];
        }
    }
    
    out <== result[CHUNK_NUMBER - 1];
    
}

template BigGreaterThan(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    
    signal output out;
    
    component lessEqThan = BigLessEqThan(CHUNK_SIZE, CHUNK_NUMBER);
    lessEqThan.in <== in;
    out <== 1 - lessEqThan.out;
}

template BigGreaterEqThan(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    
    signal output out;
    
    component lessThan = BigLessThan(CHUNK_SIZE, CHUNK_NUMBER);
    lessThan.in <== in;
    out <== 1 - lessThan.out;
}

//it is possible to save some constraints by log_2(n) operations, not n 
template BigIsEqual(CHUNK_SIZE, CHUNK_NUMBER) {
    signal input in[2][CHUNK_NUMBER];
    
    signal output out;
    
    component isEqual[CHUNK_NUMBER];
    signal equalResults[CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        isEqual[i] = IsEqual();
        isEqual[i].in[0] <== in[0][i];
        isEqual[i].in[1] <== in[1][i];
        if (i == 0){
            equalResults[i] <== isEqual[i].out;
        } else {
            equalResults[i] <== equalResults[i - 1] * isEqual[i].out;
        }
    }
    out <== equalResults[CHUNK_NUMBER - 1];
}

