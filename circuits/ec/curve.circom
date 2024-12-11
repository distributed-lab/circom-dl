pragma circom  2.1.6;

include "../bigInt/bigIntOverflow.circom";
include "../bigInt/bigIntFunc.circom";
include "./powers/secp256k1pows.circom";
include "./powers/brainpoolP256r1pows.circom";
include "./powers/brainpoolP384r1pows.circom";
include "./powers/brainpoolP224r1pows.circom";
include "./powers/p256pows.circom";
include "./powers/p384pows.circom";
include "./powers/secp521r1pows.circom";
include "../bitify/bitify.circom";
include "../bitify/comparators.circom";
include "../int/arithmetic.circom";
include "./get.circom";
include "../utils/switcher.circom";

// Operation for any Weierstrass prime-field eliptic curve (for now 256-bit)
// A, B, P in every function - params of needed curve, chunked the same as every other chunking (64 4 for now)
// Example usage of operation (those are params for secp256k1 ec):
// EllipticCurveDoubleOptimised(64, 4, [0,0,0,0], [7,0,0,0], [18446744069414583343, 18446744073709551615, 18446744073709551615, 18446744073709551615]);
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
// To add a new curve u should do next steps:
// Get curve params(A, B, P) in chunked representation
// Change params at 1..8 lines in "../../helpers/generate_get_for_new_curve.py" for your curve params, then execute script from root, this will update ./get.circom file
// DON`T USE FOR ALREADY ADDED CURVE, THIS WILL LEAD TO ERROR!!!!!
// Script also will not work for new chunking (for now 64 4 and 64 6), add first one by yourself 
// (truly, this is actual not for whole chunking, but for chunk_number, chunk_size doesn`t matter, just check for asserts in templates if u need to add an other one)
// Change params at 4..8 lines in "../../helpers/generate_pow_table_for_curve.py" for your curve params, then execute script from root, this will create file in ./powers
// Add import to it here:
// include "./powers/{curve name}pows.circom";
// in template "EllipicCurveScalarGeneratorMultiplicationOptimised" for 64 4 chunking or "EllipicCurveScalarGeneratorMultiplicationNonOptimised" for other add new if for getting powers
// var powers[parts][2 ** STRIDE][2][CHUNK_NUMBER];
// if (P[0] == 18446744069414583343 && P[1] == 18446744073709551615 && P[2] == 18446744073709551615 && P[3] == 18446744073709551615){ // change to your P chunking
    //     powers = get_g_pow_stride8_table_secp256k1(CHUNK_SIZE, CHUNK_NUMBER);                                                      // change to your func name
    // }
// Now u can succesfully execute all functions for your curve
// EllipicCurveScalarPrecomputeMultiplication still needs precomputed table
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Don`t use next templates within default point operations without understanding what are u doing, default curve operations will be below

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
// They work fine, were used for deprecated methods
// THEY ARE NOT ENOUGHT TO CHECK ADDITION / DOUBLING, ANY Y CALCULATED BY CORRECT FORMULA FOR ANY WILL GIVE CORRECT RESULT

// Check is point on tangent (for doubling check)
// (x, y), point that was doubled, (x3, y3) - result 
// λ = (3 * x ** 2 + a) / (2 * y)
// y3 = λ * (x - x3) - y
template TangentCheck(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    assert(CHUNK_SIZE == 64);
    
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal input dummy;
    
    
    dummy * dummy === 0;
    
    component mult = BigMultOptimisedOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult.in[0] <== in1[0];
    mult.in[1] <== in1[0];
    mult.dummy <== dummy;
    
    component scalarMult = ScalarMultOverflow(CHUNK_NUMBER * 2 - 1);
    scalarMult.scalar <== 3;
    scalarMult.in <== mult.out;
    
    component add = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add.in1 <== scalarMult.out;
    add.in2 <== A;
    add.dummy <== dummy;
    
    component scalarMult2 = ScalarMultOverflow(CHUNK_NUMBER);
    scalarMult2.in <== in1[1];
    scalarMult2.scalar <== 2;
    
    component modInv = BigModInvOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    modInv.in <== scalarMult2.out;
    modInv.modulus <== P;
    modInv.dummy <== dummy;
    
    component mul2 = BigMultNonEqualOverflow(CHUNK_SIZE, 2 * CHUNK_NUMBER - 1, CHUNK_NUMBER);
    mul2.in1 <== add.out;
    mul2.in2 <== modInv.out;
    mul2.dummy <== dummy;
    
    component mod = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 3);
    mod.base <== mul2.out;
    mod.modulus <== P;
    mod.dummy <== dummy;
    
    component sub = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub.in1 <== in1[0];
    sub.in2 <== in2[0];
    sub.modulus <== P;
    sub.dummy <== dummy;
    
    component mul3 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    mul3.in1 <== mod.mod;
    mul3.in2 <== sub.out;
    mul3.dummy <== dummy;
    
    component mod2 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod2.base <== mul3.out;
    mod2.modulus <== P;
    mod2.dummy <== dummy;
    
    component sub2 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub2.in1 <== mod2.mod;
    sub2.in2 <== in1[1];
    sub2.modulus <== P;
    sub2.dummy <== dummy;
    
    component add2 = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    add2.in[0] <== P;
    add2.in[1] <== in2[1];
    add2.dummy <== dummy;
    
    component smartEqual = SmartEqual(CHUNK_SIZE, CHUNK_NUMBER);
    smartEqual.in[0] <== sub2.out;
    smartEqual.in[1] <== add2.out;
    smartEqual.dummy <== dummy;
    
    component smartEqual2 = SmartEqual(CHUNK_SIZE, CHUNK_NUMBER);
    smartEqual2.in[0] <== sub2.out;
    smartEqual2.in[1] <== in2[1];
    smartEqual2.dummy <== dummy;
    
    smartEqual.out * smartEqual.out + smartEqual2.out === 1;
}

// Check is point on slope (for adding check)
// (x1, y1), (x2, y2) - point that were added to each other, (x3, y3) - result 
// λ = (y2 - y1) / (x2 - x1)
// y3​ == λ * (x1 ​− x3​) − y1
template AdditionCheck(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    // assert(CHUNK_SIZE == 64);
    
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal input in3[2][CHUNK_NUMBER];
    signal input dummy;
    
    component sub = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub.in1 <== in2[0];
    sub.in2 <== in1[0];
    sub.modulus <== P;
    sub.dummy <== dummy;
    
    component sub2 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub2.in1 <== in2[1];
    sub2.in2 <== in1[1];
    sub2.modulus <== P;
    sub2.dummy <== dummy;
    
    component sub3 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub3.in1 <== in1[0];
    sub3.in2 <== in3[0];
    sub3.modulus <== P;
    sub3.dummy <== dummy;
    
    component modInv = BigModInvOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    modInv.in <== sub.out;
    modInv.modulus <== P;
    modInv.dummy <== dummy;
    
    component mul = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mul.in[0] <== sub2.out;
    mul.in[1] <== modInv.out;
    mul.dummy <== dummy;
    
    component mul2 = BigMultNonEqualOverflow(CHUNK_SIZE, 2 * CHUNK_NUMBER - 1, CHUNK_NUMBER);
    mul2.in1 <== mul.out;
    mul2.in2 <== sub3.out;
    mul2.dummy <== dummy;
    
    component mod = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 2);
    mod.base <== mul2.out;
    mod.modulus <== P;
    mod.dummy <== dummy;
    
    component sub4 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub4.in1 <== mod.mod;
    sub4.in2 <== in1[1];
    sub4.modulus <== P;
    sub4.dummy <== dummy;
    
    component add = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    add.in[0] <== P;
    add.in[1] <== in3[1];
    add.dummy <== dummy;
    
    component smartEqual = SmartEqual(CHUNK_SIZE, CHUNK_NUMBER);
    smartEqual.in[0] <== sub4.out;
    smartEqual.in[1] <== add.out;
    smartEqual.dummy <== dummy;
    
    component smartEqual2 = SmartEqual(CHUNK_SIZE, CHUNK_NUMBER);
    smartEqual2.in[0] <== sub4.out;
    smartEqual2.in[1] <== in3[1];
    smartEqual2.dummy <== dummy;
    
    smartEqual.out * smartEqual.out + smartEqual2.out === 1;
    
}
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Helpers templates, don`t use them outside if u don`t know what are u doing

// Precomputes for pipinger optimised multiplication
// Computes 0 * G, 1 * G, 2 * G, ... (2 ** WINDOW_SIZE - 1) * G
template EllipticCurvePrecomputePipinger(CHUNK_SIZE, CHUNK_NUMBER, A, B, P, WINDOW_SIZE){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    
    var PRECOMPUTE_NUMBER = 2 ** WINDOW_SIZE;
    
    signal output out[PRECOMPUTE_NUMBER][2][CHUNK_NUMBER];
    dummy * dummy === 0;
    
    for (var i = 0; i < 2; i++){
        for (var j = 0; j < CHUNK_NUMBER; j++){
            out[0][i][j] <== 0;
        }
    }
    
    out[1] <== in;
    
    component doublers[PRECOMPUTE_NUMBER \ 2 - 1];
    component adders  [PRECOMPUTE_NUMBER \ 2 - 1];
    
    for (var i = 2; i < PRECOMPUTE_NUMBER; i++){
        if (i % 2 == 0){
            doublers[i \ 2 - 1] = EllipticCurveDouble(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
            doublers[i \ 2 - 1].in <== out[i \ 2];
            doublers[i \ 2 - 1].dummy <== dummy;
            doublers[i \ 2 - 1].out ==> out[i];
            
        }
        else {
            adders[i \ 2 - 1] = EllipticCurveAdd(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
            adders[i \ 2 - 1].in1 <== out[1];
            adders[i \ 2 - 1].in2 <== out[i - 1];
            adders[i \ 2 - 1].dummy <== dummy;
            adders[i \ 2 - 1].out ==> out[i];
        }
    }
}

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Default point operations, use them for ec calculations

// Check if given point lies on curve
// y ** 2 % p === (x ** 3 + a * x + b) % p
// fail if point isn`t on curve, otherwise pass
template PointOnCurveOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    assert(CHUNK_SIZE == 64);
    
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    component mult = BigMultOptimisedOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult.in[0] <== in[0];
    mult.in[1] <== in[0];
    mult.dummy <== dummy;
    
    component mult2 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    mult2.in1 <== mult.out;
    mult2.in2 <== in[0];
    mult2.dummy <== dummy;
    
    component mult3 = BigMultOptimisedOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult3.in[0] <== in[0];
    mult3.in[1] <== A;
    mult3.dummy <== dummy;
    
    component mult4 = BigMultOptimisedOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult4.in[0] <== in[1];
    mult4.in[1] <== in[1];
    mult4.dummy <== dummy;
    
    component add = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER * 2 - 1);
    add.in1 <== mult2.out;
    add.in2 <== mult3.out;
    add.dummy <== dummy;
    
    component add2 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER);
    add2.in1 <== add.out;
    add2.in2 <== B;
    add2.dummy <== dummy;
    
    component mod = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod.base <== mult4.out;
    mod.modulus <== P;
    mod.dummy <== dummy;
    
    component mod2 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 3);
    mod2.base <== add2.out;
    mod2.modulus <== P;
    mod2.dummy <== dummy;
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        mod.mod[i] === mod2.mod[i];
    }
    
}

