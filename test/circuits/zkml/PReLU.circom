pragma circom 2.1.6;

include "../../../circuits/zkml/activationFunc.circom";

component main = MatrixPReLUwithCutPrecision(4, 4, 0, 10);