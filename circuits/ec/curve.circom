pragma circom  2.1.6;

include "../bigInt/bigIntOverflow.circom";
include "../bigInt/bigIntFunc.circom";

// Operation for any Weierstrass prime-field eliptic curve (for now 256-bit)
// A, B, P in every function - params of needed curve, chunked the same as every other chunking (64 4 for now)
// Example usage of operation (those are params for secp256k1 ec):
// EllipticCurveDouble(64, 4, [0,0,0,0], [7,0,0,0], [18446744069414583343, 18446744073709551615, 18446744073709551615, 18446744073709551615]);

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
// Don`t use next templates within default point operations without understanding what are u doing, default curve operations will be below
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
// TODO: Research why (x3, y3) passes this check and will it harm the security and force us to use more checks:
// λ = (y2 - y1) / (x2 - x1)
// x3 = (λ * λ - x1 - x1 % p)
// y3 = (λ * (x1 - x3) - y1) % p
// Correct formula for it is:
// x3 = (λ * λ - x1 - x2 % p) // here - x1 - x2, not -2 * x1
// y3 = (λ * (x1 - x3) - y1) % p
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
// Default point operations, use them for ec calculations

// Check if given point lies on curve
// y**2 % p === (x**3 + a*x + b) % p
template PointOnCurve(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
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

// THIS IS UNSECURE, NEVER (NEVER!!!!!!!!!) USE IT IN PRODUCTION!!!!!!!!!!!
// Calculate doubled point by vars, then check if returned point lies on tangent
// Slightly recomended to check output for PointOnCurve if it is last operation for point,
// but it isn`t nessesary if it is operation in middle, it will fail in next point operation
template EllipticCurveDoubleDEPRECATED(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    signal input in[2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    var LONG3[CHUNK_NUMBER];
    LONG3[0] = 3;
    for (var i = 1; i < CHUNK_NUMBER; i++) {
        LONG3[i] = 0;
    }
    
    var lamb_num[200] = long_add_mod(CHUNK_SIZE, CHUNK_NUMBER, A, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, LONG3, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, in[0], in[0], P), P), P);
    var lamb_denom[200] = long_add_mod(CHUNK_SIZE, CHUNK_NUMBER, in[1], in[1], P);
    var lamb[200] = prod_mod(CHUNK_SIZE, CHUNK_NUMBER, lamb_num, mod_inv(CHUNK_SIZE, CHUNK_NUMBER, lamb_denom, P), P);
    
    var x3[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, lamb, lamb, P), long_add_mod(CHUNK_SIZE, CHUNK_NUMBER, in[0], in[0], P), P);
    var y3[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, lamb, long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, in[0], x3, P), P), in[1], P);
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[0][i] <-- x3[i];
        out[1][i] <-- y3[i];
    }
    
    component tangentCheck = TangentCheck(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    tangentCheck.in1 <== in;
    tangentCheck.in2 <== out;
    tangentCheck.dummy <== dummy;
    
}

// THIS IS UNSECURE, NEVER (NEVER!!!!!!!!!) USE IT IN PRODUCTION!!!!!!!!!!!
// Calculate sum of points by vars, then check if returned point is sum of 2 points
// Slightly recomended to check output for PointOnCurve if it is last operation for point,
// but it isn`t nessesary if it is operation in middle, it will fail in next point operation
template EllipticCurveAddDEPRECATED(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal output out[2][CHUNK_NUMBER];
    signal input dummy;
    dummy * dummy === 0;
    
    var DY[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, in2[1], in1[1], P);
    var DX[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, in2[0], in1[0], P);

    var DX_INV[200] = mod_inv(CHUNK_SIZE, CHUNK_NUMBER, DX, P);
    var LAMBDA[200] = prod_mod(CHUNK_SIZE, CHUNK_NUMBER, DY, DX_INV, P);

    var LAMBDA_SQ[200] = prod_mod(CHUNK_SIZE, CHUNK_NUMBER, LAMBDA, LAMBDA, P);


    var X3[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, LAMBDA_SQ, in1[0], P), in2[0], P);
    var Y3[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, LAMBDA, long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, in1[0], X3, P), P), in1[1], P);
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[0][i] <-- X3[i];
        out[1][i] <-- Y3[i];
    }
    
    component additionCheck = AdditionCheck(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    additionCheck.in1 <== in1;
    additionCheck.in2 <== in2;
    additionCheck.in3 <== out;
    additionCheck.dummy <== dummy;  
}

// λ = (3 * x ** 2 + a) / (2 * y)
// x3 = λ * λ - 2 * x
// y3 = λ * (x - x3) - y
template EllipticCurveDouble(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
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
template EllipticCurveAdd(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    
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

    // (λ * (x1 - x3) + P - y1) % p ==> y3
    component mod3 = BigModOverflow(CHUNK_SIZE, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER, 3);
    mod3.base <== add3.out;
    mod3.modulus <== P;
    mod3.dummy <== dummy;
    
    out[1] <== mod3.mod;
}