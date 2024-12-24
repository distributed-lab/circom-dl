pragma circom  2.1.6;

include "../bigInt/bigIntFunc.circom";
include "../bigInt/bigInt2.circom";
include "../bigInt/bigIntOverflow2.circom";
include "../bigInt/bigIntHelpers.circom";
include "./get.circom";
include "./powers/p256pows.circom";
include "./powers/p384pows.circom";
include "./powers/secp192r1pows.circom";
include "./powers/secp224r1pows.circom";
include "./powers/secp256k1pows.circom";
include "./powers/secp521r1pows.circom";
include "./powers/brainpoolP224r1pows.circom";
include "./powers/brainpoolP256r1pows.circom";
include "./powers/brainpoolP320r1pows.circom";
include "./powers/brainpoolP384r1pows.circom";
include "./powers/brainpoolP512r1pows.circom";
include "../utils/switcher.circom";
include "../bitify/bitify.circom";
include "../bitify/comparators.circom";
include "../int/arithmetic.circom";

// Check for point 
template PointOnCurve(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    
    component square = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    square.in1 <== in[0];
    square.in2 <== in[0];
    square.dummy <== dummy;
    
    component cube = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    cube.in1 <== square.out;
    cube.in2 <== in[0];
    cube.dummy <== dummy;
    
    component square2 = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    square2.in1 <== in[1];
    square2.in2 <== in[1];
    square2.dummy <== dummy;
    
    component coefMult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    coefMult.in1 <== in[0];
    coefMult.in2 <== A;
    coefMult.dummy <== dummy;
    
    component isZeroModP = BigIntIsZeroModP(CHUNK_SIZE, CHUNK_SIZE * 3 + 2 * CHUNK_NUMBER, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER * 3, CHUNK_NUMBER);
    for (var i = 0; i < CHUNK_NUMBER; i++){
        isZeroModP.in[i] <== cube.out[i] + coefMult.out[i] - square2.out[i] + B[i];
    }
    for (var i = CHUNK_NUMBER; i < CHUNK_NUMBER * 2 - 1; i++){
        isZeroModP.in[i] <== cube.out[i] + coefMult.out[i] - square2.out[i];
    }
    for (var i = CHUNK_NUMBER * 2 - 1; i < CHUNK_NUMBER * 3 - 2; i++){
        isZeroModP.in[i] <== cube.out[i];
    }
    isZeroModP.modulus <== P;
    isZeroModP.dummy <== dummy;
}

// Check is point on tangent (for doubling check)
// (x, y), point that was doubled, (x3, y3) - result 
// λ = (3 * x ** 2 + a) / (2 * y)
// y3 = λ * (x - x3) - y
// 2 * y * (y3 + y) = (3 * x ** 2 + a) * (x - x3)
template PointOnTangent(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal input dummy;
    
    component square = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    square.in1 <== in1[0];
    square.in2 <== in1[0];
    square.dummy <== dummy;
    
    component scalarMult = ScalarMultOverflow(CHUNK_NUMBER * 2 - 1);
    scalarMult.in <== square.out;
    scalarMult.scalar <== 3;
    
    component bigAdd = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    bigAdd.in1 <== scalarMult.out;
    bigAdd.in2 <== A;
    bigAdd.dummy <== dummy;
    
    component bigSub = BigSubModP(CHUNK_SIZE, CHUNK_NUMBER);
    bigSub.in1 <== in1[0];
    bigSub.in2 <== in2[0];
    bigSub.modulus <== P;
    bigSub.dummy <== dummy;
    
    component rightMult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER);
    rightMult.in1 <== bigAdd.out;
    rightMult.in2 <== bigSub.out;
    rightMult.dummy <== dummy;
    
    component scalarMult2 = ScalarMultOverflow(CHUNK_NUMBER);
    scalarMult2.in <== in1[1];
    scalarMult2.scalar <== 2;
    
    component bigAdd2 = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    bigAdd2.in1 <== in1[1];
    bigAdd2.in2 <== in2[1];
    bigAdd2.dummy <== dummy;
    
    component leftMult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    leftMult.in1 <== bigAdd2.out;
    leftMult.in2 <== scalarMult2.out;
    leftMult.dummy <== dummy;
    
    component isZeroModP = BigIntIsZeroModP(CHUNK_SIZE, CHUNK_SIZE * 3 + 2 * CHUNK_NUMBER, CHUNK_NUMBER * 3 - 2, CHUNK_NUMBER * 3 + 1, CHUNK_NUMBER);
    for (var i = 0; i < CHUNK_NUMBER * 2 - 1; i++){
        isZeroModP.in[i] <== rightMult.out[i] - leftMult.out[i];
    }
    for (var i = CHUNK_NUMBER * 2 - 1; i < CHUNK_NUMBER * 3 - 2; i++){
        isZeroModP.in[i] <== rightMult.out[i];
    }
    
    isZeroModP.modulus <== P;
    isZeroModP.dummy <== dummy;
    
}

