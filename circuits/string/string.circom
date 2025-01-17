pragma circom 2.1.6;

include "./stringFunc.circom";

// What is str explained here
// String is array of chars, where each char is UTF-8 encoded (so we have 256 different chars)

template StrConcate(LEN_1, LEN_2){
    signal input in1[LEN_1];
    signal input in2[LEN_2];
    
    signal output out[LEN_1 + LEN_2];
    
    for (var i = 0; i < LEN_1; i++){
        out[i] <== in1[i];
    }
    for (var i = LEN_1; i < LEN_1 + LEN_2; i++){
        out[i] <== in2[i - LEN_1];
    }
    var print = log_str(out, LEN_1 + LEN_2);
}
