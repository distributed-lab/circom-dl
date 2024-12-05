pragma circom 2.1.6;

include "../bitify/bitify.circom";
include "../bitify/comparators.circom";
include "../int/arithmetic.circom";
include "./get.circom";

// Those templates for Babujubjub curve operations

//---------------------------------------------------------------------------------------------------------------------------------------
// Helpers templates, don`t use without full understanding!!!

// Returns sum of 2 points if two non-zero points,
// returns in1 if in2 point is zero,
// returns in2 if in1 point is zero,
// returns zero if in1 and in2 points are zero
// This template uses in scalar multiplication, don`t use it without undersrtanding what are u doing!!! 
template addZeroBabyjub(){
    signal input in1[2];
    signal input in2[2];
    signal output out[2];
    
    component isZeroIn1 = IsZero();
    isZeroIn1.in <== in1[0];
    component isZeroIn2 = IsZero();
    isZeroIn2.in <== in2[0];
    
    component adder = BabyjubjubAdd();
    adder.in1 <== in1;
    adder.in2 <== in2;
    
    // 0 0 -> adders
    // 0 1 -> left
    // 1 0 -> right
    // 1 1 -> right
    
    signal resultLeft[2];
    signal resultLeft2[2];
    signal resultRight[2];
    signal resultRight2[2];
    
    for (var i = 0; i < 2; i++){
        resultLeft[i] <== (1 - isZeroIn2.out) * adder.out[i];
        resultLeft2[i] <== isZeroIn2.out * in1[i];
        resultRight[i] <== isZeroIn1.out * in2[i];
        resultRight2[i] <== (1 - isZeroIn1.out) * (resultLeft[i] + resultLeft2[i]) + resultRight[i];
    }
    
    out <== resultRight2;
}

//---------------------------------------------------------------------------------------------------------------------------------------

// Computes (x3, y3) = (x1, y1) + (x2, y2)
// a = 168700
// d = 168696
// β = x1 * y2
// Ɣ = x2 * y1
// δ = (y1 - x1 * a) * (x2 + y2)
// τ = x1 * x2 * y1 * y2
// x3 = (β + Ɣ) / (1 + d * τ)
// y3 = (δ + a * β - Ɣ) / (1 - d * τ)
template BabyjubjubAdd() {
    signal input in1[2];
    signal input in2[2];
    signal output out[2];
    
    signal beta;
    signal gamma;
    signal delta;
    signal tau;
    
    var a = 168700;
    var d = 168696;
    
    beta <== in1[0] * in2[1];
    gamma <== in1[1] * in2[0];
    delta <== (in1[1] - a * in1[0]) * (in2[0] + in2[1]);
    tau <== beta * gamma;
    
    out[0] <-- (beta + gamma) / (1 + d * tau);
    (1 + d * tau) * out[0] === (beta + gamma);
    
    out[1] <-- (delta + a * beta - gamma) / (1 - d * tau);
    (1 - d * tau) * out[1] === (delta + a * beta - gamma);
}

// Computes (x2, y2) = (x1, y1) + (x1, y1)
// Uses add under the hood
template BabyjubjubDouble() {
    signal input in[2];
    signal output out[2];
    
    component adder = BabyjubjubAdd();
    adder.in1 <== in;
    adder.in2 <== in;
    
    adder.out ==> out;
}

// Check is given point is point on curve
// Pass if point is on curve or fails if not
template BabyjubjubPointOnCurve() {
    signal input x;
    signal input y;
    
    signal x2;
    signal y2;
    
    var a = 168700;
    var d = 168696;
    
    x2 <== x * x;
    y2 <== y * y;
    
    a * x2 + y2 === 1 + d * x2 * y2;
}

// Scalar multiplication with base8 point
// Same as convert private key to public key
// don`t use 0 scalar, u will get [0,0], not error
// TODO: optimise - make it use less constraints because we know base8
template BabyjubjubBase8Multiplication(){
    signal input scalar;
    signal output out[2];
    
    component getBase8 = GetBabyjubjubBase8();
    
    component num2Bits = Num2Bits(254);
    num2Bits.in <== scalar;
    
    component adders[254];
    component doublers[253];
    component isEqual[254];
    
    for (var i = 0; i < 254; i++){
        isEqual[i] = IsEqual();
        isEqual[i].in[0] <== num2Bits.out[253 - i];
        isEqual[i].in[1] <== 1;
        adders[i] = addZeroBabyjub();
        if (i == 0){
            adders[i].in1 <== [0,0];
            adders[i].in2[0] <== getBase8.base8[0] * isEqual[i].out;
            adders[i].in2[1] <== getBase8.base8[1] * isEqual[i].out;
        } else {
            doublers[i - 1] = BabyjubjubDouble();
            doublers[i - 1].in <== adders[i - 1].out;
            adders[i].in1 <== doublers[i - 1].out;
            adders[i].in2[0] <== getBase8.base8[0] * isEqual[i].out;
            adders[i].in2[1] <== getBase8.base8[1] * isEqual[i].out;
        }
    }
    
    out <== adders[253].out;
}

// Scalar multiplication with any point
// in is point to multiply, scalar is scalar to multiply
// don`t use 0 scalar, u will get [0,0], not error
template BabyjubjubMultiplication(){
    signal input scalar;
    signal input in[2];
    
    signal output out[2];
    
    
    component num2Bits = Num2Bits(254);
    num2Bits.in <== scalar;
    
    component adders[254];
    component doublers[253];
    component isEqual[254];
    
    for (var i = 0; i < 254; i++){
        isEqual[i] = IsEqual();
        isEqual[i].in[0] <== num2Bits.out[253 - i];
        isEqual[i].in[1] <== 1;
        adders[i] = addZeroBabyjub();
        if (i == 0){
            adders[i].in1 <== [0,0];
            adders[i].in2[0] <== in[0] * isEqual[i].out;
            adders[i].in2[1] <== in[1] * isEqual[i].out;
        } else {
            doublers[i - 1] = BabyjubjubDouble();
            doublers[i - 1].in <== adders[i - 1].out;
            adders[i].in1 <== doublers[i - 1].out;
            adders[i].in2[0] <== in[0] * isEqual[i].out;
            adders[i].in2[1] <== in[1] * isEqual[i].out;
        }
    }
    
    out <== adders[253].out;
}
