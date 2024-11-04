pragma circom 2.1.6;

include "./bitify.circom";

template IsZero() {
    signal input in;
    signal output out;
    
    signal inv;
    
    inv <-- in != 0 ? 1 / in : 0;
    
    out <==  -in * inv + 1;
    in * out === 0;
}


template IsEqual() {
    signal input in[2];
    signal output out;
    
    component isZero = IsZero();
    
    isZero.in <== in[1] - in[0];
    
    isZero.out ==> out;
}

template ForceEqualIfEnabled() {
    signal input enabled;
    signal input in[2];
    
    component isEqual = IsEqual();
    isEqual.in <== in;
    (1 - isEqual.out) * enabled === 0;
}

template LessThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;
    
    component n2b = Num2Bits(n + 1);
    
    n2b.in <== in[0] + (1 << n) - in[1];
    
    out <== 1 - n2b.out[n];
}

template LessEqThan(n) {
    signal input in[2];
    signal output out;
    
    component lessThan = LessThan(n);
    
    lessThan.in[0] <== in[0];
    lessThan.in[1] <== in[1] + 1;
    lessThan.out ==> out;
}

template GreaterThan(n) {
    signal input in[2];
    signal output out;
    
    component lt = LessThan(n);
    
    lt.in[0] <== in[1];
    lt.in[1] <== in[0];
    lt.out ==> out;
}

template GreaterEqThan(n) {
    signal input in[2];
    signal output out;
    
    component lt = LessThan(n);
    
    lt.in[0] <== in[1];
    lt.in[1] <== in[0] + 1;
    lt.out ==> out;
}

