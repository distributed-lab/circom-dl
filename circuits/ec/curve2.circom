pragma circom  2.1.6;

include "../bigInt/bigIntFunc.circom";
include "../bigInt/bigInt2.circom";
include "../bigInt/bigIntOverflow2.circom";
include "../bigInt/bigIntHelpers.circom";

template PointOnLine(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;

    component square = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    square.in1 <== in[0];
    square.in2 <== in[0];
    square.dummy <== dummy;

    component cube = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    square.in1 <== square.out;
    square.in2 <== in[1];
    square.dummy <== dummy;

    component square2 = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    square2.in1 <== in[1];
    square2.in2 <== in[1];
    square2.dummy <== dummy;

}

// λ = (3 * x ** 2 + a) / (2 * y)
// x3 = λ * λ - 2 * x
// y3 = λ * (x - x3) - y
template Double(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    signal output out[2][CHUNK_NUMBER];

    component scalarMult = ScalarMultOverflow(CHUNK_NUMBER);
    scalarMult.in <== in[1];
    scalarMult.scalar <== 2;
    
    component modInv = BigModInv(CHUNK_SIZE, CHUNK_NUMBER);
    modInv.in <== scalarMult.out;
    modInv.modulus <== P;
    modInv.dummy <== dummy;

    component square = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    square.in1 <== in[0];
    square.in2 <== in[0];
    square.dummy <== dummy;

    component scalarMult2 = ScalarMultOverflow(CHUNK_NUMBER * 2 - 1);
    scalarMult2.in <== square.out;
    scalarMult2.scalar <== 3;

    component bigAdd = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    bigAdd.in1 <== scalarMult2.out;
    bigAdd.in2 <== A;
    bigAdd.dummy <== dummy;

    component bigMultModP = BigMultModP(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER, CHUNK_NUMBER);
    bigMultModP.in1 <== bigAdd.out;
    bigMultModP.in2 <== modInv.out;
    bigMultModP.modulus <== P;
    bigMultModP.dummy <== dummy;

}
