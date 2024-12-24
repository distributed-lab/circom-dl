pragma circom 2.1.6;

include "../matrix/matrix.circom";
include "./activationFunc.circom";
include "./tools.circom";

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

template AveragePooling(k, n, m) {
    signal input in[k][n][m];
    signal output out[k][n \ 2][m \ 2];

    signal inv4 <== getInverseFloat(4);
    for (var r = 0; r < k; r++) {
        for (var i = 0; i < n\2; i++) {
            for (var j = 0; j < m\2; j++) {
                out[r][i][j] <== inv4 * (in[r][2*i][2*j] + in[r][2*i+1][2*j] + in[r][2*i][2*j+1] + in[r][2*i+1][2*j+1]);
            }
        }
    }
}

template SqueezeAndExcitation(w, h, c, gammaC, precNew, precOld) {
    signal input in[c][w][h];
    signal input W1[gammaC][c];
    signal input W2[c][gammaC];
    signal input b1[gammaC][1];
    signal input b2[c][1];

    signal output out[c][w][h];

    signal invWH <== getInverseFloat(w*h);

    component z[c];

    for (var r = 0; r < c; r++) {
        z[r] = parallel GetSumOfNElements(w*h);
        z[r].dummy <== 0;
        for (var i = 0; i < w; i++) {
            for (var j = 0; j < h; j++) {
                //log(in[r][i][j]);
                z[r].in[i * h + j] <== invWH * in[r][i][j];
            }
        }
    }
    // log("z");
    // log(z[0].out);
    // log(z[1].out);
    // log(z[2].out);

    component W1z = MatrixMultiply(gammaC, c, c, 1);
    W1z.in1 <== W1;
    for (var i = 0; i < c; i++) {
        W1z.in2[i][0] <== z[i].out;
    }
    W1z.dummy <== 0;
    //log("W1z");
    //var print1 = log_matrix(W1z.out, gammaC, 1);

    component W1zb1 = MatrixAddition(gammaC, 1);
    W1zb1.in1 <== W1z.out;
    W1zb1.in2 <== b1;
    W1zb1.dummy <== 0;
    //log("W1zb1");
    //var print2 = log_matrix(W1zb1.out, gammaC, 1);

    component relu = MatrixReLUwithCutPrecision(gammaC, 1, precNew, precOld);
    relu.in <== W1zb1.out;
    //log("relu");
    //var print3 = log_matrix(relu.out, gammaC, 1);

    component W2relu = MatrixMultiply(c, gammaC, gammaC, 1);
    W2relu.in1 <== W2;
    W2relu.in2 <== relu.out;
    W2relu.dummy <== 0;
    //log("W2relu");
    //var print4 = log_matrix(W2relu.out, c, 1);

    component s = MatrixAddition(c, 1);
    s.in1 <== W2relu.out;
    s.in2 <== b2;
    s.dummy <== 0;
    //log("s");
    //var print5 = log_matrix(s.out, c, 1);

    for (var r = 0; r < c; r++) {
        for (var i = 0; i < w; i++) {
            for (var j = 0; j < h; j++) {
                out[r][i][j] <== in[r][i][j] * s.out[r][0];
            }
        }
    }
}

template EncDecLightConv(l, c, f, sqrtGammaF, n, c2, precNew, precOld) {
    signal input in[c][l][l];
    signal input W1[l \ f][l \ f][n][f * f * c];
    signal input W2[l \ f][l \ f][sqrtGammaF * sqrtGammaF * c2][n];
    signal input b1[l \ f][l \ f][n][1];
    signal input b2[l \ f][l \ f][sqrtGammaF * sqrtGammaF * c2][1];

    signal output out[c2][sqrtGammaF * (l \ f)][sqrtGammaF * (l \ f)];

    component mlp1[l \ f][l \ f];
    component add1[l \ f][l \ f];
    component relu[l \ f][l \ f];
    component mlp2[l \ f][l \ f];
    component add2[l \ f][l \ f];

    for (var r1 = 0; r1 < (l \ f); r1++) {
        for (var r2 = 0; r2 < (l \ f); r2++) { 
            mlp1[r1][r2] = MatrixMultiply(n, f * f * c, f * f * c, 1);
            mlp1[r1][r2].dummy <== 0;
            mlp1[r1][r2].in1 <== W1[r1][r2];
            for (var i = 0; i < c; i++) {
                for (var j = 0; j < f; j++) {
                    for (var k = 0; k < f; k++) {
                        mlp1[r1][r2].in2[k + j * f + i * f * f][0] <== in[i][k][j];
                    }
                }
            }

            add1[r1][r2] = MatrixAddition(n, 1);
            add1[r1][r2].in1 <== mlp1[r1][r2].out;
            add1[r1][r2].in2 <== b1[r1][r2];
            add1[r1][r2].dummy <== 0;
            
            relu[r1][r2] = MatrixReLUwithCutPrecision(n, 1, precNew, precOld);
            relu[r1][r2].in <== add1[r1][r2].out;

            mlp2[r1][r2] = MatrixMultiply(sqrtGammaF * sqrtGammaF * c2, n, n, 1);
            mlp2[r1][r2].in1 <== W2[r1][r2];
            mlp2[r1][r2].in2 <== relu[r1][r2].out;
            mlp2[r1][r2].dummy <== 0;

            add2[r1][r2] = MatrixAddition(sqrtGammaF * sqrtGammaF * c2, 1);
            add2[r1][r2].in1 <== mlp2[r1][r2].out;
            add2[r1][r2].in2 <== b2[r1][r2];
            add2[r1][r2].dummy <== 0;

            for (var i = 0; i < c2; i++) {
                for (var j = 0; j < sqrtGammaF; j++) {
                    for (var k = 0; k < sqrtGammaF; k++) {
                        out[i][j + r1 * sqrtGammaF][k + r2 * sqrtGammaF] <== add2[r1][r2].out[i * sqrtGammaF * sqrtGammaF + j * sqrtGammaF + k][0];
                    }
                }
            }
        }
    }
}