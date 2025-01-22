pragma circom 2.1.6;

include "../ec/curve.circom";
include "../ec/get.circom";
include "../bigInt/bigInt.circom";
include "../bigInt/bigIntFunc.circom";
include "../utils/switcher.circom";

template EcRecover(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input v;
    signal input r[CHUNK_NUMBER];
    signal input s[CHUNK_NUMBER];
    signal input hashed[CHUNK_NUMBER];
    signal input dummy;
    
    signal output out[2][CHUNK_NUMBER];
    
    
    component getOrder = EllipicCurveGetOrder(CHUNK_SIZE,CHUNK_NUMBER, A, B, P);
    signal order[CHUNK_NUMBER];
    order <== getOrder.order;
    
    
    component getGenerator = EllipticCurveGetGenerator(CHUNK_SIZE,CHUNK_NUMBER, A, B, P);
    signal gen[2][CHUNK_NUMBER];
    gen <== getGenerator.gen;
    
    component switcher[CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        switcher[i] = Switcher();
        switcher[i].in[0] <== r[i];
        switcher[i].in[1] <== r[i] + order[i];
        switcher[i].bool <== v;
    }
    
    component getX = BigMod(CHUNK_SIZE, CHUNK_NUMBER + 1, CHUNK_NUMBER);
    for (var i = 0; i < CHUNK_NUMBER; i++){
        getX.base[i] <== switcher[i].out[0];
    }
    getX.base[CHUNK_NUMBER] <== 0;
    getX.dummy <== dummy;
    getX.modulus <== P;
    
    component squareX = BigMultModP(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, CHUNK_NUMBER);
    squareX.in1 <== getX.mod;
    squareX.in2 <== getX.mod;
    squareX.modulus <== P;
    squareX.dummy <== dummy;
    
    component cubeX = BigMultModP(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, CHUNK_NUMBER);
    
    cubeX.in1 <== squareX.mod;
    cubeX.in2 <== getX.mod;
    cubeX.modulus <== P;
    cubeX.dummy <== dummy;
    
    component coefMult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    coefMult.in1 <== getX.mod;
    coefMult.in2 <== A;
    coefMult.dummy <== dummy;
    
    component getYSquare = BigMod(CHUNK_SIZE, CHUNK_NUMBER + 1, CHUNK_NUMBER);
    for (var i = 0; i < CHUNK_NUMBER; i++){
        getYSquare.base[i] <== cubeX.mod[i] + coefMult.out[i] + B[i];
    }
    getYSquare.base[CHUNK_NUMBER] <== 0;
    getYSquare.dummy <== dummy;
    getYSquare.modulus <== P;

    for (var i = 0; i < 4; i++){
        log(getYSquare.mod[i]);
    }
    
    // TODO: CHANGE FOR OTHER CHUNKING!!!!!
    var exp[4] = [18446744072635809548, 18446744073709551615, 18446744073709551615, 4611686018427387903];
    var var_y[200] = mod_exp(CHUNK_SIZE, CHUNK_NUMBER, getYSquare.mod, P, exp);
    
    signal y[CHUNK_NUMBER];
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        y[i] <-- var_y[i];
    }
    
    component yVerify = BigMultModP(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER, CHUNK_NUMBER);
    yVerify.in1 <== y;
    yVerify.in2 <== y;
    yVerify.dummy <== dummy;
    yVerify.modulus <== P;
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        yVerify.mod === getYSquare.mod;
    }
    
    component modInv = BigModInv(CHUNK_SIZE, CHUNK_NUMBER);
    
    modInv.in <== r;
    modInv.modulus <== order;
    modInv.dummy <== dummy;
    
    component genMult = EllipicCurveScalarGeneratorMult(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    genMult.scalar <== hashed;
    genMult.dummy <== dummy;
    
    component scalarMult = EllipticCurveScalarMult(CHUNK_SIZE, CHUNK_NUMBER, A, B, P, 4);
    scalarMult.scalar <== s;
    scalarMult.dummy <== dummy;
    scalarMult.in[0] <== getX.mod;
    scalarMult.in[1] <== y;
    
    component negateY = BigSub(CHUNK_SIZE, CHUNK_NUMBER);
    negateY.in[0] <== P;
    negateY.in[1] <== genMult.out[1];
    negateY.dummy <== dummy;

    component pointAdd = EllipticCurveAdd(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    pointAdd.in1[0] <== genMult.out[0];
    pointAdd.in1[1] <== negateY.out;
    pointAdd.in2 <== scalarMult.out;
    pointAdd.dummy <== dummy;

    component scalarMult2 = EllipticCurveScalarMult(CHUNK_SIZE, CHUNK_NUMBER, A, B, P, 4);
    scalarMult2.scalar <== modInv.out;
    scalarMult2.dummy <== dummy;
    scalarMult2.in <== pointAdd.out;

    out <== scalarMult2.out;    
}