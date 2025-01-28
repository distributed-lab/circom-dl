pragma circom  2.1.6;

include "../../../circuits/signatures/ecrecover.circom";

component main = EcRecover(64, 4, [0,0,0,0], [7,0,0,0], [18446744069414583343, 18446744073709551615, 18446744073709551615, 18446744073709551615]);