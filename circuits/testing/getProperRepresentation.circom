pragma circom 2.1.6;

include "bigInt-func.circom";

template Test() {
    signal input in[100];
    var ab_proper[100]

    out = getProperRepresentation(10, 4, 10, in);
}

component main = Test();