// λ = (3 * x ** 2 + a) / (2 * y)
// x3 = λ * λ - 2 * x
// y3 = λ * (x - x3) - y
// calculate doubled point
template EllipticCurveDoubleOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in[2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    // x * x
    component mult = BigMultOptimisedOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult.in[0] <== in[0];
    mult.in[1] <== in[0];
    mult.dummy <== dummy;
    
    // 3 * x * x
    component scalarMult = ScalarMultOverflow(CHUNK_NUMBER * 2 - 1);
    scalarMult.scalar <== 3;
    scalarMult.in <== mult.out;
    
    // 3 * x * x + a
    component add = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add.in1 <== scalarMult.out;
    add.in2 <== A;
    add.dummy <== dummy;
    
    // 2 * y
    component scalarMult2 = ScalarMultOverflow(CHUNK_NUMBER);
    scalarMult2.in <== in[1];
    scalarMult2.scalar <== 2;
    
    // (2 * y) ** -1
    component modInv = BigModInvOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    modInv.in <== scalarMult2.out;
    modInv.modulus <== P;
    modInv.dummy <== dummy;
    
    // (3 * x * x + a) * 1 / (2 * y)
    component mult2 = BigMultNonEqualOverflow(CHUNK_SIZE, 2 * CHUNK_NUMBER - 1, CHUNK_NUMBER);
    mult2.in1 <== add.out;
    mult2.in2 <== modInv.out;
    mult2.dummy <== dummy;
    
    // ((3 * x * x + a) * 1 / (2 * y)) % p ==> λ
    component mod = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 3);
    mod.base <== mult2.out;
    mod.modulus <== P;
    mod.dummy <== dummy;
    
    // λ * λ
    component mult3 = BigMultOptimisedOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult3.in[0] <== mod.mod;
    mult3.in[1] <== mod.mod;
    mult3.dummy <== dummy;
    
    // P - x
    component sub = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub.in1 <== P;
    sub.in2 <== in[0];
    sub.modulus <== P;
    sub.dummy <== dummy;
    
    // 2 * P - 2 * x
    component scalarMult3 = ScalarMultOverflow(CHUNK_NUMBER);
    scalarMult3.in <== sub.out;
    scalarMult3.scalar <== 2;
    
    // λ * λ + 2 * P - 2 * x
    component add2 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add2.in1 <== mult3.out;
    add2.in2 <== scalarMult3.out;
    add2.dummy <== dummy;
    
    // (λ * λ + 2 * P - 2 * x) % p ==> x3
    component mod2 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod2.base <== add2.out;
    mod2.modulus <== P;
    mod2.dummy <== dummy;
    
    out[0] <== mod2.mod;
    
    // x1 - x3
    component sub2 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub2.in1 <== in[0];
    sub2.in2 <== out[0];
    sub2.modulus <== P;
    sub2.dummy <== dummy;
    
    // λ * (x1 - x3)
    component mult4 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    mult4.in1 <== mod.mod;
    mult4.in2 <== sub2.out;
    mult4.dummy <== dummy;
    
    // P - y
    component sub3 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub3.in1 <== P;
    sub3.in2 <== in[1];
    sub3.modulus <== P;
    sub3.dummy <== dummy;
    
    // λ * (x1 - x3) + P - y
    component add3 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add3.in1 <== mult4.out;
    add3.in2 <== sub3.out;
    add3.dummy <== dummy;
    
    // (λ * (x1 - x3) + P - y) % P ==> y3
    component mod3 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod3.base <== add3.out;
    mod3.modulus <== P;
    mod3.dummy <== dummy;
    
    out[1] <== mod3.mod;
}

// λ = (y2 - y1) / (x2 - x1)
// x3 = λ * λ - x1 - x2
// y3 = λ * (x1 - x3) - y1
// calculate sum of 2 points
template EllipticCurveAddOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    // x2 - x1
    component sub = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub.in1 <== in2[0];
    sub.in2 <== in1[0];
    sub.modulus <== P;
    sub.dummy <== dummy;
    
    // y2 - y1
    component sub2 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub2.in1 <== in2[1];
    sub2.in2 <== in1[1];
    sub2.modulus <== P;
    sub2.dummy <== dummy;
    
    // (x2 - x1) ** -1
    component modInv = BigModInvOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    modInv.in <== sub.out;
    modInv.modulus <== P;
    modInv.dummy <== dummy;
    
    // (y2 - y1) * 1 / (x2 - x1)
    component mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult.in[0] <== sub2.out;
    mult.in[1] <== modInv.out;
    mult.dummy <== dummy;
    
    // (y2 - y1) * 1 / (x2 - x1) % P ==> λ
    component mod = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod.base <== mult.out;
    mod.modulus <== P;
    mod.dummy <== dummy;
    
    // λ * λ
    component mult2 = BigMultOptimisedOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult2.in[0] <== mod.mod;
    mult2.in[1] <== mod.mod;
    mult2.dummy <== dummy;
    
    // P - in1
    component sub3 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub3.in1 <== P;
    sub3.in2 <== in1[0];
    sub3.modulus <== P;
    sub3.dummy <== dummy;
    
    // P - in2
    component sub4 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub4.in1 <== P;
    sub4.in2 <== in2[0];
    sub4.modulus <== P;
    sub4.dummy <== dummy;
    
    // 2 * P - in1 - in2
    component add = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    add.in[0] <== sub3.out;
    add.in[1] <== sub4.out;
    add.dummy <== dummy;
    
    // λ * λ + 2 * P - in1 - in2
    component add2 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add2.in1 <== mult2.out;
    add2.in2 <== add.out;
    add2.dummy <== dummy;
    
    // (λ * λ + 2 * P - in1 - in2) % P ==> x3
    component mod2 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod2.base <== add2.out;
    mod2.modulus <== P;
    mod2.dummy <== dummy;
    
    out[0] <== mod2.mod;
    
    // x1 - x3
    component sub5 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub5.in1 <== in1[0];
    sub5.in2 <== out[0];
    sub5.modulus <== P;
    sub5.dummy <== dummy;
    
    // λ * (x1 - x3)
    component mult3 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    mult3.in1 <== mult.out;
    mult3.in2 <== sub5.out;
    mult3.dummy <== dummy;
    
    // P - y1
    component sub6 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub6.in1 <== P;
    sub6.in2 <== in1[1];
    sub6.modulus <== P;
    sub6.dummy <== dummy;
    
    // λ * (x1 - x3) + P - y1
    component add3 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER);
    add3.in1 <== mult3.out;
    add3.in2 <== sub6.out;
    add3.dummy <== dummy;
    
    // (λ * (x1 - x3) + P - y1) % P ==> y3
    component mod3 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 3);
    mod3.base <== add3.out;
    mod3.modulus <== P;
    mod3.dummy <== dummy;
    
    out[1] <== mod3.mod;
}

