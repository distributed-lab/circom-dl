pragma circom  2.1.6;

include "bigIntHelpers.circom";
include "bigIntOverflow2.circom";
include "bigIntComparators.circom";
include "../bitify/bitify.circom";

// What BigInt in this lib means
// We represent big number as array of chunks with some shunk_size (will be explained later) 
// for this example we will use N for number, n for chunk size and k for chunk_number:
// N[k];
// Number can be calculated by this formula:
// N = N[0] * 2 ** (0 * n) + N[1] * 2 ** (1 * n) + ... + N[k - 1] * 2 ** ((k-1) * n)
// By overflow we mean situation where N[i] >= 2 ** n
// Without overflow every number has one and only one representation
// To reduce overflow we must leave N[i] % 2 ** n for N[i] and add N[i] // 2 ** n to N[i + 1]
// If u want to do many operation in a row, it is better to use overflow operations from "./bigIntOverflow" and then just reduce overflow from result

// If u want to convert any number to this representation, u can this python3 function:
// ```
// def bigint_to_array(n, k, x):
//     # Initialize mod to 1 (Python's int can handle arbitrarily large numbers)
//     mod = 1
//     for idx in range(n):
//         mod *= 2
//     # Initialize the return list
//     ret = []
//     x_temp = x
//     for idx in range(k):
//         # Append x_temp mod mod to the list
//         ret.append(str(x_temp % mod))
//         # Divide x_temp by mod for the next iteration
//         x_temp //= mod  # Use integer division in Python
//     return ret
// ```

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// Get sum of each chunk with same positions
// Out has no overflow and has CHUNK_NUMBER_GREATER + 1 chunks
template BigAdd(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS){
    
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input dummy;
    
    signal output out[CHUNK_NUMBER_GREATER + 1];
    
    component num2bits[CHUNK_NUMBER_GREATER];
    
    component bigAddOverflow = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS);
    bigAddOverflow.in1 <== in1;
    bigAddOverflow.in2 <== in2;
    bigAddOverflow.dummy <== dummy;
    
    for (var i = 0; i < CHUNK_NUMBER_GREATER; i++){
        num2bits[i] = Num2Bits(CHUNK_SIZE + 1);
        
        //if >= 2**CHUNK_SIZE, overflow
        if (i == 0){
            num2bits[i].in <== bigAddOverflow.out[i];
        } else {
            num2bits[i].in <== bigAddOverflow.out[i] + num2bits[i - 1].out[CHUNK_SIZE] + dummy * dummy;
        }
    }
    
    for (var i = 0; i < CHUNK_NUMBER_GREATER; i++){
        if (i == 0) {
            out[i] <== bigAddOverflow.out[i] - (num2bits[i].out[CHUNK_SIZE]) * (2 ** CHUNK_SIZE) + dummy * dummy;
        }
        else {
            out[i] <== bigAddOverflow.out[i] - (num2bits[i].out[CHUNK_SIZE]) * (2 ** CHUNK_SIZE) + num2bits[i - 1].out[CHUNK_SIZE] + dummy * dummy;
        }
    }
    out[CHUNK_NUMBER_GREATER] <== num2bits[CHUNK_NUMBER_GREATER - 1].out[CHUNK_SIZE];
}

// Get multiplication of 2 numbers with CHUNK_NUMBER chunks
// out is 2 * CHUNK_NUMBER chunks without overflows
template BigMult(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS){
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input dummy;
    signal output out[CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS];
    
    component bigMultOverflow = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS);
    bigMultOverflow.in1 <== in1;
    bigMultOverflow.in2 <== in2;
    bigMultOverflow.dummy <== dummy;
    
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
            num2bits[i].in <== bigMultOverflow.out[i];
        } else {
            num2bits[i].in <== bigMultOverflow.out[i] + bits2numOverflow[i - 1].out + dummy * dummy;
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
}

// Get base % modulus and base // modulus
template BigMod(CHUNK_SIZE, CHUNK_NUMBER_BASE, CHUNK_NUMBER_MODULUS){
    assert(CHUNK_NUMBER_BASE <= 252);
    assert(CHUNK_NUMBER_MODULUS <= 252);
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
        mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER_DIV, CHUNK_NUMBER_MODULUS);
        mult.dummy <== dummy;
        
        mult.in1 <== div;
        mult.in2 <== modulus;
    } else {
        mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER_MODULUS, CHUNK_NUMBER_DIV);
        mult.dummy <== dummy;
        
        mult.in2 <== div;
        mult.in1 <== modulus;
    }
    
    for (var i = CHUNK_NUMBER_BASE - 1; i < CHUNK_NUMBER_MODULUS + CHUNK_NUMBER_DIV - 1; i++){
        mult.out[i] === 0;
    }
    
    component checkCarry = BigIntIsZero(CHUNK_SIZE, CHUNK_SIZE * 2 + log_ceil(CHUNK_NUMBER_MODULUS + CHUNK_NUMBER_DIV - 1), CHUNK_NUMBER_BASE);
    for (var i = 0; i < CHUNK_NUMBER_MODULUS; i++) {
        checkCarry.in[i] <== base[i] - mult.out[i] - mod[i];
    }
    for (var i = CHUNK_NUMBER_MODULUS; i < CHUNK_NUMBER_BASE; i++) {
        checkCarry.in[i] <== base[i] - mult.out[i];
    }
}

