pragma circom 2.1.6;

include "../int/arithmetic.circom";

template MatrixL2Dist(n1, m1) {
    signal input in1[n1][m1];
    signal input in2[n1][m1];

    signal output out;
    component sum = GetSumOfNElements(n1*m1);

    for (var i = 0; i < n1; i++) {
        for (var j = 0; j < m1; j++) {
            sum.in[i*m1 + j] <== (in1[i][j] - in2[i][j]) * (in1[i][j] - in2[i][j]);
        }
    }
    out <== sum.out;
}