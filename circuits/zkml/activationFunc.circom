pragma circom 2.1.6;

include "../float/float.circom";

template ReLU() {
    signal input in;

    signal output out;

    component comp = FloatIsNegative();
    comp.in <== in;
    out <== in * (1 - comp.out);
}

template ReLU6(prec) {
    signal input in;

    signal output out;

    component comp = FloatIsNegative();
    comp.in <== in;
    
    component comp2 = FloatIsNegative();
    comp2.in <== (in - (6 * 2 ** prec));

    signal temp <== in * (1 - comp.out);
    out <== (1 - comp2.out) * (6 * 2 ** prec - in) + temp;
}

//Saves about 254 constraints
template ReLUwithCutPrecision(precNew, precOld) {
    assert (precNew < precOld);
    
    signal input in;
    signal output out;
    component num2Bits = Num2Bits(254);
    num2Bits.in <== in;
    component bits2Num = Bits2Num(253);
    for (var i = 0; i < 253; i++) {
        if (i > 252 - (precOld-precNew)) {
            bits2Num.in[i] <== 0;
        }
        else {
            bits2Num.in[i] <== num2Bits.out[(precOld-precNew) + i];
        }
    }

    out <== bits2Num.out * (1-num2Bits.out[253]);
}

template ReLU6withCutPrecision(precNew, precOld) {
    assert (precNew < precOld);
    
    signal input in;
    signal output out;
    component num2Bits = Num2Bits(254);
    num2Bits.in <== in;
    component bits2Num = Bits2Num(253);
    for (var i = 0; i < 253; i++) {
        if (i > 252 - (precOld-precNew)) {
            bits2Num.in[i] <== 0;
        }
        else {
            bits2Num.in[i] <== num2Bits.out[(precOld-precNew) + i];
        }
    }

    component num2Bits6 = Num2Bits(254);
    num2Bits6.in <== in - (6 * 2 ** precOld);

    signal temp <== bits2Num.out * (1 - num2Bits.out[253]);
    out <== (1 - num2Bits6.out[253]) * (6 * 2 ** precNew - bits2Num.out) + temp;
    log(out);
}

template MatrixReLUwithCutPrecision(n, m, precNew, precOld) {
    assert (precNew < precOld);

    signal input in[n][m];
    signal output out[n][m];

    component relu[n][m];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j < m; j++) {
            relu[i][j] = parallel ReLUwithCutPrecision(precNew, precOld);
            relu[i][j].in <== in[i][j];
            out[i][j] <== relu[i][j].out;
        }
    }
}

template MatrixReLU6withCutPrecision(n, m, precNew, precOld) {
    assert (precNew < precOld);

    signal input in[n][m];
    signal output out[n][m];

    component relu[n][m];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j < m; j++) {
            relu[i][j] = parallel ReLU6withCutPrecision(precNew, precOld);
            relu[i][j].in <== in[i][j];
            out[i][j] <== relu[i][j].out;
        }
    }
}