// calculate G * scalar
// Now works for secp256k1 and BrainpoolP256r1, to add other curve see header
// To make it work for other curve u should generate generator pow table
// Other curves will be added by ourself soon
// Will fail if scalar == 0, don`t do it
// Complexity is 31 additions for 256 curves
template EllipicCurveScalarGeneratorMultiplicationOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    assert(CHUNK_SIZE == 64 && CHUNK_NUMBER == 4 || CHUNK_SIZE == 66 && CHUNK_NUMBER == 8);
    
    signal input scalar[CHUNK_NUMBER];
    signal input dummy;
    
    signal output out[2][CHUNK_NUMBER];
    
    var STRIDE = 8;
    
    var parts = CHUNK_NUMBER * CHUNK_SIZE \ STRIDE;
    
    dummy * dummy === 0;
    var powers[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    if (CHUNK_NUMBER == 4){
        if (P[0] == 18446744069414583343 && P[1] == 18446744073709551615 && P[2] == 18446744073709551615 && P[3] == 18446744073709551615){
            powers = get_g_pow_stride8_table_secp256k1(CHUNK_SIZE, CHUNK_NUMBER);
        }
        if (P[0] == 2311270323689771895 && P[1] == 7943213001558335528 && P[2] == 4496292894210231666 && P[3] == 12248480212390422972){
            powers = get_g_pow_stride8_table_brainpoolP256r1(CHUNK_SIZE, CHUNK_NUMBER);
        }
        if (P[0] == 18446744073709551615 && P[1] == 4294967295 && P[2] == 0 && P[3] == 18446744069414584321) {
            powers = get_g_pow_stride8_table_p256(CHUNK_SIZE, CHUNK_NUMBER);
        }
    }
    if (CHUNK_NUMBER == 8 && CHUNK_SIZE == 66){
        if (P[0] == 73786976294838206463 && P[1] == 73786976294838206463 && P[2] == 73786976294838206463 && P[3] == 73786976294838206463 && P[4] == 73786976294838206463 && P[5] == 73786976294838206463 && P[6] == 73786976294838206463 && P[7] == 576460752303423487){
            powers = get_g_pow_stride8_table_secp521r1(CHUNK_SIZE, CHUNK_NUMBER);
        }
    }
    
    component num2bits[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        num2bits[i] = Num2Bits(CHUNK_SIZE);
        num2bits[i].in <== scalar[i];
    }
    component bits2num[parts];
    for (var i = 0; i < parts; i++){
        bits2num[i] = Bits2Num(STRIDE);
        for (var j = 0; j < STRIDE; j++){
            bits2num[i].in[j] <== num2bits[(i * STRIDE + j) \ CHUNK_SIZE].out[(i * STRIDE + j) % CHUNK_SIZE];
        }
    }
    
    component equal[parts][2 ** STRIDE];
    signal resultCoordinateComputation[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    for (var i = 0; i < parts; i++){
        for (var j = 0; j < 2 ** STRIDE; j++){
            equal[i][j] = IsEqual();
            equal[i][j].in[0] <== j;
            equal[i][j].in[1] <== bits2num[i].out;
            
            
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                resultCoordinateComputation[i][j][0][axis_idx] <== equal[i][j].out * powers[i][j][0][axis_idx];
            }
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                resultCoordinateComputation[i][j][1][axis_idx] <== equal[i][j].out * powers[i][j][1][axis_idx];
            }
            
            
        }
    }
    
    component getSumOfNElements[parts][2][CHUNK_NUMBER];
    for (var i = 0; i < parts; i++){
        for (var j = 0; j < 2; j++){
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                getSumOfNElements[i][j][axis_idx] = GetSumOfNElements(2 ** STRIDE);
                getSumOfNElements[i][j][axis_idx].dummy <== dummy;
                for (var stride_idx = 0; stride_idx < 2 ** STRIDE; stride_idx++){
                    getSumOfNElements[i][j][axis_idx].in[stride_idx] <== resultCoordinateComputation[i][stride_idx][j][axis_idx];
                }
            }
        }
    }
    
    component isZero[parts];
    for (var i = 0; i < parts; i++){
        isZero[i] = IsZero();
        isZero[i].in <== getSumOfNElements[i][0][0].out + getSumOfNElements[i][0][1].out + getSumOfNElements[i][0][2].out + getSumOfNElements[i][0][3].out + getSumOfNElements[i][1][0].out + getSumOfNElements[i][1][1].out + getSumOfNElements[i][1][2].out + getSumOfNElements[i][1][3].out + dummy * dummy;
    }
    
    signal precomptedDummy[parts][2][CHUNK_NUMBER];
    
    component getDummy = EllipticCurveGetDummy(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    
    for (var part_idx = 0; part_idx < parts; part_idx++){
        for (var i = 0; i < 2; i++){
            for (var j = 0; j < CHUNK_NUMBER; j++){
                precomptedDummy[part_idx][i][j] <== isZero[part_idx].out * getDummy.dummyPoint[i][j];
            }
        }
    }
    
    signal additionPoints[parts][2][CHUNK_NUMBER];
    for (var part_idx = 0; part_idx < parts; part_idx++){
        for (var i = 0; i < 2; i++){
            for (var j = 0; j < CHUNK_NUMBER; j++){
                additionPoints[part_idx][i][j] <== (1 - isZero[part_idx].out) * getSumOfNElements[part_idx][i][j].out + precomptedDummy[part_idx][i][j];
            }
        }
    }
    
    component adders[parts - 1];
    component isDummyLeft[parts - 1];
    component isDummyRight[parts - 1];
    
    signal resultingPoints[parts][2][CHUNK_NUMBER];
    
    component switcherLeft[parts][2][CHUNK_NUMBER];
    component switcherRight[parts][2][CHUNK_NUMBER];
    
    
    for (var i = 0; i < parts - 1; i++){
        adders[i] = EllipticCurveAddOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        adders[i].dummy <== dummy;
        isDummyLeft[i] = IsEqual();
        isDummyRight[i] = IsEqual();
        
        isDummyLeft[i].in[0] <== getDummy.dummyPoint[0][0];
        isDummyRight[i].in[0] <== getDummy.dummyPoint[0][0];
        
        if (i == 0){
            isDummyLeft[i].in[1] <== additionPoints[i][0][0];
            isDummyRight[i].in[1] <== additionPoints[i + 1][0][0];
            adders[i].in1 <== additionPoints[i];
            for (var j = 0; j < CHUNK_NUMBER - 1; j++){
                adders[i].in2[0][j] <== additionPoints[i + 1][0][j];
                adders[i].in2[1][j] <== additionPoints[i + 1][1][j];
            }
            adders[i].in2[0][CHUNK_NUMBER - 1] <== additionPoints[i + 1][0][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            adders[i].in2[1][CHUNK_NUMBER - 1] <== additionPoints[i + 1][1][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            
            // 0 0 -> adders
            // 0 1 -> left
            // 1 0 -> right
            // 1 1 -> right
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var j = 0; j < CHUNK_NUMBER; j++){
                    
                    switcherRight[i][axis_idx][j] = Switcher();
                    switcherRight[i][axis_idx][j].bool <== isDummyRight[i].out;
                    switcherRight[i][axis_idx][j].in[0] <== adders[i].out[axis_idx][j];
                    switcherRight[i][axis_idx][j].in[1] <== additionPoints[i][axis_idx][j];
                    
                    switcherLeft[i][axis_idx][j] = Switcher();
                    switcherLeft[i][axis_idx][j].bool <== isDummyLeft[i].out;
                    switcherLeft[i][axis_idx][j].in[0] <== additionPoints[i + 1][axis_idx][j];
                    switcherLeft[i][axis_idx][j].in[1] <== switcherRight[i][axis_idx][j].out[0];
                    
                    resultingPoints[i][axis_idx][j] <== switcherLeft[i][axis_idx][j].out[1];
                }
            }
            
        } else {
            isDummyLeft[i].in[1] <== resultingPoints[i - 1][0][0];
            isDummyRight[i].in[1] <== additionPoints[i + 1][0][0];
            adders[i].in1 <== resultingPoints[i - 1];
            for (var j = 0; j < CHUNK_NUMBER - 1; j++){
                adders[i].in2[0][j] <== additionPoints[i + 1][0][j];
                adders[i].in2[1][j] <== additionPoints[i + 1][1][j];
            }
            adders[i].in2[0][CHUNK_NUMBER - 1] <== additionPoints[i + 1][0][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            adders[i].in2[1][CHUNK_NUMBER - 1] <== additionPoints[i + 1][1][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            
            // 0 0 -> adders
            // 0 1 -> left
            // 1 0 -> right
            // 1 1 -> right
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var j = 0; j < CHUNK_NUMBER; j++){
                    
                    switcherRight[i][axis_idx][j] = Switcher();
                    switcherRight[i][axis_idx][j].bool <== isDummyRight[i].out;
                    switcherRight[i][axis_idx][j].in[0] <== adders[i].out[axis_idx][j];
                    switcherRight[i][axis_idx][j].in[1] <== resultingPoints[i - 1][axis_idx][j];
                    
                    switcherLeft[i][axis_idx][j] = Switcher();
                    switcherLeft[i][axis_idx][j].bool <== isDummyLeft[i].out;
                    switcherLeft[i][axis_idx][j].in[0] <== additionPoints[i + 1][axis_idx][j];
                    switcherLeft[i][axis_idx][j].in[1] <== switcherRight[i][axis_idx][j].out[0];
                    
                    resultingPoints[i][axis_idx][j] <== switcherLeft[i][axis_idx][j].out[1];
                }
            }
        }
    }
    out <== resultingPoints[parts - 2];
}

