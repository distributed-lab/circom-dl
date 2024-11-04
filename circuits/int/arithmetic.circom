pragma circom 2.1.6;

include "../../node_modules/circomlib/circuits/comparators.circom";

template Inverse(){
    signal input in;
    signal output out;
    out <-- 1 / in;
    out * in === 1;
}

//use if u don`t know what is len of bit representation of in[0] is
template DivisionStrict(){
    signal input in[2];

    signal output mod; //in[0] % in[1]
    signal output div; //in[0] \ in[1]

    mod <-- in[0] % in[1];
    div <-- in[0] \ in[1];

    div * in[1] + mod === in[0];
    component check1 = LessEqThan(252);
    component check2 = GreaterThan(252);

    check1.in[0] <== div * in[1];
    check1.in[1] <== in[0];
    check1.out === 1;

    check2.in[0] <== (div + 1) * in[1];
    check2.in[1] <== in[0];
    check2.out === 1;

}


//use this if u know what len of bit representation of in[1] is
template Division(LEN){

    assert (LEN < 253);
    signal input in[2];

    signal output div; //in[0] \ in[1]
    signal output mod; //in[0] % in[1]

    mod <-- in[0] % in[1];
    div <-- in[0] \ in[1];

    div * in[1] + mod === in[0];
    component check1 = LessEqThan(LEN);
    component check2 = GreaterThan(LEN);

    check1.in[0] <== div * in[1];
    check1.in[1] <== in[0];
    check1.out === 1;

    check2.in[0] <== (div + 1) * in[1];
    check2.in[1] <== in[0];
    check2.out === 1;

}