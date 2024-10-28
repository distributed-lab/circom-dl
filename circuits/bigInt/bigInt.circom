pragma circom 2.1.6;

//move to directory and refactor
include "../../node_modules/circomlib/circuits/comparators.circom";

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
            log(out[i]);
        } else {
            for (var j = 0; j < 2 * CHUNK_NUMBER - 1 - i; j++){
                if (j == 0){
                    tmpResult[i][j] <== tmpMults[CHUNK_NUMBER - 1 - j][i + j - CHUNK_NUMBER + 1];
                } else {
                    tmpResult[i][j] <== tmpMults[CHUNK_NUMBER - 1 - j][i + j - CHUNK_NUMBER + 1] + tmpResult[i][j - 1];
                }
            }
            out[i] <== tmpResult[i][2 * CHUNK_NUMBER - 2 - i];
            log(out[i]);

        }
    }
}