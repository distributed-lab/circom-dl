pragma circom 2.1.6;

include "../bitify/comparators.circom";
include "../bitify/bitify.circom";
include "./bigInt.circom";
include "./bigIntFunc.circom";
include "../int/arithmetic.circom";
include "./karatsuba.circom";

// Here will be explanation what our big int is and how to use it
// Same as default BigInt but we ignore overflow (a_i * 2 ** CHUNK_SIZE * i, here a_i can be greater than 2 ** CHUNK_SIZE)
//-------------------------------------------------------------------------------------------------------------------------------------------------
// Next templates are actual only for same chunk sizes of inputs, don`t use them without knowing what are u doing!!!

template BigAddOwerflow(CHUNK_SIZE, CHUNK_NUMBER){
    assert(CHUNK_SIZE <= 253);
    
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER];
    signal input dummy;
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[i] <== in[0][i] + in[1][i] + dummy * dummy;
    }
}

template BigMultOwerflow(CHUNK_SIZE, CHUNK_NUMBER){
    
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

template BigMultOptimisedOwerflow(CHUNK_SIZE, CHUNK_NUMBER){
    
    assert(CHUNK_SIZE <= 126);
    
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    signal output out[CHUNK_NUMBER * 2 - 1];
    
    component karatsuba = KaratsubaNoCarry(CHUNK_NUMBER);
    karatsuba.in <== in;
    karatsuba.dummy <== dummy;
    for (var i = 0; i < CHUNK_NUMBER * 2 - 1; i++){
        out[i] <== karatsuba.out[i];
    }
}

// template BigModOwerflow(CHUNK_SIZE, CHUNK_NUMBER){
    
    //     assert(CHUNK_SIZE <= 126);
    
    //     signal input base[CHUNK_NUMBER * 2];
    //     signal input modulus[CHUNK_NUMBER];
    //     signal input dummy;
    
    //     var long_division[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, base, modulus);
    
    //     signal output div[CHUNK_NUMBER];
    //     signal output mod[CHUNK_NUMBER];
    
    //     for (var i = 0; i < CHUNK_NUMBER; i++){
        //         div[i] <-- long_division[0][i];
        //         mod[i] <-- long_division[1][i];
        //     }
    
    //     component multChecks[2];
    //     multChecks[0] = BigMultOptimised(CHUNK_SIZE, CHUNK_NUMBER);
    //     multChecks[1] = BigMultOptimised(CHUNK_SIZE, CHUNK_NUMBER);
    
    //     multChecks[0].in[0] <== div;
    //     multChecks[0].in[1] <== modulus;
    //     multChecks[0].dummy <== dummy;
    
    //     for (var i = 0; i < CHUNK_NUMBER - 1; i++){
        //         multChecks[1].in[0][i] <== div[i];
        //     }
    //     multChecks[1].in[0][CHUNK_NUMBER - 1] <== div[CHUNK_NUMBER - 1] + 1 + dummy * dummy;
    //     multChecks[1].in[1] <== modulus;
    //     multChecks[1].dummy <== dummy;
    
    //     // div * modulus <= base
    //     // (div + 1) * modulus > base
    //     component lessEqThan = BigLessEqThan(CHUNK_SIZE, CHUNK_NUMBER * 2);
    //     component greaterThan = BigGreaterThan(CHUNK_SIZE, CHUNK_NUMBER * 2);
    
    //     lessEqThan.in[0] <== multChecks[0].out;
    //     lessEqThan.in[1] <== base;
    //     lessEqThan.out === 1;
    
    //     greaterThan.in[0] <== multChecks[1].out;
    //     greaterThan.in[1] <== base;
    //     greaterThan.out === 1;
    
    //     //div * modulus + mod === base
    
    //     component bigAddCheck = BigAdd(CHUNK_SIZE, CHUNK_NUMBER * 2);
    
    //     bigAddCheck.in[0] <== multChecks[0].out;
    //     for (var i = 0; i < CHUNK_NUMBER; i++){
        //         bigAddCheck.in[1][i] <== mod[i];
        //     }
    //     for (var i = CHUNK_NUMBER; i < 2 * CHUNK_NUMBER; i++){
        //         bigAddCheck.in[1][i] <== 0;
        //     }
    //     bigAddCheck.dummy <== dummy;
    
    //     component bigIsEqual = BigIsEqual(CHUNK_SIZE, CHUNK_NUMBER * 2 + 1);
    
    //     bigIsEqual.in[0] <== bigAddCheck.out;
    //     for (var i = 0; i < CHUNK_NUMBER * 2; i++){
        //         bigIsEqual.in[1][i] <== base[i];
        //     }
    //     bigIsEqual.in[1][CHUNK_NUMBER * 2] <== 0;
    
    //     bigIsEqual.out === 1;
    // }


// use only for CHUNK_NUMBER == 2 ** x
template BigModInvOptimisedOwerflow(CHUNK_SIZE, CHUNK_NUMBER) {
    assert(CHUNK_SIZE <= 252);
    signal input in[CHUNK_NUMBER];
    signal input modulus[CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER];

    signal input dummy;
    dummy * dummy === 0;

    component reduce = RemoveOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER + 1);
    reduce.in <== in;
    reduce.dummy <== dummy;

    var inv[200] = mod_inv(CHUNK_SIZE, CHUNK_NUMBER + 1, reduce.out, modulus);

    for (var i = 0; i < CHUNK_NUMBER; i++) {
        out[i] <-- inv[i];
    }
    
    component mult = BigMultModPNonEqual(CHUNK_SIZE, CHUNK_NUMBER + 1, CHUNK_NUMBER, CHUNK_NUMBER);
    mult.in1 <== reduce.out;
    mult.in2 <== out;
    mult.modulus <== modulus;
    mult.dummy <== dummy;

    mult.out[0] === 1;
    for (var i = 1; i < CHUNK_NUMBER; i++) {
        mult.out[i] === 0;
    }
}


