pragma circom  2.1.6;

include "../../../circuits/signatures/rsaPss.circom";


component main = VerifyRsaPssSig(64, 48, 32, 65537, 256);
