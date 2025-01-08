pragma circom 2.1.6;

include "../matrix/matrix.circom";
include "../int/arithmetic.circom";

template MatrixSum(n1, m1, n) {
    signal input matrices[n][n1][m1];
    signal input dummy;

    signal output out[n1][m1];

    component sums[n1][m1];
    for (var i = 0; i < n1; i++) {
        for (var j = 0; j < m1; j++) {
            sums[i][j] = GetSumOfNElements(n);
            for (var k = 0; k < n; k++) {
                sums[i][j].in[k] <== matrices[k][i][j];
            }
            sums[i][j].dummy <== dummy;
            sums[i][j].out ==> out[i][j]; 
        }
    }
    
}

// computes convolution with step 1 
// in is matrix n1xm1
// filter is matrix n2xm2
// step is shift between filters
// out is matrix n1 - n2 + 1, m1 - m2 + 1
// For example, step 1:
// 
//     [ [1, 2, 3]
// in:   [4, 5, 6]    filter: [ [10, 11]
//       [7, 8, 9] ]            [12, 13] ]
//
// result is:
// [ [x1, x2]
//   [x3, x4] ], 
// where 
// x1 = in[0][0] * filter[0][0] + in[1][0] * filter[1][0] + in[0][1] * filter[0][1] + in[1][1] * filter[1][1] 
// x2 = in[1][0] * filter[0][0] + in[2][0] * filter[1][0] + in[1][1] * filter[0][1] + in[2][1] * filter[1][1] 
// x3 = in[0][1] * filter[0][0] + in[1][1] * filter[1][0] + in[0][2] * filter[0][1] + in[1][2] * filter[1][1] 
// x4 = in[1][1] * filter[0][0] + in[2][1] * filter[1][0] + in[1][2] * filter[0][1] + in[2][2] * filter[1][1] 
// Will fail assert if (n1 - n2) % step != 0
// If u have this case, reduce (or increase) input table in size;
template Conv(n1, m1, n2, m2, step){
    assert(n1 >= n2 && (n1 - n2) % step == 0 && m1 >= m2 && (m1 - m2) % step == 0);

    signal input in[n1][m1];
    signal input filter[n2][m2];
    signal input dummy;
    
    var OUT_N = (n1 - n2) \ step + 1;
    var OUT_M = (m1 - m2) \ step + 1;
    
    dummy * dummy === 0;
    signal output out[OUT_N][OUT_M];
    
    component sum[OUT_N][OUT_M];
    
    for (var i = 0; i < OUT_N; i++){
        for (var j = 0; j < OUT_M; j++){
            sum[i][j] = GetSumOfNElements(n2 * m2);
            sum[i][j].dummy <== dummy;
            for (var idx_x = 0; idx_x < n2; idx_x++){
                for (var idx_y = 0; idx_y < m2; idx_y++){
                    sum[i][j].in[idx_x * m2 + idx_y] <== filter[idx_x][idx_y] * in[idx_x + i * step][idx_y + j * step];
                }
            }
            out[i][j] <== sum[i][j].out;
        }
    }
    
    // var print = log_matrix(out, OUT_N, OUT_M);
}

template ConvNChannels1Filter(n1, m1, n2, m2, n, step) {
    assert(n1 >= n2 && (n1 - n2) % step == 0 && m1 >= m2 && (m1 - m2) % step == 0);
    signal input in[n][n1][m1];
    signal input filter[n2][m2];
    signal input dummy;

    var OUT_N = (n1 - n2) \ step + 1;
    var OUT_M = (m1 - m2) \ step + 1;

    component conv[n];
    for (var i = 0; i < n; i++) {
        conv[i] = Conv(n1, m1, n2, m2, step);
        conv[i].in <== in[i];
        conv[i].filter <== filter;
        conv[i].dummy <== dummy;
    }
    
    signal output out[OUT_N][OUT_M];

    component matrixsum = MatrixSum(OUT_N, OUT_M, n);
    for (var i = 0; i < n; i++) {
        matrixsum.matrices[i] <== conv[i].out;
    }
    matrixsum.dummy <== dummy;


    out <== matrixsum.out;

    //var print = log_matrix(out, OUT_N, OUT_M);
}

template ConvNChannelsBias1Filter(n1, m1, n2, m2, n, step) {
    assert(n1 >= n2 && (n1 - n2) % step == 0 && m1 >= m2 && (m1 - m2) % step == 0);
    signal input in[n][n1][m1];
    signal input filter[n2][m2];
    signal input dummy;

    var OUT_N = (n1 - n2) \ step + 1;
    var OUT_M = (m1 - m2) \ step + 1;

    signal input bias[OUT_N][OUT_M];

    component conv[n];
    for (var i = 0; i < n; i++) {
        conv[i] = Conv(n1, m1, n2, m2, step);
        conv[i].in <== in[i];
        conv[i].filter <== filter;
        conv[i].dummy <== dummy;
    }
    
    signal output out[OUT_N][OUT_M];

    component matrixsum = MatrixSum(OUT_N, OUT_M, n+1);
    for (var i = 0; i < n; i++) {
        matrixsum.matrices[i] <== conv[i].out;
    }
    
    matrixsum.matrices[n] <== bias;

    matrixsum.dummy <== dummy;


    out <== matrixsum.out;

    //var print = log_matrix(out, OUT_N, OUT_M);
}