template ScalarMultOverflow(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[CHUNK_NUMBER];
    signal input scalar;
    
    signal output out[CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[i] <== scalar * in[i];
    }
}


template RemoveOverflow(CHUNK_SIZE, CHUNK_NUMBER_OLD, CHUNK_NUMBER_NEW){
    assert(CHUNK_SIZE <= 126);
    assert(CHUNK_NUMBER_OLD <= CHUNK_NUMBER_NEW);
    
    signal input dummy;
    dummy * dummy === 0;
    signal input in[CHUNK_NUMBER_OLD];
    signal output out[CHUNK_NUMBER_NEW];
    
    component getLastNBits[CHUNK_NUMBER_NEW - 1];
    component bits2Num[CHUNK_NUMBER_NEW - 1];
    if (CHUNK_NUMBER_NEW > CHUNK_NUMBER_OLD){
        for (var i = 0; i < CHUNK_NUMBER_OLD; i++){
            if (i == 0){
                getLastNBits[i] = GetLastNBits(CHUNK_SIZE);
                getLastNBits[i].in <== in[i];
                bits2Num[i] = Bits2Num(CHUNK_SIZE);
                bits2Num[i].in <== getLastNBits[i].out;
                out[i] <== bits2Num[i].out;
            } else {
                getLastNBits[i] = GetLastNBits(CHUNK_SIZE);
                getLastNBits[i].in <== in[i] + getLastNBits[i - 1].div + dummy * dummy;
                bits2Num[i] = Bits2Num(CHUNK_SIZE);
                bits2Num[i].in <== getLastNBits[i].out;
                out[i] <== bits2Num[i].out;
            }
        }
        for (var i = CHUNK_NUMBER_OLD; i < CHUNK_NUMBER_NEW - 1; i++){
            getLastNBits[i] = GetLastNBits(CHUNK_SIZE);
            getLastNBits[i].in <== getLastNBits[i - 1].div;
            bits2Num[i] = Bits2Num(CHUNK_SIZE);
            bits2Num[i].in <== getLastNBits[i].out;
            out[i] <== bits2Num[i].out;
        }
        out[CHUNK_NUMBER_NEW - 1] <== getLastNBits[CHUNK_NUMBER_NEW - 2].div;
    } else {
        for (var i = 0; i < CHUNK_NUMBER_OLD - 1; i++){
            if (i == 0){
                getLastNBits[i] = GetLastNBits(CHUNK_SIZE);
                getLastNBits[i].in <== in[i];
                bits2Num[i] = Bits2Num(CHUNK_SIZE);
                bits2Num[i].in <== getLastNBits[i].out;
                out[i] <== bits2Num[i].out;
            } else {
                getLastNBits[i] = GetLastNBits(CHUNK_SIZE);
                getLastNBits[i].in <== in[i] + getLastNBits[i - 1].div + dummy * dummy;
                bits2Num[i] = Bits2Num(CHUNK_SIZE);
                bits2Num[i].in <== getLastNBits[i].out;
                out[i] <== bits2Num[i].out;
            }
        }
        out[CHUNK_NUMBER_NEW - 1] <== getLastNBits[CHUNK_NUMBER_NEW - 2].div + in[CHUNK_NUMBER_NEW - 1] + dummy * dummy;
    }
}



// Comparators
//---------------------------------------------------------------------------------------------------------------------
//

// compare each chunk
// !!!!!!!!!!!can be slightly optimised!!!!!!!!!
template ForceEqual(CHUNK_NUMBER){
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


// in1 already reduced, used for checks of function returns (they return correctly reduced)
template ReducedEqual(CHUNK_SIZE, CHUNK_NUMBER_OLD, CHUNK_NUMBER_NEW){
    signal input in1[CHUNK_NUMBER_NEW];
    signal input in2[CHUNK_NUMBER_OLD];
    signal input dummy;
    dummy * dummy === 0;
    signal output out;

    component reduce = RemoveOverflow(CHUNK_SIZE, CHUNK_NUMBER_OLD, CHUNK_NUMBER_NEW);
    reduce.in <== in2;
    reduce.dummy <== dummy;

    component forceEqual = ForceEqual(CHUNK_NUMBER_NEW);
    forceEqual.in[0] <== in1;
    forceEqual.in[1] <== reduce.out;
    
    out <== forceEqual.out;
    log(out);

}

// 2 of nums are not reduced
//todo: fix
// template OverflowedEqual(CHUNK_SIZE, CHUNK_NUMBER_LESS, CHUNK_NUMBER_GREATER){
//     signal input in1[CHUNK_NUMBER_LESS];
//     signal input in2[CHUNK_NUMBER_GREATER];
//     signal input dummy;
//     dummy * dummy === 0;
//     signal output out;


//     component reduce[2];
//     reduce[0] = RemoveOverflow(CHUNK_SIZE, CHUNK_NUMBER_LESS, CHUNK_NUMBER_GREATER);
//     reduce[1] = RemoveOverflow(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_GREATER);

//     reduce[0].in <== in1;
//     reduce[0].dummy <== dummy;
//     reduce[1].in <== in2;
//     reduce[1].dummy <== dummy;

//     component forceEqual = ForceEqual(CHUNK_NUMBER_GREATER);
//     forceEqual.in[0] <== reduce[0].out;
//     forceEqual.in[1] <== reduce[1].out;
    
//     out <== forceEqual.out;
//     log(out);

// }
