pragma circom 2.1.6;

include "../float/float.circom";

template ReLU() {
    signal input in;

    signal output out;

    component comp = FloatIsNegative();
    comp.in <== in;
    out <== in * (1 - comp.out);
}