template ConvNChannelsConstantBias1Filter(n1, m1, n2, m2, n, step) {
    assert(n1 >= n2 && (n1 - n2) % step == 0 && m1 >= m2 && (m1 - m2) % step == 0);
    signal input in[n][n1][m1];
    signal input filter[n2][m2];
    signal input dummy;

    var OUT_N = (n1 - n2) \ step + 1;
    var OUT_M = (m1 - m2) \ step + 1;

    signal input bias;

    component conv[n];
    for (var i = 0; i < n; i++) {
        conv[i] = Conv(n1, m1, n2, m2, step);
        conv[i].in <== in[i];
        conv[i].filter <== filter;
        conv[i].dummy <== dummy;
    }
    
    signal output out[OUT_N][OUT_M];

    component matrixsum = MatrixSum(OUT_N, OUT_M, n+1);
    for (var i = 0; i < n; i++) {
        matrixsum.matrices[i] <== conv[i].out;
    }
    for (var i = 0; i < OUT_N; i++) {
        for (var j = 0; j < OUT_M; j++) {
            matrixsum.matrices[n][i][j] <== bias;
        }
    }

    matrixsum.dummy <== dummy;


    out <== matrixsum.out;

    //var print = log_matrix(out, OUT_N, OUT_M);
}

template ConvNChannelsNFilter(n1, m1, n2, m2, n, step) {
    assert(n1 >= n2 && (n1 - n2) % step == 0 && m1 >= m2 && (m1 - m2) % step == 0);
    signal input in[n][n1][m1];
    signal input filter[n][n2][m2];
    signal input dummy;

    var OUT_N = (n1 - n2) \ step + 1;
    var OUT_M = (m1 - m2) \ step + 1;

    component conv[n];
    for (var i = 0; i < n; i++) {
        conv[i] = Conv(n1, m1, n2, m2, step);
        conv[i].in <== in[i];
        conv[i].filter <== filter[i];
        conv[i].dummy <== dummy;
    }
    
    signal output out[OUT_N][OUT_M];

    component matrixsum = MatrixSum(OUT_N, OUT_M, n);
    for (var i = 0; i < n; i++) {
        matrixsum.matrices[i] <== conv[i].out;
    }
    matrixsum.dummy <== dummy;


    out <== matrixsum.out;

    var print = log_matrix(out, OUT_N, OUT_M);
}

template ConvNChannelsBiasNFilter(n1, m1, n2, m2, n, step) {
    assert(n1 >= n2 && (n1 - n2) % step == 0 && m1 >= m2 && (m1 - m2) % step == 0);
    signal input in[n][n1][m1];
    signal input filter[n][n2][m2];
    signal input dummy;

    var OUT_N = (n1 - n2) \ step + 1;
    var OUT_M = (m1 - m2) \ step + 1;

    signal input bias[OUT_N][OUT_M];

    component conv[n];
    for (var i = 0; i < n; i++) {
        conv[i] = Conv(n1, m1, n2, m2, step);
        conv[i].in <== in[i];
        conv[i].filter <== filter[i];
        conv[i].dummy <== dummy;
    }
    
    signal output out[OUT_N][OUT_M];

    component matrixsum = MatrixSum(OUT_N, OUT_M, n+1);
    for (var i = 0; i < n; i++) {
        matrixsum.matrices[i] <== conv[i].out;
    }
    
    matrixsum.matrices[n] <== bias;

    matrixsum.dummy <== dummy;


    out <== matrixsum.out;

    //var print = log_matrix(out, OUT_N, OUT_M);
}

template ConvNChannelsConstantBiasNFilter(n1, m1, n2, m2, n, step) {
    assert(n1 >= n2 && (n1 - n2) % step == 0 && m1 >= m2 && (m1 - m2) % step == 0);
    signal input in[n][n1][m1];
    signal input filter[n][n2][m2];
    signal input dummy;

    var OUT_N = (n1 - n2) \ step + 1;
    var OUT_M = (m1 - m2) \ step + 1;

    signal input bias;

    component conv[n];
    for (var i = 0; i < n; i++) {
        conv[i] = Conv(n1, m1, n2, m2, step);
        conv[i].in <== in[i];
        conv[i].filter <== filter[i];
        conv[i].dummy <== dummy;
    }
    
    signal output out[OUT_N][OUT_M];

    component matrixsum = MatrixSum(OUT_N, OUT_M, n+1);
    for (var i = 0; i < n; i++) {
        matrixsum.matrices[i] <== conv[i].out;
    }
    for (var i = 0; i < OUT_N; i++) {
        for (var j = 0; j < OUT_M; j++) {
            matrixsum.matrices[n][i][j] <== bias;
        }
    }

    matrixsum.dummy <== dummy;


    out <== matrixsum.out;

    //var print = log_matrix(out, OUT_N, OUT_M);
}