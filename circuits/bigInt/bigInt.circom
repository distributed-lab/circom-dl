pragma circom 2.1.6;

//move to directory and refactor
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";

//here will be explanation what our big int is and how to use it

//here will be explanation what is happening here

template BigAddNoCarry(CHUNK_SIZE, CHUNK_NUMBER){
    assert(CHUNK_SIZE <= 253);
    
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[i] <== in[0][i] + in[1][i];
    }
}

template BigAdd(CHUNK_SIZE, CHUNK_NUMBER){
    
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER + 1];
    
    component bigAddNoCarry = BigAddNoCarry(CHUNK_SIZE, CHUNK_NUMBER);
    bigAddNoCarry.in <== in;
    
    component greaterThan[CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        greaterThan[i] = GreaterEqThan(CHUNK_SIZE + 1);
        
        //if >= 2**CHUNK_SIZE, overflow
        if (i == 0){
            greaterThan[i].in[0] <== bigAddNoCarry.out[i];
            greaterThan[i].in[1] <== 2 ** CHUNK_SIZE;
        } else {
            greaterThan[i].in[0] <== bigAddNoCarry.out[i] + greaterThan[i - 1].out;
            greaterThan[i].in[1] <== 2 ** CHUNK_SIZE;
        }
    }
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        if (i == 0){
            out[i] <== bigAddNoCarry.out[i] - (greaterThan[i].out) * (2 ** CHUNK_SIZE);
        }
        else {
            out[i] <== bigAddNoCarry.out[i] - (greaterThan[i].out) * (2 ** CHUNK_SIZE) + greaterThan[i - 1].out;
        }
    }
    out[CHUNK_NUMBER] <== greaterThan[CHUNK_NUMBER - 1].out;
}

template BigMultNoCarry(CHUNK_SIZE, CHUNK_NUMBER){
    
    assert(CHUNK_SIZE <= 126);
    
    signal input in[2][CHUNK_NUMBER];
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
    // result[idx].lenght = count(i+j === idx)
    // result[0].lenght = 1 (i = 0; j = 0)
    // result[1].lenght = 2 (i = 1; j = 0; i = 0; j = 1);
    // result[i] = result[i-1] + 1 if i <= CHUNK_NUMBER else result[i-1] - 1 (middle, main diagonal)
    
    signal tmpResult[CHUNK_NUMBER * 2 - 1][CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER * 2 - 1; i++){
        
        if (i < CHUNK_NUMBER){
            for (var j = 0; j < i + 1; j++){
                if (j == 0){
                    tmpResult[i][j] <== tmpMults[i - j][j];
                } else {
                    tmpResult[i][j] <== tmpMults[i - j][j] + tmpResult[i][j - 1];
                }
            }
            out[i] <== tmpResult[i][i];
            
        } else {
            for (var j = 0; j < 2 * CHUNK_NUMBER - 1 - i; j++){
                if (j == 0){
                    tmpResult[i][j] <== tmpMults[CHUNK_NUMBER - 1 - j][i + j - CHUNK_NUMBER + 1];
                } else {
                    tmpResult[i][j] <== tmpMults[CHUNK_NUMBER - 1 - j][i + j - CHUNK_NUMBER + 1] + tmpResult[i][j - 1];
                }
            }
            out[i] <== tmpResult[i][2 * CHUNK_NUMBER - 2 - i];
            
        }
    }
}

template BigMult(CHUNK_SIZE, CHUNK_NUMBER){
    
    signal input in[2][CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER * 2];
    
    component bigMultNoCarry = BigMultNoCarry(CHUNK_SIZE, CHUNK_NUMBER);
    bigMultNoCarry.in <== in;
    
    component num2bits[CHUNK_NUMBER * 2 - 1];
    component bits2numOverflow[CHUNK_NUMBER * 2 - 1];
    component bits2numModulus[CHUNK_NUMBER * 2 - 1];
    
    //overflow = no carry (multiplication result / 2 ** chunk_size) === chunk_size first bits in result
    for (var i = 0; i < 2 * CHUNK_NUMBER - 1; i++){
        //bigMultNoCarry = CHUNK_i * CHUNK_j (2 * CHUNK_SIZE) + CHUNK_i0 * CHUNK_j0 (2 * CHUNK_SIZE) + ..., up to len times, => 2 * CHUNK_SIZE + ADDITIONAL_LEN
        var ADDITIONAL_LEN = i;
        if (i >= CHUNK_NUMBER){
            ADDITIONAL_LEN = 2 * CHUNK_NUMBER - 2 - i;
        }

        num2bits[i] = Num2Bits(CHUNK_SIZE * 2 + ADDITIONAL_LEN);

        if (i == 0 ){
            num2bits[i].in <== bigMultNoCarry.out[i];
        } else {
            num2bits[i].in <== bigMultNoCarry.out[i] + bits2numOverflow[i-1].out;
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
            out[i] <== bits2numOverflow[i-1].out;
        } else {
            out[i] <== bits2numModulus[i].out;
        }
    }
}