// in1 = (x1, y1)
// in2 = (x2, y2)
// in3 = (x3, y3) (sum of (x1, y1), (x2, y2))
// Implements constraint: (y1 + y3) * (x2 - x1) - (y2 - y1) * (x1 - x3) = 0 mod P
// used to show (x1, y1), (x2, y2), (x3, -y3) are co-linear
template PointOnLine(CHUNK_SIZE, CHUNK_NUMBER, A, B, P) {
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal input in3[2][CHUNK_NUMBER];
    signal input dummy;

    
    component bigAdd = BigAddOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    bigAdd.in1 <== in1[1];
    bigAdd.in2 <== in3[1];
    bigAdd.dummy <== dummy;
    
    component bigSub = BigSubModP(CHUNK_SIZE, CHUNK_NUMBER);
    bigSub.in1 <== in2[0];
    bigSub.in2 <== in1[0];
    bigSub.modulus <== P;
    bigSub.dummy <== dummy;
    
    component bigSub2 = BigSubModP(CHUNK_SIZE, CHUNK_NUMBER);
    bigSub2.in1 <== in2[1];
    bigSub2.in2 <== in1[1];
    bigSub2.modulus <== P;
    bigSub2.dummy <== dummy;
    
    component bigSub3 = BigSubModP(CHUNK_SIZE, CHUNK_NUMBER);
    bigSub3.in1 <== in1[0];
    bigSub3.in2 <== in3[0];
    bigSub3.modulus <== P;
    bigSub3.dummy <== dummy;
    
    component leftMult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    leftMult.in1 <== bigAdd.out;
    leftMult.in2 <== bigSub.out;
    leftMult.dummy <== dummy;
    
    component rightMult = BigMultOverflow(CHUNK_SIZE, CHUNK_NUMBER, CHUNK_NUMBER);
    rightMult.in1 <== bigSub2.out;
    rightMult.in2 <== bigSub3.out;
    rightMult.dummy <== dummy;
    
    
    component isZeroModP = BigIntIsZeroModP(CHUNK_SIZE, CHUNK_SIZE * 2 + 2 * CHUNK_NUMBER, CHUNK_NUMBER * 2 - 1, CHUNK_NUMBER * 2 + 1, CHUNK_NUMBER);
    for (var i = 0; i < CHUNK_NUMBER * 2 - 1; i++){
        isZeroModP.in[i] <== leftMult.out[i] - rightMult.out[i];
    }
    
    isZeroModP.modulus <== P;
    isZeroModP.dummy <== dummy;
}

