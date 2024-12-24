pragma circom 2.1.6;

include "../../../circuits/zkml/zkFriendlyLayers.circom";

template SetParams(l, c, f, sqrtGammaF, n, c2, precNew, precOld) {
    signal W1[l \ f][l \ f][n][f * f * c];
    signal W2[l \ f][l \ f][sqrtGammaF * sqrtGammaF * c2][n];
    signal b1[l \ f][l \ f][n][1];
    signal b2[l \ f][l \ f][sqrtGammaF * sqrtGammaF * c2][1];

    for (var i = 0; i < l \ f; i++) {
        for (var j = 0; j < l \ f; j++) {
            for (var k = 0; k < n; k++) {
                for (var r = 0; r < f * f * c; r++) {
                    W1[i][j][k][r] <== 1;
                }   
            }
        }
    }

    for (var i = 0; i < l \ f; i++) {
        for (var j = 0; j < l \ f; j++) {
            for (var k = 0; k < sqrtGammaF * sqrtGammaF * c2; k++) {
                for (var r = 0; r < n; r++) {
                    W2[i][j][k][r] <== 1;
                }   
            }
        }
    }

    for (var i = 0; i < l \ f; i++) {
        for (var j = 0; j < l \ f; j++) {
            for (var k = 0; k < n; k++) {
                for (var r = 0; r < 1; r++) {
                    b1[i][j][k][r] <== 1;
                }   
            }
        }
    }

    for (var i = 0; i < l \ f; i++) {
        for (var j = 0; j < l \ f; j++) {
            for (var k = 0; k < sqrtGammaF * sqrtGammaF * c2; k++) {
                for (var r = 0; r < 1; r++) {
                    b2[i][j][k][r] <== 1;
                }   
            }
        }
    }
    signal input in[c][l][l];

    component enc = EncDecLightConv(192, 1, 24, 8, 5, 8, 10, 50);
    enc.in <== in;
    enc.W1 <== W1;
    enc.W2 <== W2;
    enc.b1 <== b1;
    enc.b2 <== b2;
}

component main = SetParams(192, 1, 24, 8, 5, 8, 10, 50);