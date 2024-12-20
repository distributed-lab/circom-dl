pragma circom 2.1.6;

include "../matrix/matrixFunc.circom";

// k layers, each presented as matrix n*m
template SumPool(k, n, m) {
    signal input in[k][n][m];
    signal output out[k][n \ 2][m \ 2];

    for (var r = 0; r < k; r++) {
        for (var i = 0; i < n\2; i++) {
            for (var j = 0; j < m\2; j++) {
                out[r][i][j] <== in[r][2*i][2*j] + in[r][2*i+1][2*j] + in[r][2*i][2*j+1] + in[r][2*i+1][2*j+1];
            }
        }
    }
    //for (var r = 0; r < k; r++) {
    //    var print = log_matrix(out[r], n\2, m\2);
    //}
}