// Precomputes for pipinger optimised multiplication
// Computes 0 * G, 1 * G, 2 * G, ... (2 ** WINDOW_SIZE - 1) * G
template EllipticCurvePrecomputePipinger(CHUNK_SIZE, CHUNK_NUMBER, A, B, P, WINDOW_SIZE){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    
    var PRECOMPUTE_NUMBER = 2 ** WINDOW_SIZE;
    
    signal output out[PRECOMPUTE_NUMBER][2][CHUNK_NUMBER];
    dummy * dummy === 0;
    
    component getDummy = EllipticCurveGetDummy(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    out[0] <== getDummy.dummyPoint;

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

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// λ = (3 * x ** 2 + a) / (2 * y)
// x3 = λ * λ - 2 * x
// y3 = λ * (x - x3) - y
// We check is point is lies both on tangent and curve to assume that point is result of doubling
template EllipticCurveDouble(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in[2][CHUNK_NUMBER];
    signal input dummy;
    signal output out[2][CHUNK_NUMBER];
    
    var long_3[CHUNK_NUMBER];
    long_3[0] = 3;
    var lamb_num[200] = long_add_mod(CHUNK_SIZE, CHUNK_NUMBER, A, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, long_3, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, in[0], in[0], P), P), P);
    var lamb_denom[200] = long_add_mod(CHUNK_SIZE, CHUNK_NUMBER, in[1], in[1], P);
    var lamb[200] = prod_mod(CHUNK_SIZE, CHUNK_NUMBER, lamb_num, mod_inv(CHUNK_SIZE, CHUNK_NUMBER, lamb_denom, P), P);
    var x3[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, lamb, lamb, P), long_add_mod(CHUNK_SIZE, CHUNK_NUMBER, in[0], in[0], P), P);
    var y3[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, lamb, long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, in[0], x3, P), P), in[1], P);
    
    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[0][i] <-- x3[i];
        out[1][i] <-- y3[i];
    }
    
    // We check for result point be both on tangent and curve
    component onTangentCheck = PointOnTangent(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    onTangentCheck.in1 <== in;
    onTangentCheck.in2 <== out;
    onTangentCheck.dummy <== dummy;
    
    component onCurveCheck = PointOnCurve(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    onCurveCheck.in <== out;
    onCurveCheck.dummy <== dummy;
    
    // In circom pairing lib, there were 2 other checks checks. 
    // First is for each chunk is in range [0, 2**CHUNK_NUMBER).
    // Which is just overflow check, and it isn`t nessesary because we will get valid results even with overflow inputs
    // But it`s recommended to to this check for the last point in all ec operations (last add in ecdsa, for example)
    // Second is check for out[0] and out[1] both less than P. Same as previous, this one shouldn`t add any problems, 
    // cause potential overflow over circom field will ruin onCurve check, and just chunk overflow isn`t a real problem for us,
    // cause we work with overflowed values.
}

// We check is point both on curve and line ((x1, y1), (x2, y2), (x3, -y3) are co-linear) to assume that this is result of addition
template EllipticCurveAdd(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    signal input in1[2][CHUNK_NUMBER];
    signal input in2[2][CHUNK_NUMBER];
    signal input dummy;
    
    signal output out[2][CHUNK_NUMBER];
    
    var dy[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, in2[1], in1[1], P);
    var dx[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, in2[0], in1[0], P);
    var dx_inv[200] = mod_inv(CHUNK_SIZE, CHUNK_NUMBER, dx, P);
    var lambda[200] = prod_mod(CHUNK_SIZE, CHUNK_NUMBER, dy, dx_inv, P);
    var lambda_sq[200] = prod_mod(CHUNK_SIZE, CHUNK_NUMBER, lambda, lambda, P);
    var x3[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, lambda_sq, in1[0], P), in2[0], P);
    var y3[200] = long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, prod_mod(CHUNK_SIZE, CHUNK_NUMBER, lambda, long_sub_mod(CHUNK_SIZE, CHUNK_NUMBER, in1[0], x3, P), P), in1[1], P);

    for (var i = 0; i < CHUNK_NUMBER; i++){
        out[0][i] <-- x3[i];
        out[1][i] <-- y3[i];
    }

    
    component onCurveCheck = PointOnCurve(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    onCurveCheck.in <== out;
    onCurveCheck.dummy <== dummy;
    
    component onLineCheck = PointOnLine(CHUNK_SIZE, CHUNK_NUMBER, A, B, P);
    onLineCheck.in1 <== in1;
    onLineCheck.in2 <== in2;
    onLineCheck.in3 <== out;
    onLineCheck.dummy <== dummy;
    
    
    
    // same as previous, this checks should be enought, no need in range checks
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
template EllipticCurveScalarMult(CHUNK_SIZE, CHUNK_NUMBER, A, B, P, WINDOW_SIZE){
    
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
    
    resultingPoints[0] <== precompute.out[0];
    
    for (var i = 0; i < CHUNK_NUMBER * CHUNK_SIZE; i += WINDOW_SIZE){
        bits2Num[i \ WINDOW_SIZE] = Bits2Num(WINDOW_SIZE);
        for (var j = 0; j < WINDOW_SIZE; j++){
            bits2Num[i \ WINDOW_SIZE].in[j] <== scalarBits[i + (WINDOW_SIZE - 1) - j];
        }
        
        isZeroResult[i \ WINDOW_SIZE] = IsEqual();
        isZeroResult[i \ WINDOW_SIZE].in[0] <== resultingPoints[i \ WINDOW_SIZE][0][0];
        isZeroResult[i \ WINDOW_SIZE].in[1] <== getDummy.dummyPoint[0][0];
        
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
            
            isZeroAddition[i \ WINDOW_SIZE] = IsEqual();
            isZeroAddition[i \ WINDOW_SIZE].in[0] <== additionPoints[i \ WINDOW_SIZE][0][0];
            isZeroAddition[i \ WINDOW_SIZE].in[1] <== getDummy.dummyPoint[0][0];
            
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