// Get in1 * in2 % modulus and in1 * in2 // modulus
template BigMultModP(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS, CHUNK_NUMBER_MODULUS){
    signal input in1[CHUNK_NUMBER_GREATER];
    signal input in2[CHUNK_NUMBER_LESS];
    signal input modulus[CHUNK_NUMBER_MODULUS];
    signal input dummy;
    
    var CHUNK_NUMBER_BASE = CHUNK_NUMBER_GREATER + CHUNK_NUMBER_LESS;
    var CHUNK_NUMBER_DIV = CHUNK_NUMBER_BASE - CHUNK_NUMBER_MODULUS + 1;

    signal output div[CHUNK_NUMBER_DIV];
    signal output mod[CHUNK_NUMBER_MODULUS];
    
    component mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER_GREATER, CHUNK_NUMBER_LESS);
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
    
    component isZero = BigIntIsZero(CHUNK_SIZE, CHUNK_SIZE * 2 + log_ceil(CHUNK_NUMBER_MODULUS + CHUNK_NUMBER_DIV - 1), CHUNK_NUMBER_BASE - 1);
    for (var i = 0; i < CHUNK_NUMBER_MODULUS; i++) {
        isZero.in[i] <== mult.out[i] - mult2.out[i] - mod[i];
    }
    for (var i = CHUNK_NUMBER_MODULUS; i < CHUNK_NUMBER_BASE - 1; i++) {
        isZero.in[i] <== mult.out[i] - mult2.out[i];
    }
}

// Computes CHUNK_NUMBER number power with EXP = exponent
// EXP is default num, not chunked bigInt!!!
// CHUNK_NUMBER_BASE == CHUNK_NUMBER_MODULUS because other options don`t have much sense:
// if CHUNK_NUMBER_BASE > CHUNK_NUMBER_MODULUS, do one mod before and get less constraints
// if CHUNK_NUMBER_BASE < CHUNK_NUMBER_MODULUS, just put zero in first one, this won`t affect at constraints
// we will get CHUNK_NUMBER_MODULUS num after first multiplication anyway
template PowerMod(CHUNK_SIZE, CHUNK_NUMBER, EXP) {

    assert(EXP >= 2);
    
    signal input base[CHUNK_NUMBER];
    signal input modulus[CHUNK_NUMBER];
    signal input dummy;
    
    signal output out[CHUNK_NUMBER];
    
    var exp_process[256] = exp_to_bits(EXP);
    
    component muls[exp_process[0]];
    component resultMuls[exp_process[1] - 1];
    
    for (var i = 0; i < exp_process[0]; i++){
        muls[i] = BigMultModP(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, CHUNK_NUMBER);
        muls[i].dummy <== dummy;
        muls[i].modulus <== modulus;
    }
    
    for (var i = 0; i < exp_process[1] - 1; i++){
        resultMuls[i] = BigMultModP(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, CHUNK_NUMBER);
        resultMuls[i].dummy <== dummy;
        resultMuls[i].modulus <== modulus;
    }
    
    muls[0].in1 <== base;
    muls[0].in2 <== base;
    
    for (var i = 1; i < exp_process[0]; i++){
        muls[i].in1 <== muls[i - 1].mod;
        muls[i].in2 <== muls[i - 1].mod;
    }
    
    for (var i = 0; i < exp_process[1] - 1; i++){
        if (i == 0){
            if (exp_process[i + 2] == 0){
                resultMuls[i].in1 <== base;
            } else {
                resultMuls[i].in1 <== muls[exp_process[i + 2] - 1].mod;
            }
            resultMuls[i].in2 <== muls[exp_process[i + 3] - 1].mod;
        }
        else {
            resultMuls[i].in1 <== resultMuls[i - 1].mod;
            resultMuls[i].in2 <== muls[exp_process[i + 3] - 1].mod;
        }
    }

    if (exp_process[1] == 1){
        out <== muls[exp_process[0] - 1].mod;
    } else {
        out <== resultMuls[exp_process[1] - 2].mod;
    }
}


// calculates in ^ (-1) % modulus;
// in, modulus has CHUNK_NUMBER
template BigModInv(CHUNK_SIZE, CHUNK_NUMBER) {
    assert(CHUNK_SIZE <= 252);
    signal input in[CHUNK_NUMBER];
    signal input modulus[CHUNK_NUMBER];
    signal output out[CHUNK_NUMBER];
    
    signal input dummy;
    dummy * dummy === 0;
    
    var inv[200] = mod_inv(CHUNK_SIZE, CHUNK_NUMBER, in, modulus);
    for (var i = 0; i < CHUNK_NUMBER; i++) {
        out[i] <-- inv[i];
    }
    
    component mult = BigMultModP(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, CHUNK_NUMBER);
    mult.in1 <== in;
    mult.in2 <== out;
    mult.modulus <== modulus;
    mult.dummy <== dummy;
    
    mult.mod[0] === 1;
    for (var i = 1; i < CHUNK_NUMBER; i++) {
        mult.mod[i] === 0;
    }
}