pragma circom 2.1.6;

include "../../../circuits/zkml/convolution.circom";

component main = ConvNChannelsConstantBiasNFilter(5, 5, 3, 3, 3, 1);