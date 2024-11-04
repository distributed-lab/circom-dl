pragma circom  2.1.6;


template Num2Bits(LEN){
    
    assert(LEN < 253);
    
    signal input in;
    signal output out[LEN];

    signal sum[LEN + 1];
    sum[0] <== 0;
    
    for (var i = 0; i < LEN; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] - 1) === 0;
        sum[i+1] <== sum[i] + (2 ** i) * out[i];
    }

}

template Bits2Num(LEN){
    
    assert(LEN <= 253);
    
    signal input in[LEN];
    signal output out;
    
    signal sum[LEN];

    sum[0] <== in[0];

    for (var i = 1; i < LEN; i++){
        sum[i] <== sum[i - 1] + in[i] * (2 ** i);
    }

    out <== sum[LEN - 1];
}