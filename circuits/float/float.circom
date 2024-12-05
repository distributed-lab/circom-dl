pragma circom  2.1.6;

include "../int/arithmetic.circom";
include "./floatFunc.circom";

// There are some templates to operate with float nums
// In our implementation, every float number has presicion n,
// which mean that our representation on number:
// our_representation = (real_number * 2 **n) % 1
// for example, 6.5 with presition 8 will be (6.5 * 2**8) % 1 = 1664
// Addition and substraction for those numbers is the same as default:
// c <== a + b,
// a, b, c - floats in our realisation
// (don`t forget about linear constraint here!)
// for multiplying floats use next templates
//------------------------------------------------------------
// Multiplication of 2 floats with ceiling down
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