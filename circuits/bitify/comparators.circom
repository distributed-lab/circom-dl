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

template LessThan(LEN) {
    assert(LEN <= 252);
    signal input in[2];
    signal output out;
    
    component n2b = Num2Bits(LEN + 1);
    
    n2b.in <== in[0] + (1 << LEN) - in[1];
    
    out <== 1 - n2b.out[LEN];
}

template LessEqThan(LEN) {
    signal input in[2];
    signal output out;
    
    component lessThan = LessThan(LEN);
    
    lessThan.in[0] <== in[0];
    lessThan.in[1] <== in[1] + 1;
    lessThan.out ==> out;
}

template GreaterThan(LEN) {
    signal input in[2];
    signal output out;
    
    component lt = LessThan(LEN);
    
    lt.in[0] <== in[1];
    lt.in[1] <== in[0];
    lt.out ==> out;
}

template GreaterEqThan(LEN) {
    signal input in[2];
    signal output out;
    
    component lt = LessThan(LEN);
    
    lt.in[0] <== in[1];
    lt.in[1] <== in[0] + 1;
    lt.out ==> out;
}