// Optimised scalar point multiplication, use it if u can`t add precompute table
// Algo:
// Precompute (see "PrecomputePipinger" template)
// Convert each WINDOW_SIZE bits into num IDX, double WINDOW_SIZE times, add to result IDX * G (from precomputes), repeat
// Double add and algo complexity:
// 255 doubles + 256 adds
// Our algo complexity:
// 256 - WINDOW_SIZE doubles, 256 / WINDOW_SIZE adds, 2 ** WINDOW_SIZE - 2 adds and doubles for precompute
// for 256 curve best WINDOW_SIZE = 4 with 330 operations with points
template EllipticCurvePipingerMult(CHUNK_SIZE, CHUNK_NUMBER, A, B, P, WINDOW_SIZE){
    
    signal input in[2][CHUNK_NUMBER];
    signal input scalar[CHUNK_NUMBER];
    signal input dummy;
    
    signal output out[2][CHUNK_NUMBER];
    
    component precompute = EllipticCurvePrecomputePipinger(CHUNK_SIZE, CHUNK_NUMBER, A, B, P, WINDOW_SIZE);
    precompute.dummy <== dummy;
    precompute.in <== in;
    
    var PRECOMPUTE_NUMBER = 2 ** WINDOW_SIZE;
    var DOUBLERS_NUMBER = CHUNK_SIZE * CHUNK_NUMBER - WINDOW_SIZE;
    var ADDERS_NUMBER = CHUNK_SIZE * CHUNK_NUMBER \ WINDOW_SIZE;
    
    
    component doublers[DOUBLERS_NUMBER];
    component adders  [ADDERS_NUMBER - 1];
    component bits2Num[ADDERS_NUMBER];
    component num2Bits[CHUNK_NUMBER];
    
    component getDummy = EllipticCurveGetDummy(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    signal scalarBits[CHUNK_NUMBER * CHUNK_SIZE];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        num2Bits[i] = Num2Bits(CHUNK_SIZE);
        num2Bits[i].in <== scalar[i];
        for (var j = 0; j < CHUNK_SIZE; j++){
            scalarBits[CHUNK_NUMBER * CHUNK_SIZE - CHUNK_SIZE * (i + 1) + j] <== num2Bits[i].out[CHUNK_SIZE - 1 - j];
        }
    }
    
    signal resultingPoints[ADDERS_NUMBER + 1][2][CHUNK_NUMBER];
    signal additionPoints[ADDERS_NUMBER][2][CHUNK_NUMBER];
    
    
    component isZeroResult[ADDERS_NUMBER];
    component isZeroAddition[ADDERS_NUMBER];
    
    component partsEqual[ADDERS_NUMBER][PRECOMPUTE_NUMBER];
    component getSum[ADDERS_NUMBER][2][CHUNK_NUMBER];
    
    
    component doubleSwitcher[DOUBLERS_NUMBER][2][CHUNK_NUMBER];
    
    component resultSwitcherAddition[DOUBLERS_NUMBER][2][CHUNK_NUMBER];
    component resultSwitcherDoubling[DOUBLERS_NUMBER][2][CHUNK_NUMBER];
    
    // Setting zero point ([0, ... , 0], [0, ... , 0])
    resultingPoints[0] <== precompute.out[0];
    
    for (var i = 0; i < CHUNK_NUMBER * CHUNK_SIZE; i += WINDOW_SIZE){
        bits2Num[i \ WINDOW_SIZE] = Bits2Num(WINDOW_SIZE);
        for (var j = 0; j < WINDOW_SIZE; j++){
            bits2Num[i \ WINDOW_SIZE].in[j] <== scalarBits[i + (WINDOW_SIZE - 1) - j];
        }
        
        isZeroResult[i \ WINDOW_SIZE] = IsZero();
        isZeroResult[i \ WINDOW_SIZE].in <== resultingPoints[i \ WINDOW_SIZE][0][0];
        
        if (i != 0){
            for (var j = 0; j < WINDOW_SIZE; j++){
                doublers[i + j - WINDOW_SIZE] = EllipticCurveDouble(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
                doublers[i + j - WINDOW_SIZE].dummy <== dummy;
                
                // if input == 0, double gen, result - zero
                // if input != 0, double res window times, result - doubling result
                if (j == 0){
                    for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                        for (var coor_idx = 0; coor_idx < CHUNK_NUMBER; coor_idx++){
                            
                            doubleSwitcher[i \ WINDOW_SIZE - 1][axis_idx][coor_idx] = Switcher();
                            doubleSwitcher[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].bool <== isZeroResult[i \ WINDOW_SIZE].out;
                            doubleSwitcher[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].in[0] <== getDummy.dummyPoint[axis_idx][coor_idx];
                            doubleSwitcher[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].in[1] <== resultingPoints[i \ WINDOW_SIZE][axis_idx][coor_idx];

                            doublers[i + j - WINDOW_SIZE].in[axis_idx][coor_idx] <== doubleSwitcher[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].out[1];
                        }
                    }
                }
                else {
                    doublers[i + j - WINDOW_SIZE].in <== doublers[i + j - 1 - WINDOW_SIZE].out;
                }
            }
        }
        
        // Setting components
        for (var axis_idx = 0; axis_idx < 2; axis_idx++){
            for (var coor_idx = 0; coor_idx < CHUNK_NUMBER; coor_idx++){
                getSum[i \ WINDOW_SIZE][axis_idx][coor_idx] = GetSumOfNElements(PRECOMPUTE_NUMBER);
                getSum[i \ WINDOW_SIZE][axis_idx][coor_idx].dummy <== dummy;
            }
        }
        
        // Each sum is sum of all precomputed coordinates * isEqual result (0 + 0 + 1 * coordinate[][] + .. + 0)
        
        for (var point_idx = 0; point_idx < PRECOMPUTE_NUMBER; point_idx++){
            partsEqual[i \ WINDOW_SIZE][point_idx] = IsEqual();
            partsEqual[i \ WINDOW_SIZE][point_idx].in[0] <== point_idx;
            partsEqual[i \ WINDOW_SIZE][point_idx].in[1] <== bits2Num[i \ WINDOW_SIZE].out;
            
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var coor_idx = 0; coor_idx < CHUNK_NUMBER; coor_idx++){
                    getSum[i \ WINDOW_SIZE][axis_idx][coor_idx].in[point_idx] <== partsEqual[i \ WINDOW_SIZE][point_idx].out * precompute.out[point_idx][axis_idx][coor_idx];
                }
            }
        }
        // Setting results in point
        for (var axis_idx = 0; axis_idx < 2; axis_idx++){
            for (var coor_idx = 0; coor_idx < CHUNK_NUMBER; coor_idx++){
                additionPoints[i \ WINDOW_SIZE][axis_idx][coor_idx] <== getSum[i \ WINDOW_SIZE][axis_idx][coor_idx].out;
            }
        }
        
        if (i == 0){
            
            resultingPoints[i \ WINDOW_SIZE + 1] <== additionPoints[i \ WINDOW_SIZE];
            
        } else {
            adders[i \ WINDOW_SIZE - 1] = EllipticCurveAdd(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
            adders[i \ WINDOW_SIZE - 1].in1 <== doublers[i - 1].out;
            adders[i \ WINDOW_SIZE - 1].in2 <== additionPoints[i \ WINDOW_SIZE];
            adders[i \ WINDOW_SIZE - 1].dummy <== dummy;
            
            isZeroAddition[i \ WINDOW_SIZE] = IsZero();
            isZeroAddition[i \ WINDOW_SIZE].in <== additionPoints[i \ WINDOW_SIZE][0][0];
            
            // isZeroAddition / isZeroResult
            // 0 0 -> adders Result
            // 0 1 -> additionPoints
            // 1 0 -> doubling result
            // 1 1 -> 0
            
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var coor_idx = 0; coor_idx < CHUNK_NUMBER; coor_idx++){
                    resultSwitcherAddition[i \ WINDOW_SIZE - 1][axis_idx][coor_idx] = Switcher();
                    resultSwitcherDoubling[i \ WINDOW_SIZE - 1][axis_idx][coor_idx] = Switcher();
                    
                    resultSwitcherAddition[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].bool <== isZeroAddition[i \ WINDOW_SIZE].out;
                    resultSwitcherAddition[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].in[0] <== adders[i \ WINDOW_SIZE - 1].out[axis_idx][coor_idx];
                    resultSwitcherAddition[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].in[1] <== doublers[i - 1].out[axis_idx][coor_idx];
                    
                    resultSwitcherDoubling[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].bool <== isZeroResult[i \ WINDOW_SIZE].out;
                    resultSwitcherDoubling[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].in[0] <== additionPoints[i \ WINDOW_SIZE][axis_idx][coor_idx];
                    resultSwitcherDoubling[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].in[1] <== resultSwitcherAddition[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].out[0];
                    
                    resultingPoints[i \ WINDOW_SIZE + 1][axis_idx][coor_idx] <== resultSwitcherDoubling[i \ WINDOW_SIZE - 1][axis_idx][coor_idx].out[1];
                }
            }
        }
    }
    out <== resultingPoints[ADDERS_NUMBER];
}

