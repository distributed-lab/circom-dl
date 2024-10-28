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
            greaterThan[i].in[0] <== bigAddNoCarry.out[i] + greaterThan[i-1].out;
            greaterThan[i].in[1] <== 2 ** CHUNK_SIZE;
        }
    }
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        if (i == 0){
            out[i] <== bigAddNoCarry.out[i] - (greaterThan[i].out) * (2 ** CHUNK_SIZE);
        }
        else{
            out[i] <== bigAddNoCarry.out[i] - (greaterThan[i].out) * (2 ** CHUNK_SIZE) + greaterThan[i-1].out;
        }
    }
    out[CHUNK_NUMBER] <== greaterThan[CHUNK_NUMBER-1].out;
}
