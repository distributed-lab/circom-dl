pragma circom  2.1.6;

include "../bitify/bitify.circom";
include "../bitify/comparators.circom";
include "./bigIntFunc.circom";
include "../utils/switcher.circom";

// Calculates 2 numbers with CHUNK_NUMBER multiplication using karatsuba method
// out is overflowed
// use only for 2 ** k CHUNK_NUMBER, othewise u will get error
// here is no check for CHUNK_SIZE <= 126,  maybe will be added later
template KaratsubaOverflow(CHUNK_NUMBER) {
    signal input in[2][CHUNK_NUMBER];
    signal output out[2 * CHUNK_NUMBER];
    
    
    if (CHUNK_NUMBER == 1) {
        out[0] <== in[0][0] * in[1][0];
    } else {
        component karatsubaA1B1 = KaratsubaOverflow(CHUNK_NUMBER / 2);
        component karatsubaA2B2 = KaratsubaOverflow(CHUNK_NUMBER / 2);
        component karatsubaA1A2B1B2 = KaratsubaOverflow(CHUNK_NUMBER / 2);
        
        for (var i = 0; i < CHUNK_NUMBER / 2; i++) {
            karatsubaA1B1.in[0][i] <== in[0][i];
            karatsubaA1B1.in[1][i] <== in[1][i];
            karatsubaA2B2.in[0][i] <== in[0][i + CHUNK_NUMBER / 2];
            karatsubaA2B2.in[1][i] <== in[1][i + CHUNK_NUMBER / 2];
            karatsubaA1A2B1B2.in[0][i] <== in[0][i] + in[0][i + CHUNK_NUMBER / 2];
            karatsubaA1A2B1B2.in[1][i] <== in[1][i] + in[1][i + CHUNK_NUMBER / 2];
        }
        
        for (var i = 0; i < 2 * CHUNK_NUMBER; i++) {
            if (i < CHUNK_NUMBER) {
                if (CHUNK_NUMBER / 2 <= i && i < 3 * (CHUNK_NUMBER / 2)) {
                    out[i] <== karatsubaA1B1.out[i]
                    + karatsubaA1A2B1B2.out[i - CHUNK_NUMBER / 2]
                    - karatsubaA1B1.out[i - CHUNK_NUMBER / 2]
                    - karatsubaA2B2.out[i - CHUNK_NUMBER / 2];
                } else {
                    out[i] <== karatsubaA1B1.out[i];
                }
            } else {
                if (CHUNK_NUMBER / 2 <= i && i < 3 * (CHUNK_NUMBER / 2)) {
                    out[i] <== karatsubaA2B2.out[i - CHUNK_NUMBER]
                    + karatsubaA1A2B1B2.out[i - CHUNK_NUMBER / 2]
                    - karatsubaA1B1.out[i - CHUNK_NUMBER / 2]
                    - karatsubaA2B2.out[i - CHUNK_NUMBER / 2];
                } else {
                    out[i] <== karatsubaA2B2.out[i - CHUNK_NUMBER];
                }
            }
        }
    }
}

template BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS){
    
    assert(CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS <= 252);
    assert(CHUNK_NUMBER_GREATER >= CHUNK_NUMBER_LESS);
    
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    
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
                    tmpResult[i][j] <== tmpMults[i - j][j] + tmpResult[i][j - 1];
                }
            }
            out[i] <== tmpResult[i][i];
            
        } else {
            if (i < CHUNK_NUMBER_GREATER) {
                for (var j = 0; j < CHUNK_NUMBER_LESS; j++){
                    if (j == 0){
                        tmpResult[i][j] <== tmpMults[i - j][j];
                    } else {
                        tmpResult[i][j] <== tmpMults[i - j][j] + tmpResult[i][j - 1];
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

template RemoveOverflow(CHUNK_SIZE, MAX_CHUNK_SIZE, CHUNK_NUMBER, MAX_CHUNK_NUMBER){
    assert (CHUNK_NUMBER <= MAX_CHUNK_NUMBER);
    
    signal input in[CHUNK_NUMBER];
    signal output out[MAX_CHUNK_NUMBER];
    
    signal signs[MAX_CHUNK_SIZE];
    component signSwitchers[MAX_CHUNK_NUMBER];
    component getDiv[MAX_CHUNK_NUMBER];
    component getMod[MAX_CHUNK_NUMBER];
    component num2Bits[MAX_CHUNK_NUMBER];
    component isZero[MAX_CHUNK_NUMBER];
    component zeroSwitcher[MAX_CHUNK_NUMBER];
    component modSwitcher[MAX_CHUNK_NUMBER];
    signal overflows[MAX_CHUNK_NUMBER];
    
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        if (i != MAX_CHUNK_NUMBER - 1){
            signSwitchers[i] = Switcher();
            modSwitcher[i] = Switcher();
            zeroSwitcher[i] = Switcher();
            isZero[i] = IsZero();
            num2Bits[i] = Num2Bits(MAX_CHUNK_SIZE + 1); 
            getMod[i] = Bits2Num(CHUNK_SIZE);
            getDiv[i] = Bits2Num(MAX_CHUNK_SIZE - CHUNK_SIZE + 1);
        }
        if (i == 0){
            signs[i] <-- is_negative_chunk(in[i], MAX_CHUNK_SIZE);
            signs[i] * (1 - signs[i]) === 0;
            
            signSwitchers[i].bool <== signs[i];
            signSwitchers[i].in[0] <== in[i];
            signSwitchers[i].in[1] <==  -in[i];
            
            num2Bits[i].in <== signSwitchers[i].out[0];
            for (var j = 0; j < CHUNK_SIZE; j++){
                getMod[i].in[j] <== num2Bits[i].out[j];
            }
            isZero[i].in <== getMod[i].out;
            modSwitcher[i].in[0] <== getMod[i].out;
            modSwitcher[i].in[1] <== 2 ** CHUNK_SIZE - getMod[i].out;
            modSwitcher[i].bool <== signs[i];
            
            zeroSwitcher[i].bool <== isZero[i].out;
            zeroSwitcher[i].in[0] <== modSwitcher[i].out[0];
            zeroSwitcher[i].in[1] <== 0;
            
            out[i] <== zeroSwitcher[i].out[0];
            
            for (var j = 0; j < MAX_CHUNK_SIZE - CHUNK_SIZE + 1; j++){
                getDiv[i].in[j] <== num2Bits[i].out[j + CHUNK_SIZE];
            }
            overflows[i] <== getDiv[i].out + signs[i] * (1 - isZero[i].out); 
        } else {
            if (i != MAX_CHUNK_NUMBER - 1){
                signs[i] <-- is_negative_chunk(in[i] + overflows[i - 1] * (- 2 * signs[i - 1] + 1), MAX_CHUNK_SIZE);
                signs[i] * (1 - signs[i]) === 0;
                
                signSwitchers[i].bool <== signs[i];
                signSwitchers[i].in[0] <== in[i] + overflows[i - 1] * (-2 * signs[i - 1] + 1);
                signSwitchers[i].in[1] <==  -(in[i] + overflows[i - 1] * (-2 * signs[i - 1] + 1));
                
                num2Bits[i].in <== signSwitchers[i].out[0];
                for (var j = 0; j < CHUNK_SIZE; j++){
                    getMod[i].in[j] <== num2Bits[i].out[j];
                }
                isZero[i].in <== getMod[i].out;
                modSwitcher[i].in[0] <== getMod[i].out;
                modSwitcher[i].in[1] <== 2 ** CHUNK_SIZE - getMod[i].out;
                modSwitcher[i].bool <== signs[i];
                
                zeroSwitcher[i].bool <== isZero[i].out;
                zeroSwitcher[i].in[0] <== modSwitcher[i].out[0];
                zeroSwitcher[i].in[1] <== 0;
                
                out[i] <== zeroSwitcher[i].out[0];
                
                 for (var j = 0; j < MAX_CHUNK_SIZE - CHUNK_SIZE + 1; j++){
                    getDiv[i].in[j] <== num2Bits[i].out[j + CHUNK_SIZE];
                }
                overflows[i] <== getDiv[i].out + signs[i] * (1 - isZero[i].out); 
            } else {
                out[i] <== overflows[i - 1] * (-2 * signs[i - 1] + 1);
            }
           
        }
    }
    for (var i = CHUNK_NUMBER; i < MAX_CHUNK_NUMBER; i++){
        if (i != MAX_CHUNK_NUMBER - 1){
            signSwitchers[i] = Switcher();
            modSwitcher[i] = Switcher();
            zeroSwitcher[i] = Switcher();
            isZero[i] = IsZero();
            num2Bits[i] = Num2Bits(MAX_CHUNK_SIZE + 1); 
            getMod[i] = Bits2Num(CHUNK_SIZE);
            getDiv[i] = Bits2Num(MAX_CHUNK_SIZE - CHUNK_SIZE + 1);

            signs[i] <-- is_negative_chunk(overflows[i - 1] * (- 2 * signs[i - 1] + 1), MAX_CHUNK_SIZE);
            signs[i] * (1 - signs[i]) === 0;
            
            signSwitchers[i].bool <== signs[i];
            signSwitchers[i].in[0] <== overflows[i - 1] * (- 2 * signs[i - 1] + 1);
            signSwitchers[i].in[1] <==  -(overflows[i - 1] * (- 2 * signs[i - 1] + 1));
            
            num2Bits[i].in <== signSwitchers[i].out[0];
            for (var j = 0; j < CHUNK_SIZE; j++){
                getMod[i].in[j] <== num2Bits[i].out[j];
            }
            isZero[i].in <== getMod[i].out;
            modSwitcher[i].in[0] <== getMod[i].out;
            modSwitcher[i].in[1] <== 2 ** CHUNK_SIZE - getMod[i].out;
            modSwitcher[i].bool <== signs[i];
            
            zeroSwitcher[i].bool <== isZero[i].out;
            zeroSwitcher[i].in[0] <== modSwitcher[i].out[0];
            zeroSwitcher[i].in[1] <== 0;
            
            out[i] <== zeroSwitcher[i].out[0];
            
            for (var j = 0; j < MAX_CHUNK_SIZE - CHUNK_SIZE + 1; j++){
                getDiv[i].in[j] <== num2Bits[i].out[j + CHUNK_SIZE];
            }
            overflows[i] <== getDiv[i].out + signs[i] * (1 - isZero[i].out); 

        } else {
            out[i] <== overflows[i - 1] * (-2 * signs[i - 1] + 1);
        }
    }
}