// Our elliptic scalar mult cost almost ~5 000 000 constarints
// There is a way to reduce it if can make some precomputations off-circuit
// One of examples is Generator multiplication, which costs almost ~550 000 (10 times less!)
// So, solution is next:
// If u know point at the moment of compilation, u can precompute this table as same, then insert it as input
// We should understand that it can be insecure, cause this table size (256 * 32 points of 512 bytes each -> 4kb) is too big to make it public input
// Our decision is to make result public and input public, so u can check if result was calculated in right way anywhere else (on smart contracts, for example)
// This can prevent fake table adding
// There is no problem of making result point output, but making input point public may cause other zk idea problems:
// For example, we want to verify ECDSA, and have message, signature and pubkey.
// If u do it with defauld scalar mult, it will take ~ 5 600 000 constraints, while if u use precomputed table - ~ 1 200 000
// But u need to make pubkey public in this case
// I u have no problem with it, use this one, and u will get 5 times less consraints verification
// But pubkey reveal leads to other problem: it is zk now, and u can know who signer is
// This can be crutial, so be careful with it
// To generate table for input, use script located in "../helpers/generate_mult_input.py"
// Change lines 127..132 to get input
// Note that Gx and Gy is your point, not generator (U can simply use generator multiplication without generating other table for generator)
template EllipicCurveScalarPrecomputeMultiplicationOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    assert(CHUNK_SIZE == 64 && CHUNK_NUMBER == 4);
    var STRIDE = 8;
    var parts = CHUNK_NUMBER * CHUNK_SIZE \ STRIDE;
    
    signal input scalar[CHUNK_NUMBER];
    signal input dummy;
    signal input in[2][CHUNK_NUMBER];
    signal input powers[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    
    dummy * dummy === 0;
    
    //----------------------------------------------------------------------------------------------------------------------------------------------------------------
    // We don`t use point anywhere, we should add any quadratic constraint for secure issues
    // I don`t sure if public inputs needs it, but it is 8 constraints from ~500 000, so better to let it be
    // U can remove it if u sure that this one isn`t nessesary for security
    signal secureIn[2][CHUNK_NUMBER];
    for (var i = 0; i < 2; i++){
        for (var j = 0; j < CHUNK_NUMBER; j++){
            secureIn[i][j] <== in[i][j] * in[i][j];
        }
    }
    //----------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    component num2bits[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        num2bits[i] = Num2Bits(CHUNK_SIZE);
        num2bits[i].in <== scalar[i];
    }
    component bits2num[parts];
    for (var i = 0; i < parts; i++){
        bits2num[i] = Bits2Num(STRIDE);
        for (var j = 0; j < STRIDE; j++){
            bits2num[i].in[j] <== num2bits[(i * STRIDE + j) \ CHUNK_SIZE].out[(i * STRIDE + j) % CHUNK_SIZE];
        }
    }
    
    component equal[parts][2 ** STRIDE];
    signal resultCoordinateComputation[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    for (var i = 0; i < parts; i++){
        for (var j = 0; j < 2 ** STRIDE; j++){
            equal[i][j] = IsEqual();
            equal[i][j].in[0] <== j;
            equal[i][j].in[1] <== bits2num[i].out;
            
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                resultCoordinateComputation[i][j][0][axis_idx] <== equal[i][j].out * powers[i][j][0][axis_idx];
            }
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                resultCoordinateComputation[i][j][1][axis_idx] <== equal[i][j].out * powers[i][j][1][axis_idx];
            }
        }
    }
    
    component getSumOfNElements[parts][2][CHUNK_NUMBER];
    for (var i = 0; i < parts; i++){
        for (var j = 0; j < 2; j++){
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                getSumOfNElements[i][j][axis_idx] = GetSumOfNElements(2 ** STRIDE);
                getSumOfNElements[i][j][axis_idx].dummy <== dummy;
                for (var stride_idx = 0; stride_idx < 2 ** STRIDE; stride_idx++){
                    getSumOfNElements[i][j][axis_idx].in[stride_idx] <== resultCoordinateComputation[i][stride_idx][j][axis_idx];
                }
            }
        }
    }
    
    component isZero[parts];
    for (var i = 0; i < parts; i++){
        isZero[i] = IsZero();
        isZero[i].in <== getSumOfNElements[i][0][0].out + getSumOfNElements[i][0][1].out + getSumOfNElements[i][0][2].out + getSumOfNElements[i][0][3].out + getSumOfNElements[i][1][0].out + getSumOfNElements[i][1][1].out + getSumOfNElements[i][1][2].out + getSumOfNElements[i][1][3].out + dummy * dummy;
    }
    
    signal precomptedDummy[parts][2][CHUNK_NUMBER];
    
    component getDummy = EllipticCurveGetDummy(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    
    for (var part_idx = 0; part_idx < parts; part_idx++){
        for (var i = 0; i < 2; i++){
            for (var j = 0; j < CHUNK_NUMBER; j++){
                precomptedDummy[part_idx][i][j] <== isZero[part_idx].out * getDummy.dummyPoint[i][j];
            }
        }
    }
    
    signal additionPoints[parts][2][CHUNK_NUMBER];
    for (var part_idx = 0; part_idx < parts; part_idx++){
        for (var i = 0; i < 2; i++){
            for (var j = 0; j < CHUNK_NUMBER; j++){
                additionPoints[part_idx][i][j] <== (1 - isZero[part_idx].out) * getSumOfNElements[part_idx][i][j].out + precomptedDummy[part_idx][i][j];
            }
        }
    }
    
    component adders[parts - 1];
    component isDummyLeft[parts - 1];
    component isDummyRight[parts - 1];
    
    signal resultingPoints[parts][2][CHUNK_NUMBER];
    
    component switcherLeft[parts][2][CHUNK_NUMBER];
    component switcherRight[parts][2][CHUNK_NUMBER];
    
    
    for (var i = 0; i < parts - 1; i++){
        adders[i] = EllipticCurveAddOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        adders[i].dummy <== dummy;
        isDummyLeft[i] = IsEqual();
        isDummyRight[i] = IsEqual();
        
        isDummyLeft[i].in[0] <== getDummy.dummyPoint[0][0];
        isDummyRight[i].in[0] <== getDummy.dummyPoint[0][0];
        
        if (i == 0){
            isDummyLeft[i].in[1] <== additionPoints[i][0][0];
            isDummyRight[i].in[1] <== additionPoints[i + 1][0][0];
            adders[i].in1 <== additionPoints[i];
            for (var j = 0; j < CHUNK_NUMBER - 1; j++){
                adders[i].in2[0][j] <== additionPoints[i + 1][0][j];
                adders[i].in2[1][j] <== additionPoints[i + 1][1][j];
            }
            adders[i].in2[0][CHUNK_NUMBER - 1] <== additionPoints[i + 1][0][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            adders[i].in2[1][CHUNK_NUMBER - 1] <== additionPoints[i + 1][1][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            
            // 0 0 -> adders
            // 0 1 -> left
            // 1 0 -> right
            // 1 1 -> right
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var j = 0; j < CHUNK_NUMBER; j++){
                    
                    
                    switcherRight[i][axis_idx][j] = Switcher();
                    switcherRight[i][axis_idx][j].bool <== isDummyRight[i].out;
                    switcherRight[i][axis_idx][j].in[0] <== adders[i].out[axis_idx][j];
                    switcherRight[i][axis_idx][j].in[1] <== additionPoints[i][axis_idx][j];
                    
                    switcherLeft[i][axis_idx][j] = Switcher();
                    switcherLeft[i][axis_idx][j].bool <== isDummyLeft[i].out;
                    switcherLeft[i][axis_idx][j].in[0] <== additionPoints[i + 1][axis_idx][j];
                    switcherLeft[i][axis_idx][j].in[1] <== switcherRight[i][axis_idx][j].out[0];
                    
                    resultingPoints[i][axis_idx][j] <== switcherLeft[i][axis_idx][j].out[1];
                }
            }
            
        } else {
            isDummyLeft[i].in[1] <== resultingPoints[i - 1][0][0];
            isDummyRight[i].in[1] <== additionPoints[i + 1][0][0];
            adders[i].in1 <== resultingPoints[i - 1];
            for (var j = 0; j < CHUNK_NUMBER - 1; j++){
                adders[i].in2[0][j] <== additionPoints[i + 1][0][j];
                adders[i].in2[1][j] <== additionPoints[i + 1][1][j];
            }
            adders[i].in2[0][CHUNK_NUMBER - 1] <== additionPoints[i + 1][0][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            adders[i].in2[1][CHUNK_NUMBER - 1] <== additionPoints[i + 1][1][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            
            // 0 0 -> adders
            // 0 1 -> left
            // 1 0 -> right
            // 1 1 -> right
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var j = 0; j < CHUNK_NUMBER; j++){
                    
                    switcherRight[i][axis_idx][j] = Switcher();
                    switcherRight[i][axis_idx][j].bool <== isDummyRight[i].out;
                    switcherRight[i][axis_idx][j].in[0] <== adders[i].out[axis_idx][j];
                    switcherRight[i][axis_idx][j].in[1] <== resultingPoints[i - 1][axis_idx][j];
                    
                    switcherLeft[i][axis_idx][j] = Switcher();
                    switcherLeft[i][axis_idx][j].bool <== isDummyLeft[i].out;
                    switcherLeft[i][axis_idx][j].in[0] <== additionPoints[i + 1][axis_idx][j];
                    switcherLeft[i][axis_idx][j].in[1] <== switcherRight[i][axis_idx][j].out[0];
                    
                    resultingPoints[i][axis_idx][j] <== switcherLeft[i][axis_idx][j].out[1];
                }
            }
        }
    }
    out <== resultingPoints[parts - 2];
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Non Optimised templates (for not CHUNK_SIZE == 64 and CHUNK_NUMBER == 4)
// Will be changed to autodetect optimised version and use it if need, but use this for now.

// Check if given point lies on curve
// y ** 2 % p === (x ** 3 + a * x + b) % p
// fail if point isn`t on curve, otherwise pass
template PointOnCurveNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    assert(CHUNK_SIZE == 64);
    
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    component mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult.in[0] <== in[0];
    mult.in[1] <== in[0];
    mult.dummy <== dummy;
    
    component mult2 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    mult2.in1 <== mult.out;
    mult2.in2 <== in[0];
    mult2.dummy <== dummy;
    
    component mult3 = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult3.in[0] <== in[0];
    mult3.in[1] <== A;
    mult3.dummy <== dummy;
    
    component mult4 = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult4.in[0] <== in[1];
    mult4.in[1] <== in[1];
    mult4.dummy <== dummy;
    
    component add = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER * 2 - 1);
    add.in1 <== mult2.out;
    add.in2 <== mult3.out;
    add.dummy <== dummy;
    
    component add2 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER);
    add2.in1 <== add.out;
    add2.in2 <== B;
    add2.dummy <== dummy;
    
    component mod = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod.base <== mult4.out;
    mod.modulus <== P;
    mod.dummy <== dummy;
    
    component mod2 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 3);
    mod2.base <== add2.out;
    mod2.modulus <== P;
    mod2.dummy <== dummy;
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        mod.mod[i] === mod2.mod[i];
    }
    
}

