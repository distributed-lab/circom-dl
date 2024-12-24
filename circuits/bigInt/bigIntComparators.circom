pragma circom  2.1.6;

include "../bitify/comparators.circom";
include "../bitify/bitify.circom";
include "../utils/switcher.circom";

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
    for (var i = 0; i < CHUNK_NUMBER - 1; i++){
        if (i == 0){
            carry[i] <== in[i] / 2 ** CHUNK_SIZE;
        }
        else {
            carry[i] <== (in[i] + carry[i - 1]) / 2 ** CHUNK_SIZE;
        }
    }
    component carryRangeCheck = Num2Bits(MAX_CHUNK_SIZE + EPSILON - CHUNK_SIZE);
    carryRangeCheck.in <== carry[CHUNK_NUMBER - 2] + (1 << (MAX_CHUNK_SIZE + EPSILON - CHUNK_SIZE - 1));
    in[CHUNK_NUMBER - 1] + carry[CHUNK_NUMBER - 2] === 0;
}

// checks for in % p == 0
template BigIntIsZeroModP(CHUNK_SIZE, MAX_CHUNK_SIZE, CHUNK_NUMBER, MAX_CHUNK_NUMBER, CHUNK_NUMBER_MODULUS){
    signal input in[CHUNK_NUMBER];
    signal input modulus[CHUNK_NUMBER_MODULUS];
    signal input dummy;
    
    var CHUNK_NUMBER_DIV = MAX_CHUNK_NUMBER - CHUNK_NUMBER_MODULUS + 1;
    
    var reduced[200] = reduce_overflow_signed(CHUNK_SIZE, CHUNK_NUMBER, MAX_CHUNK_NUMBER, MAX_CHUNK_SIZE, in);
    var div_result[2][200] = long_div(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV - 1, reduced, modulus);
    signal sign <-- reduced[199];
    sign * (1 - sign) === 0;
    component mult;
    if (CHUNK_NUMBER_DIV >= CHUNK_NUMBER_MODULUS){
        mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER_DIV, CHUNK_NUMBER_MODULUS);
        mult.in2 <== modulus;
        mult.dummy <== dummy;
        for (var i = 0; i < CHUNK_NUMBER_DIV; i++){
            mult.in1[i] <-- div_result[0][i];
        }
    } else {
        mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV);
        mult.in1 <== modulus;
        mult.dummy <== dummy;
        for (var i = 0; i < CHUNK_NUMBER_DIV; i++){
            mult.in2[i] <-- div_result[0][i];
        }
    }
    
    component swicher[CHUNK_NUMBER];

    component isZero = BigIntIsZero(CHUNK_SIZE, MAX_CHUNK_SIZE, MAX_CHUNK_NUMBER);
    for (var i = 0; i < CHUNK_NUMBER; i++){
        swicher[i] = Switcher();
        swicher[i].in[0] <== in[i];
        swicher[i].in[1] <== -in[i];
        swicher[i].bool <== sign;

        isZero.in[i] <== mult.out[i] - swicher[i].out[1];
    }
    for (var i = CHUNK_NUMBER; i < MAX_CHUNK_NUMBER; i++){
        isZero.in[i] <== mult.out[i];
    }
    
}