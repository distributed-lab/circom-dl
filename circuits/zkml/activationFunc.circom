pragma circom 2.1.6;

template ReLU() {
    signal input in;

    signal output out;

    component comp = IsNegative();
    comp.in <== in;

    out = in * (1 - comp.out);
}