// λ = (3 * x ** 2 + a) / (2 * y)
// x3 = λ * λ - 2 * x
// y3 = λ * (x - x3) - y
// calculate doubled point
template EllipticCurveDoubleNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in[2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    // x * x
    component mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult.in[0] <== in[0];
    mult.in[1] <== in[0];
    mult.dummy <== dummy;
    
    // 3 * x * x
    component scalarMult = ScalarMultOverflow(CHUNK_NUMBER * 2 - 1);
    scalarMult.scalar <== 3;
    scalarMult.in <== mult.out;
    
    // 3 * x * x + a
    component add = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add.in1 <== scalarMult.out;
    add.in2 <== A;
    add.dummy <== dummy;
    
    // 2 * y
    component scalarMult2 = ScalarMultOverflow(CHUNK_NUMBER);
    scalarMult2.in <== in[1];
    scalarMult2.scalar <== 2;
    
    // (2 * y) ** -1
    component modInv = BigModInvOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    modInv.in <== scalarMult2.out;
    modInv.modulus <== P;
    modInv.dummy <== dummy;
    
    // (3 * x * x + a) * 1 / (2 * y)
    component mult2 = BigMultNonEqualOverflow(CHUNK_SIZE, 2 * CHUNK_NUMBER - 1, CHUNK_NUMBER);
    mult2.in1 <== add.out;
    mult2.in2 <== modInv.out;
    mult2.dummy <== dummy;
    
    // ((3 * x * x + a) * 1 / (2 * y)) % p ==> λ
    component mod = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 3);
    mod.base <== mult2.out;
    mod.modulus <== P;
    mod.dummy <== dummy;
    
    // λ * λ
    component mult3 = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult3.in[0] <== mod.mod;
    mult3.in[1] <== mod.mod;
    mult3.dummy <== dummy;
    
    // P - x
    component sub = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub.in1 <== P;
    sub.in2 <== in[0];
    sub.modulus <== P;
    sub.dummy <== dummy;
    
    // 2 * P - 2 * x
    component scalarMult3 = ScalarMultOverflow(CHUNK_NUMBER);
    scalarMult3.in <== sub.out;
    scalarMult3.scalar <== 2;
    
    // λ * λ + 2 * P - 2 * x
    component add2 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add2.in1 <== mult3.out;
    add2.in2 <== scalarMult3.out;
    add2.dummy <== dummy;
    
    // (λ * λ + 2 * P - 2 * x) % p ==> x3
    component mod2 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod2.base <== add2.out;
    mod2.modulus <== P;
    mod2.dummy <== dummy;
    
    out[0] <== mod2.mod;
    
    // x1 - x3
    component sub2 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub2.in1 <== in[0];
    sub2.in2 <== out[0];
    sub2.modulus <== P;
    sub2.dummy <== dummy;
    
    // λ * (x1 - x3)
    component mult4 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    mult4.in1 <== mod.mod;
    mult4.in2 <== sub2.out;
    mult4.dummy <== dummy;
    
    // P - y
    component sub3 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub3.in1 <== P;
    sub3.in2 <== in[1];
    sub3.modulus <== P;
    sub3.dummy <== dummy;
    
    // λ * (x1 - x3) + P - y
    component add3 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add3.in1 <== mult4.out;
    add3.in2 <== sub3.out;
    add3.dummy <== dummy;
    
    // (λ * (x1 - x3) + P - y) % P ==> y3
    component mod3 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod3.base <== add3.out;
    mod3.modulus <== P;
    mod3.dummy <== dummy;
    
    out[1] <== mod3.mod;
}

// λ = (y2 - y1) / (x2 - x1)
// x3 = λ * λ - x1 - x2
// y3 = λ * (x1 - x3) - y1
// calculate sum of 2 points
template EllipticCurveAddNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    // x2 - x1
    component sub = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub.in1 <== in2[0];
    sub.in2 <== in1[0];
    sub.modulus <== P;
    sub.dummy <== dummy;
    
    // y2 - y1
    component sub2 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub2.in1 <== in2[1];
    sub2.in2 <== in1[1];
    sub2.modulus <== P;
    sub2.dummy <== dummy;
    
    // (x2 - x1) ** -1
    component modInv = BigModInvOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    modInv.in <== sub.out;
    modInv.modulus <== P;
    modInv.dummy <== dummy;
    
    // (y2 - y1) * 1 / (x2 - x1)
    component mult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult.in[0] <== sub2.out;
    mult.in[1] <== modInv.out;
    mult.dummy <== dummy;
    
    // (y2 - y1) * 1 / (x2 - x1) % P ==> λ
    component mod = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod.base <== mult.out;
    mod.modulus <== P;
    mod.dummy <== dummy;
    
    // λ * λ
    component mult2 = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    mult2.in[0] <== mod.mod;
    mult2.in[1] <== mod.mod;
    mult2.dummy <== dummy;
    
    // P - in1
    component sub3 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub3.in1 <== P;
    sub3.in2 <== in1[0];
    sub3.modulus <== P;
    sub3.dummy <== dummy;
    
    // P - in2
    component sub4 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub4.in1 <== P;
    sub4.in2 <== in2[0];
    sub4.modulus <== P;
    sub4.dummy <== dummy;
    
    // 2 * P - in1 - in2
    component add = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    add.in[0] <== sub3.out;
    add.in[1] <== sub4.out;
    add.dummy <== dummy;
    
    // λ * λ + 2 * P - in1 - in2
    component add2 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    add2.in1 <== mult2.out;
    add2.in2 <== add.out;
    add2.dummy <== dummy;
    
    // (λ * λ + 2 * P - in1 - in2) % P ==> x3
    component mod2 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, 2);
    mod2.base <== add2.out;
    mod2.modulus <== P;
    mod2.dummy <== dummy;
    
    out[0] <== mod2.mod;
    
    // x1 - x3
    component sub5 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub5.in1 <== in1[0];
    sub5.in2 <== out[0];
    sub5.modulus <== P;
    sub5.dummy <== dummy;
    
    // λ * (x1 - x3)
    component mult3 = BigMultNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    mult3.in1 <== mult.out;
    mult3.in2 <== sub5.out;
    mult3.dummy <== dummy;
    
    // P - y1
    component sub6 = BigSubModOverflow(CHUNK_SIZE, CHUNK_NUMBER);
    sub6.in1 <== P;
    sub6.in2 <== in1[1];
    sub6.modulus <== P;
    sub6.dummy <== dummy;
    
    // λ * (x1 - x3) + P - y1
    component add3 = BigAddNonEqualOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER);
    add3.in1 <== mult3.out;
    add3.in2 <== sub6.out;
    add3.dummy <== dummy;
    
    // (λ * (x1 - x3) + P - y1) % P ==> y3
    component mod3 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 3);
    mod3.base <== add3.out;
    mod3.modulus <== P;
    mod3.dummy <== dummy;
    
    out[1] <== mod3.mod;
}

