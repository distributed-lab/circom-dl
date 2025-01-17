pragma circom 2.1.6;

include "../../../circuits/zkml/activationFunc.circom";

component main = ReLUwithCutPrecision(10, 50);