pragma circom 2.1.6;

include "../float/float.circom";
include "../utils/switcher.circom";

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

template PReLU(prec) {
    signal input in;
    signal input a; // value with precision 2**prec

    signal output out;

    component comp = FloatIsNegative();
    comp.in <== in;

    component switcher = Switcher();
    switcher.bool <== comp.out;
    switcher.in[0] <== in * (1 << prec);
    switcher.in[1] <== in * a; 

    out <== switcher.out[0];
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
}

template PReLUwithCutPrecision(precNew, precOld) {
    assert (precNew < precOld);

    //Decided to use constant value, change if needed, if a is power of 2 allows to save constraints by half, here a = 2^-k = 2^-4
    var k = 4;

    signal input in;
    signal output out;

    var absBits[253] = abs_in_bits(in);

    signal absInBits[253];
    component abs = Bits2Num(253);
    for (var i = 0; i < 253; i++) {
        absInBits[i] <-- absBits[i];
        absInBits[i]*(1-absInBits[i]) === 0;
        abs.in[i] <== absInBits[i];
    }
    (abs.out - in)*(abs.out + in) === 0;

    component sign = IsEqual();
    sign.in[0] <== abs.out;
    sign.in[1] <== in;

    component bits2Num = Bits2Num(253);
    component bits2NumA = Bits2Num(253);
    for (var i = 0; i < 253; i++) {
        if (i > 252 - (precOld-precNew)) {
            bits2Num.in[i] <== 0;
        }
        else {
            bits2Num.in[i] <== absInBits[(precOld-precNew) + i];
        }
        if (i > 252 - (precOld-precNew+k)) {
            bits2NumA.in[i] <== 0;
        }
        else {
            bits2NumA.in[i] <== absInBits[(precOld-precNew+k) + i];
        }
    }
    component switcher = Switcher();
    switcher.bool <== 1 - sign.out;
    switcher.in[0] <== bits2Num.out * sign.out;
    switcher.in[1] <== -bits2NumA.out * (1 - sign.out);
    out <== switcher.out[0];

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

template MatrixPReLUwithCutPrecision(n, m, precNew, precOld) {
    assert (precNew < precOld);

    signal input in[n][m];
    signal output out[n][m];

    component relu[n][m];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j < m; j++) {
            relu[i][j] = parallel PReLUwithCutPrecision(precNew, precOld);
            relu[i][j].in <== in[i][j];
            out[i][j] <== relu[i][j].out;
        }
    }
}