// calculate G * scalar
// To make it work for other curve u should generate generator pow table
// Other curves will be added by ourself soon
// Will fail if scalar == 0, don`t do it
// Use chunking that CHUNK_NUMBER * CHUNK_SIZE == FIELD
// And don`t use for 43 * 6 != 256, for example
// This chunking will be added late
// Complexity is field \ 8 - 1 additions
template EllipicCurveScalarGeneratorMultiplicationNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    signal input scalar[CHUNK_NUMBER];
    signal input dummy;
    
    signal output out[2][CHUNK_NUMBER];
    
    var STRIDE = 8;
    
    var parts = CHUNK_NUMBER * CHUNK_SIZE \ STRIDE;
    
    dummy * dummy === 0;
    var powers[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    if (CHUNK_NUMBER == 6){
        if (P[0] == 9747760000893709395 && P[1] == 12453481191562877553 && P[2] == 1347097566612230435 && P[3] == 1526563086152259252 && P[4] == 1107163671716839903 && P[5] == 10140169582434348328){
            powers = get_g_pow_stride8_table_brainpoolP384r1(CHUNK_SIZE, CHUNK_NUMBER);
        }
        if (P[0] == 4294967295 && P[1] == 18446744069414584320 && P[2] == 18446744073709551614 && P[3] == 18446744073709551615 && P[4] == 18446744073709551615 && P[5] == 18446744073709551615){
            powers = get_g_pow_stride8_table_p384(CHUNK_SIZE, CHUNK_NUMBER);
        }
    }
    if (CHUNK_NUMBER == 7 && CHUNK_SIZE == 32){
        if (P[0] == 2127085823 && P[1] == 2547681781 && P[2] == 2963212119 && P[3] == 1976686471 && P[4] == 706228261 && P[5] == 641951366 && P[6] == 3619763370){
            powers = get_g_pow_stride8_table_brainpoolP224r1(CHUNK_SIZE, CHUNK_NUMBER);
        }
    }
    
    component num2bits[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        num2bits[i] = Num2Bits(CHUNK_SIZE);
        num2bits[i].in <== scalar[i];
    }
    component bits2num[parts];
    for (var i = 0; i < parts; i++){
        bits2num[i] = Bits2Num(STRIDE);
        for (var j = 0; j < STRIDE; j++){
            bits2num[i].in[j] <== num2bits[(i * STRIDE + j) \ CHUNK_SIZE].out[(i * STRIDE + j) % CHUNK_SIZE];
        }
    }
    
    component equal[parts][2 ** STRIDE];
    signal resultCoordinateComputation[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    for (var i = 0; i < parts; i++){
        for (var j = 0; j < 2 ** STRIDE; j++){
            equal[i][j] = IsEqual();
            equal[i][j].in[0] <== j;
            equal[i][j].in[1] <== bits2num[i].out;
            
            
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                resultCoordinateComputation[i][j][0][axis_idx] <== equal[i][j].out * powers[i][j][0][axis_idx];
            }
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                resultCoordinateComputation[i][j][1][axis_idx] <== equal[i][j].out * powers[i][j][1][axis_idx];
            }
            
            
        }
    }
    
    component getSumOfNElements[parts][2][CHUNK_NUMBER];
    for (var i = 0; i < parts; i++){
        for (var j = 0; j < 2; j++){
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                getSumOfNElements[i][j][axis_idx] = GetSumOfNElements(2 ** STRIDE);
                getSumOfNElements[i][j][axis_idx].dummy <== dummy;
                for (var stride_idx = 0; stride_idx < 2 ** STRIDE; stride_idx++){
                    getSumOfNElements[i][j][axis_idx].in[stride_idx] <== resultCoordinateComputation[i][stride_idx][j][axis_idx];
                }
            }
        }
    }
    
    component isZero[parts];
    for (var i = 0; i < parts; i++){
        isZero[i] = IsZero();
        isZero[i].in <== getSumOfNElements[i][0][0].out + getSumOfNElements[i][0][1].out + getSumOfNElements[i][0][2].out + getSumOfNElements[i][0][3].out + getSumOfNElements[i][1][0].out + getSumOfNElements[i][1][1].out + getSumOfNElements[i][1][2].out + getSumOfNElements[i][1][3].out + dummy * dummy;
    }
    
    signal precomptedDummy[parts][2][CHUNK_NUMBER];
    
    component getDummy = EllipticCurveGetDummy(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    
    for (var part_idx = 0; part_idx < parts; part_idx++){
        for (var i = 0; i < 2; i++){
            for (var j = 0; j < CHUNK_NUMBER; j++){
                precomptedDummy[part_idx][i][j] <== isZero[part_idx].out * getDummy.dummyPoint[i][j];
            }
        }
    }
    
    signal additionPoints[parts][2][CHUNK_NUMBER];
    for (var part_idx = 0; part_idx < parts; part_idx++){
        for (var i = 0; i < 2; i++){
            for (var j = 0; j < CHUNK_NUMBER; j++){
                additionPoints[part_idx][i][j] <== (1 - isZero[part_idx].out) * getSumOfNElements[part_idx][i][j].out + precomptedDummy[part_idx][i][j];
            }
        }
    }
    
    component adders[parts - 1];
    component isDummyLeft[parts - 1];
    component isDummyRight[parts - 1];
    
    
    signal resultingPointsLeft[parts][2][CHUNK_NUMBER];
    signal resultingPointsLeft2[parts][2][CHUNK_NUMBER];
    signal resultingPointsRight[parts][2][CHUNK_NUMBER];
    signal resultingPointsRight2[parts][2][CHUNK_NUMBER];
    signal resultingPoints[parts][2][CHUNK_NUMBER];
    
    component switcherLeft[parts][2][CHUNK_NUMBER];
    component switcherRight[parts][2][CHUNK_NUMBER];
    
    
    for (var i = 0; i < parts - 1; i++){
        adders[i] = EllipticCurveAdd(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        adders[i].dummy <== dummy;
        isDummyLeft[i] = IsEqual();
        isDummyRight[i] = IsEqual();
        
        isDummyLeft[i].in[0] <== getDummy.dummyPoint[0][0];
        isDummyRight[i].in[0] <== getDummy.dummyPoint[0][0];
        
        if (i == 0){
            isDummyLeft[i].in[1] <== additionPoints[i][0][0];
            isDummyRight[i].in[1] <== additionPoints[i + 1][0][0];
            adders[i].in1 <== additionPoints[i];
            for (var j = 0; j < CHUNK_NUMBER - 1; j++){
                adders[i].in2[0][j] <== additionPoints[i + 1][0][j];
                adders[i].in2[1][j] <== additionPoints[i + 1][1][j];
            }
            adders[i].in2[0][CHUNK_NUMBER - 1] <== additionPoints[i + 1][0][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            adders[i].in2[1][CHUNK_NUMBER - 1] <== additionPoints[i + 1][1][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            
            // 0 0 -> adders
            // 0 1 -> left
            // 1 0 -> right
            // 1 1 -> right
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var j = 0; j < CHUNK_NUMBER; j++){
                    
                    switcherRight[i][axis_idx][j] = Switcher();
                    switcherRight[i][axis_idx][j].bool <== isDummyRight[i].out;
                    switcherRight[i][axis_idx][j].in[0] <== adders[i].out[axis_idx][j];
                    switcherRight[i][axis_idx][j].in[1] <== additionPoints[i][axis_idx][j];
                    
                    switcherLeft[i][axis_idx][j] = Switcher();
                    switcherLeft[i][axis_idx][j].bool <== isDummyLeft[i].out;
                    switcherLeft[i][axis_idx][j].in[0] <== additionPoints[i + 1][axis_idx][j];
                    switcherLeft[i][axis_idx][j].in[1] <== switcherRight[i][axis_idx][j].out[0];
                    
                    resultingPoints[i][axis_idx][j] <== switcherLeft[i][axis_idx][j].out[1];
                }
            }
            
        } else {
            isDummyLeft[i].in[1] <== resultingPoints[i - 1][0][0];
            isDummyRight[i].in[1] <== additionPoints[i + 1][0][0];
            adders[i].in1 <== resultingPoints[i - 1];
            for (var j = 0; j < CHUNK_NUMBER - 1; j++){
                adders[i].in2[0][j] <== additionPoints[i + 1][0][j];
                adders[i].in2[1][j] <== additionPoints[i + 1][1][j];
            }
            adders[i].in2[0][CHUNK_NUMBER - 1] <== additionPoints[i + 1][0][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            adders[i].in2[1][CHUNK_NUMBER - 1] <== additionPoints[i + 1][1][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            
            // 0 0 -> adders
            // 0 1 -> left
            // 1 0 -> right
            // 1 1 -> right
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var j = 0; j < CHUNK_NUMBER; j++){
                    
                    switcherRight[i][axis_idx][j] = Switcher();
                    switcherRight[i][axis_idx][j].bool <== isDummyRight[i].out;
                    switcherRight[i][axis_idx][j].in[0] <== adders[i].out[axis_idx][j];
                    switcherRight[i][axis_idx][j].in[1] <== resultingPoints[i - 1][axis_idx][j];
                    
                    switcherLeft[i][axis_idx][j] = Switcher();
                    switcherLeft[i][axis_idx][j].bool <== isDummyLeft[i].out;
                    switcherLeft[i][axis_idx][j].in[0] <== additionPoints[i + 1][axis_idx][j];
                    switcherLeft[i][axis_idx][j].in[1] <== switcherRight[i][axis_idx][j].out[0];
                    
                    resultingPoints[i][axis_idx][j] <== switcherLeft[i][axis_idx][j].out[1];
                }
            }
        }
    }
    out <== resultingPoints[parts - 2];
}

// Our elliptic scalar mult cost almost ~5 000 000 constarints
// There is a way to reduce it if can make some precomputations off-circuit
// One of examples is Generator multiplication, which costs almost ~550 000 (10 times less!)
// So, solution is next:
// If u know point at the moment of compilation, u can precompute this table as same, then insert it as input
// We should understand that it can be insecure, cause this table size (256 * 32 points of 512 bytes each -> 4kb) is too big to make it public input
// Our decision is to make result public and input public, so u can check if result was calculated in right way anywhere else (on smart contracts, for example)
// This can prevent fake table adding
// There is no problem of making result point output, but making input point public may cause other zk idea problems:
// For example, we want to verify ECDSA, and have message, signature and pubkey.
// If u do it with defauld scalar mult, it will take ~ 5 600 000 constraints, while if u use precomputed table - ~ 1 200 000
// But u need to make pubkey public in this case
// I u have no problem with it, use this one, and u will get 5 times less consraints verification
// But pubkey reveal leads to other problem: it is zk now, and u can know who signer is
// This can be crutial, so be careful with it
// To generate table for input, use script located in "../helpers/generate_mult_input.py"
// Change lines 127..132 to get input
// Note that Gx and Gy is your point, not generator (U can simply use generator multiplication without generating other table for generator)
template EllipicCurveScalarPrecomputeMultiplicationNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    var STRIDE = 8;
    var parts = CHUNK_NUMBER * CHUNK_SIZE \ STRIDE;
    
    signal input scalar[CHUNK_NUMBER];
    signal input dummy;
    signal input in[2][CHUNK_NUMBER];
    signal input powers[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    
    dummy * dummy === 0;
    
    //----------------------------------------------------------------------------------------------------------------------------------------------------------------
    // We don`t use point anywhere, we should add any quadratic constraint for secure issues
    // I don`t sure if public inputs needs it, but it is 2 * CHUNK_NUMBER constraints from thousands or even millions for 384+ field curves, so better to let it be
    // U can remove it if u sure that this one isn`t nessesary for security
    signal secureIn[2][CHUNK_NUMBER];
    for (var i = 0; i < 2; i++){
        for (var j = 0; j < CHUNK_NUMBER; j++){
            secureIn[i][j] <== in[i][j] * in[i][j];
        }
    }
    //----------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    component num2bits[CHUNK_NUMBER];
    for (var i = 0; i < CHUNK_NUMBER; i++){
        num2bits[i] = Num2Bits(CHUNK_SIZE);
        num2bits[i].in <== scalar[i];
    }
    component bits2num[parts];
    for (var i = 0; i < parts; i++){
        bits2num[i] = Bits2Num(STRIDE);
        for (var j = 0; j < STRIDE; j++){
            bits2num[i].in[j] <== num2bits[(i * STRIDE + j) \ CHUNK_SIZE].out[(i * STRIDE + j) % CHUNK_SIZE];
        }
    }
    
    component equal[parts][2 ** STRIDE];
    signal resultCoordinateComputation[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    for (var i = 0; i < parts; i++){
        for (var j = 0; j < 2 ** STRIDE; j++){
            equal[i][j] = IsEqual();
            equal[i][j].in[0] <== j;
            equal[i][j].in[1] <== bits2num[i].out;
            
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                resultCoordinateComputation[i][j][0][axis_idx] <== equal[i][j].out * powers[i][j][0][axis_idx];
            }
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                resultCoordinateComputation[i][j][1][axis_idx] <== equal[i][j].out * powers[i][j][1][axis_idx];
            }
        }
    }
    
    component getSumOfNElements[parts][2][CHUNK_NUMBER];
    for (var i = 0; i < parts; i++){
        for (var j = 0; j < 2; j++){
            for (var axis_idx = 0; axis_idx < CHUNK_NUMBER; axis_idx++){
                getSumOfNElements[i][j][axis_idx] = GetSumOfNElements(2 ** STRIDE);
                getSumOfNElements[i][j][axis_idx].dummy <== dummy;
                for (var stride_idx = 0; stride_idx < 2 ** STRIDE; stride_idx++){
                    getSumOfNElements[i][j][axis_idx].in[stride_idx] <== resultCoordinateComputation[i][stride_idx][j][axis_idx];
                }
            }
        }
    }
    
    component isZero[parts];
    for (var i = 0; i < parts; i++){
        isZero[i] = IsZero();
        isZero[i].in <== getSumOfNElements[i][0][0].out + getSumOfNElements[i][0][1].out + getSumOfNElements[i][0][2].out + getSumOfNElements[i][0][3].out + getSumOfNElements[i][1][0].out + getSumOfNElements[i][1][1].out + getSumOfNElements[i][1][2].out + getSumOfNElements[i][1][3].out + dummy * dummy;
    }
    
    signal precomptedDummy[parts][2][CHUNK_NUMBER];
    
    component getDummy = EllipticCurveGetDummy(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    
    for (var part_idx = 0; part_idx < parts; part_idx++){
        for (var i = 0; i < 2; i++){
            for (var j = 0; j < CHUNK_NUMBER; j++){
                precomptedDummy[part_idx][i][j] <== isZero[part_idx].out * getDummy.dummyPoint[i][j];
            }
        }
    }
    
    signal additionPoints[parts][2][CHUNK_NUMBER];
    for (var part_idx = 0; part_idx < parts; part_idx++){
        for (var i = 0; i < 2; i++){
            for (var j = 0; j < CHUNK_NUMBER; j++){
                additionPoints[part_idx][i][j] <== (1 - isZero[part_idx].out) * getSumOfNElements[part_idx][i][j].out + precomptedDummy[part_idx][i][j];
            }
        }
    }
    
    component adders[parts - 1];
    component isDummyLeft[parts - 1];
    component isDummyRight[parts - 1];
    
    
    signal resultingPointsLeft[parts][2][CHUNK_NUMBER];
    signal resultingPointsLeft2[parts][2][CHUNK_NUMBER];
    signal resultingPointsRight[parts][2][CHUNK_NUMBER];
    signal resultingPointsRight2[parts][2][CHUNK_NUMBER];
    signal resultingPoints[parts][2][CHUNK_NUMBER];
    
    component switcherLeft[parts][2][CHUNK_NUMBER];
    component switcherRight[parts][2][CHUNK_NUMBER];
    
    
    for (var i = 0; i < parts - 1; i++){
        adders[i] = EllipticCurveAdd(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        adders[i].dummy <== dummy;
        isDummyLeft[i] = IsEqual();
        isDummyRight[i] = IsEqual();
        
        isDummyLeft[i].in[0] <== getDummy.dummyPoint[0][0];
        isDummyRight[i].in[0] <== getDummy.dummyPoint[0][0];
        
        if (i == 0){
            isDummyLeft[i].in[1] <== additionPoints[i][0][0];
            isDummyRight[i].in[1] <== additionPoints[i + 1][0][0];
            adders[i].in1 <== additionPoints[i];
            for (var j = 0; j < CHUNK_NUMBER - 1; j++){
                adders[i].in2[0][j] <== additionPoints[i + 1][0][j];
                adders[i].in2[1][j] <== additionPoints[i + 1][1][j];
            }
            adders[i].in2[0][CHUNK_NUMBER - 1] <== additionPoints[i + 1][0][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            adders[i].in2[1][CHUNK_NUMBER - 1] <== additionPoints[i + 1][1][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            
            // 0 0 -> adders
            // 0 1 -> left
            // 1 0 -> right
            // 1 1 -> right
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var j = 0; j < CHUNK_NUMBER; j++){
                    
                    switcherRight[i][axis_idx][j] = Switcher();
                    switcherRight[i][axis_idx][j].bool <== isDummyRight[i].out;
                    switcherRight[i][axis_idx][j].in[0] <== adders[i].out[axis_idx][j];
                    switcherRight[i][axis_idx][j].in[1] <== additionPoints[i][axis_idx][j];
                    
                    switcherLeft[i][axis_idx][j] = Switcher();
                    switcherLeft[i][axis_idx][j].bool <== isDummyLeft[i].out;
                    switcherLeft[i][axis_idx][j].in[0] <== additionPoints[i + 1][axis_idx][j];
                    switcherLeft[i][axis_idx][j].in[1] <== switcherRight[i][axis_idx][j].out[0];
                    
                    resultingPoints[i][axis_idx][j] <== switcherLeft[i][axis_idx][j].out[1];
                }
            }
            
        } else {
            isDummyLeft[i].in[1] <== resultingPoints[i - 1][0][0];
            isDummyRight[i].in[1] <== additionPoints[i + 1][0][0];
            adders[i].in1 <== resultingPoints[i - 1];
            for (var j = 0; j < CHUNK_NUMBER - 1; j++){
                adders[i].in2[0][j] <== additionPoints[i + 1][0][j];
                adders[i].in2[1][j] <== additionPoints[i + 1][1][j];
            }
            adders[i].in2[0][CHUNK_NUMBER - 1] <== additionPoints[i + 1][0][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            adders[i].in2[1][CHUNK_NUMBER - 1] <== additionPoints[i + 1][1][CHUNK_NUMBER - 1] + isDummyRight[i].out * isDummyRight[i].out;
            
            // 0 0 -> adders
            // 0 1 -> left
            // 1 0 -> right
            // 1 1 -> right
            for (var axis_idx = 0; axis_idx < 2; axis_idx++){
                for (var j = 0; j < CHUNK_NUMBER; j++){
                    switcherRight[i][axis_idx][j] = Switcher();
                    switcherRight[i][axis_idx][j].bool <== isDummyRight[i].out;
                    switcherRight[i][axis_idx][j].in[0] <== adders[i].out[axis_idx][j];
                    switcherRight[i][axis_idx][j].in[1] <== resultingPoints[i - 1][axis_idx][j];
                    
                    switcherLeft[i][axis_idx][j] = Switcher();
                    switcherLeft[i][axis_idx][j].bool <== isDummyLeft[i].out;
                    switcherLeft[i][axis_idx][j].in[0] <== additionPoints[i + 1][axis_idx][j];
                    switcherLeft[i][axis_idx][j].in[1] <== switcherRight[i][axis_idx][j].out[0];
                    
                    resultingPoints[i][axis_idx][j] <== switcherLeft[i][axis_idx][j].out[1];
                }
            }
        }
    }
    out <== resultingPoints[parts - 2];
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Here are autodetect templates, use them

template PointOnCurve(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    if (CHUNK_NUMBER == 4 && CHUNK_SIZE == 64){
        component pointOnCurveOptimised = PointOnCurveOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        pointOnCurveOptimised.in <== in;
        pointOnCurveOptimised.dummy <== dummy;
    } else {
        component pointOnCurveNonOptimised = PointOnCurveNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        pointOnCurveNonOptimised.in <== in;
        pointOnCurveNonOptimised.dummy <== dummy;
    }
    
}

template EllipticCurveDouble(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    signal output out[2][CHUNK_NUMBER];
    
    if (CHUNK_NUMBER == 4 && CHUNK_SIZE == 64 || CHUNK_SIZE == 66 && CHUNK_NUMBER == 8){
        component ecDoubleOptimised = EllipticCurveDoubleOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        ecDoubleOptimised.in <== in;
        ecDoubleOptimised.dummy <== dummy;
        out <== ecDoubleOptimised.out;
    } else {
        component ecDoubleNonOptimised = EllipticCurveDoubleNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        ecDoubleNonOptimised.in <== in;
        ecDoubleNonOptimised.dummy <== dummy;
        out <== ecDoubleNonOptimised.out;
    }
}

template EllipticCurveAdd(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    signal output out[2][CHUNK_NUMBER];
    
    if (CHUNK_NUMBER == 4 && CHUNK_SIZE == 64 || CHUNK_SIZE == 66 && CHUNK_NUMBER == 8){
        component ecAddOptimised = EllipticCurveAddOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        ecAddOptimised.in1 <== in1;
        ecAddOptimised.in2 <== in2;
        ecAddOptimised.dummy <== dummy;
        out <== ecAddOptimised.out;
    } else {
        component ecAddNonOptimised = EllipticCurveAddNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        ecAddNonOptimised.in1 <== in1;
        ecAddNonOptimised.in2 <== in2;
        ecAddNonOptimised.dummy <== dummy;
        out <== ecAddNonOptimised.out;
    }
}

template EllipicCurveScalarGeneratorMultiplication(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input scalar[CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    signal output out[2][CHUNK_NUMBER];
    
    if (CHUNK_SIZE == 64 && CHUNK_NUMBER == 4 || CHUNK_NUMBER == 8 && CHUNK_SIZE == 66){
        component ecGenMultOptimised = EllipicCurveScalarGeneratorMultiplicationOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        ecGenMultOptimised.scalar <== scalar;
        ecGenMultOptimised.dummy <== dummy;
        out <== ecGenMultOptimised.out;
    } else {
        component ecGenMultNonOptimised = EllipicCurveScalarGeneratorMultiplicationNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        ecGenMultNonOptimised.scalar <== scalar;
        ecGenMultNonOptimised.dummy <== dummy;
        out <== ecGenMultNonOptimised.out;
    }
}

template EllipicCurveScalarPrecomputeMultiplication(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    var STRIDE = 8;
    var parts = CHUNK_NUMBER * CHUNK_SIZE \ STRIDE;
    
    signal input scalar[CHUNK_NUMBER];
    signal input dummy;
    signal input in[2][CHUNK_NUMBER];
    signal input powers[parts][2 ** STRIDE][2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    
    dummy * dummy === 0;
    
    if (CHUNK_SIZE == 64 && CHUNK_NUMBER == 4){
        component scalarMultOptimised = EllipicCurveScalarPrecomputeMultiplicationOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        scalarMultOptimised.in <== in;
        scalarMultOptimised.scalar <== scalar;
        scalarMultOptimised.powers <== powers;
        scalarMultOptimised.dummy <== dummy;
        out <== scalarMultOptimised.out;
    } else {
        component scalarMultNonOptimised = EllipicCurveScalarPrecomputeMultiplicationNonOptimised(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
        scalarMultNonOptimised.in <== in;
        scalarMultNonOptimised.scalar <== scalar;
        scalarMultNonOptimised.powers <== powers;
        scalarMultNonOptimised.dummy <== dummy;
        out <== scalarMultNonOptimised.out;
        
    }
}