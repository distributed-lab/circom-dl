pragma circom 2.1.6;

include "../../../circuits/zkml/zkFriendlyLayers.circom";

component main = SqueezeAndExcitation(4, 4, 3, 2, 10, 50);
