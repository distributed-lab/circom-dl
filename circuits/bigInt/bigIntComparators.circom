pragma circom  2.1.6;

include "../bitify/comparators.circom";

//-------------------------------------------------------------------------------------------------------------------------------------------------
// Comparators for big numbers

// For next 4 templates interface is the same, difference is only compare operation (<, <=, >, >=)
// input are in[2][CHUNK_NUMBER]
// there is no overflow allowed, so chunk are equal, otherwise this is no sense
// those are very "expensive" by constraints operations, try to reduse num of usage if these if u can

// in[0] < in[1]
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

// in[0] <= in[1]
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

// in[0] > in[1]
template BigGreaterThan(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    
    signal output out;
    
    component lessEqThan = BigLessEqThan(CHUNK_SIZE, CHUNK_NUMBER);
    lessEqThan.in <== in;
    out <== 1 - lessEqThan.out;
}

// in[0] >= in[1]
template BigGreaterEqThan(CHUNK_SIZE, CHUNK_NUMBER){
    signal input in[2][CHUNK_NUMBER];
    
    signal output out;
    
    component lessThan = BigLessThan(CHUNK_SIZE, CHUNK_NUMBER);
    lessThan.in <== in;
    out <== 1 - lessThan.out;
}

// Check for BigInt is zero, fail if it isn`t
// Works with overflowed signed chunks
// Can check for 2 bigints equality if in is sub of each chunk of those numbers
template BigIntIsZero(CHUNK_SIZE, MAX_CHUNK_SIZE, CHUNK_NUMBER) {
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
