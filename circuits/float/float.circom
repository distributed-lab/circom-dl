pragma circom  2.1.6;

include "../int/arithmetic.circom";
include "./floatFunc.circom";
include "../utils/switcher.circom";

// There are some templates to operate with float nums
// In our implementation, every float number has presicion n,
// which mean that our representation on number:
// our_representation = (real_number * 2 **n) % 1
// for example, 6.5 with presition 8 will be (6.5 * 2**8) // 1 = 1664
// Addition and substraction for those numbers is the same as default:
// c <== a + b,
// a, b, c - floats in our realisation
// (don`t forget about linear constraint here!)
// for multiplying floats use next templates
//------------------------------------------------------------
// Multiplication of 2 floats with flooring
// Uses n*2 + 1 constraints
template FloatMult(n){
    signal input in[2];
    signal output out;
    
    component getLastNBits = GetLastNBits(n);
    getLastNBits.in <== in[0] * in[1];
    out <== getLastNBits.div;
    
    // var print1 = log_float(in[0], n);
    // var print2 = log_float(in[1], n);
    // var print3 = log_float(out, n);
    // var print4 = log_float(in[1] * in[0], 2 * n);
}

// Multiplication of 2 floats with ceiling
// Uses n*2 + 2 constraints (1 more than previous for ceiling)
template FloatMultCeil(n){
    signal input in[2];
    signal output out;
    
    component getLastNBits = GetLastNBits(n);
    getLastNBits.in <== in[0] * in[1];
    out <== getLastNBits.div + getLastNBits.out[n - 1] * getLastNBits.out[n - 1];
    
    // var print1 = log_float(in[0], n);
    // var print2 = log_float(in[1], n);
    // var print3 = log_float(out, n);
    // var print4 = log_float(in[1] * in[0], 2 * n);
}

template FloatToArray(n){
    signal input in;
    signal output out[2];
    
    component getLastNBits = GetLastNBits(n);
    getLastNBits.in <== in;
    out[0] <== getLastNBits.div;
    component b2n = Bits2Num(n);
    b2n.in <== getLastNBits.out;
    out[1] <== b2n.out;
    
}

template FloatMultArray(n){
    signal input in1[2];
    signal input in2[2];
    
    signal output out[2];
    
    signal mults[2];
    mults[0] <== in1[0] * in2[1];
    mults[1] <== in2[0] * in1[1];
    
    component bits2Num = Bits2Num(n);
    component getLastNBits[2];
    getLastNBits[0] = GetLastNBits(n);
    getLastNBits[0].in <== mults[0] * 2 ** n + mults[1] * 2 ** n + in1[1] * in2[1];
    
    getLastNBits[1] = GetLastNBits(n);
    getLastNBits[1].in <== getLastNBits[0].div;
    
    bits2Num.in <== getLastNBits[1].out;
    
    out[0] <== getLastNBits[1].div + in1[0] * in2[0];
    out[1] <== bits2Num.out;
    
}

// calculates inverse (1 / in) of float in
template FloatInverse(n){
    signal input in;
    signal output out;
    
    out <-- 2 ** (2 * n) \ in;
    
    component floatToArrayIn = FloatToArray(n);
    component floatToArrayOut = FloatToArray(n);
    floatToArrayIn.in <== in;
    floatToArrayOut.in <== out;
    
    component mults[3];
    
    // mults[0] - in * (out+1)
    // mults[1] - in * out
    // mults[2] - in * (out-1)
    for (var i = 0; i < 3; i++){
        mults[i] = FloatMultArray(n);
        mults[i].in1 <== floatToArrayIn.out;
        mults[i].in2[0] <== floatToArrayOut.out[0];
        mults[i].in2[1] <== floatToArrayOut.out[1] + 1 - i;
    }
    
    component comparators[3];
    component switcher[3];
    
    for (var i = 0; i < 3; i++){

        comparators[i] = LessThan(n);
        comparators[i].in[0] <== mults[i].out[0] * 2 ** n + mults[i].out[1];
        comparators[i].in[1] <== 2 ** n;
        
        switcher[i] = Switcher();
        switcher[i].bool <== comparators[i].out;
        switcher[i].in[0] <== 2 ** n - mults[i].out[0] * 2 ** n - mults[i].out[1];
        switcher[i].in[1] <== mults[i].out[0] * 2 ** n + mults[i].out[1] - 2 ** n;
    }

    component comparatorsResult[2];

    for (var i = 0; i < 2; i++){
        comparatorsResult[i] = LessEqThan(n);
        comparatorsResult[i].in[0] <== switcher[1].out[1];
        comparatorsResult[i].in[1] <== switcher[2 * i].out[1];

        comparatorsResult[i].out === 1;
    }
}


// Set new presicition 
// new presition(n2) is always smaller than old one(n1)
// use for sum of multiple muls for more accuracy and less constraints
template RemovePrecision(n1, n2){
    assert (n2 > n1);
    
    signal input in;
    signal output out;
    component getLastNBits = GetLastNBits(n2 - n1);
    getLastNBits.in <== in;
    out <== getLastNBits.div + getLastNBits.out[n2 - n1 - 1] * getLastNBits.out[n2 - n1 - 1];
}

// Computes e ^ x, where x is float by Teilor series.
//      inf
// e^x = ∑ (x^k)/(k!)
//      k=0
template Exp(n){
    assert(n >= 4);
    signal input in;
    signal input dummy;
    signal output out;
    
    component mult[n \ 2 - 1];
    for (var i = 0; i < n \ 2 - 1; i++){
        mult[i] = FloatMultCeil(n);
        if (i == 0){
            mult[i].in[0] <== in;
            mult[i].in[1] <== in;
        } else {
            mult[i].in[0] <== in;
            mult[i].in[1] <== mult[i - 1].out;
        }
    }
    
    var precompute[100] = precompute_exp_constants(n \ 2 + 1, n);
    component sum = GetSumOfNElements(n \ 2 + 1);
    sum.dummy <== dummy;
    sum.in[0] <== precompute[0] * 2 ** n;
    for (var i = 1; i < n \ 2 + 1; i++){
        if (i == 1){
            sum.in[i] <== in * precompute[i];
        } else {
            sum.in[i] <== mult[i - 2].out * precompute[i];
        }
    }

    component reduce = RemovePrecision(n, 2 * n);
    reduce.in <== sum.out;
    out <== reduce.out;
}

template FloatIsNegative(){
    signal input in;
    signal output out;

    var QUATER_P = (-1) \ 4; 

    component getLastBit = GetLastBit();

    getLastBit.in <== in;
    component n2b = Num2Bits(254);

    n2b.in <== 2 ** 253 - QUATER_P + getLastBit.div;

    out <== n2b.out[253];
}