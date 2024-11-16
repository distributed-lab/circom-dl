pragma circom  2.1.6;

include "../bigInt/bigIntOverflow.circom";
include "../bigInt/bigIntFunc.circom";

// Operation for any Weierstrass prime-field eliptic curve (for now 256-bit)
// For now, use only 64 4 bigInt chunking (will be changed to any later)
// A, B, P in every function - params of needed curve, chunked the same as every other chunking (64 4 for now)
// Example usage of operation (those are params for secp256k1 ec):
// Double(64, 4, [0,0,0,0], [7,0,0,0], [18446744069414583343, 18446744073709551615, 18446744073709551615, 18446744073709551615]);


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

// Check is point on tangent (for doubling check)
// λ = (3 * x ** 2 + a) / (2 * y)
// y_2 = λ * (x - x_2) - y
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

// Calculate doubled point by vars, then check if returned point lies on tangent
// Slightly recomended to check output for PointOnCurve if it is last operation for point,
// but it isn`t nessesary if it is operation in middle, it will fail in next point operation
template Double(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){

    assert(CHUNK_SIZE == 64);

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
    
    for(var i = 0; i < CHUNK_NUMBER; i++){
        out[0][i] <-- x3[i];
        out[1][i] <-- y3[i];
    }

    component tangentCheck = TangentCheck(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    tangentCheck.in1 <== in;
    tangentCheck.in2 <== out;
    tangentCheck.dummy <== dummy;

}