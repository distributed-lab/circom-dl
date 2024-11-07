pragma circom 2.1.6;

include "../bitify/comparators.circom";
include "../bitify/bitify.circom";

template Inverse(){
    signal input in;
    signal output out;
    out <-- 1 / in;
    out * in === 1;
}

//use if u don`t know what is len of bit representation of in[0] is
template DivisionStrict(){
    signal input in[2];
    
    signal output mod;
    signal output div;
    
    mod <-- in[0] % in[1];
    div <-- in[0] \ in[1];
    
    div * in[1] + mod === in[0];
    component check1 = LessEqThan(252);
    component check2 = GreaterThan(252);
    
    check1.in[0] <== div * in[1];
    check1.in[1] <== in[0];
    check1.out === 1;
    
    check2.in[0] <== (div + 1) * in[1];
    check2.in[1] <== in[0];
    check2.out === 1;
    
}

//use this if u know what len of bit representation of in[1] is
template Division(LEN){
    
    assert (LEN < 253);
    signal input in[2];
    
    signal output div;
    signal output mod;
    
    mod <-- in[0] % in[1];
    div <-- in[0] \ in[1];
    
    div * in[1] + mod === in[0];
    component check1 = LessEqThan(LEN);
    component check2 = GreaterThan(LEN);
    
    check1.in[0] <== div * in[1];
    check1.in[1] <== in[0];
    check1.out === 1;
    
    check2.in[0] <== (div + 1) * in[1];
    check2.in[1] <== in[0];
    check2.out === 1;
    
}

//don`t use it for 0!!!
template Log2CeilStrict(){
    signal input in;
    signal output out;
    
    signal bits[252];
    component n2b = Num2Bits(252);
    n2b.in <== in - 1;
    n2b.out ==> bits;
    
    signal counter[252];
    signal sum[252];
    
    counter[0] <== bits[251];
    sum[0] <== counter[0];
    
    for (var i = 1; i < 252; i++){
        counter[i] <== (1 - counter[i - 1]) * bits[251 - i] + counter[i - 1];
        sum[i] <== sum[i - 1] + counter[i];
    }
    
    out <== sum[251];
}

template Log2Ceil(RANGE){
    signal input in;
    signal output out;
    
    signal bits[RANGE];
    component n2b = Num2Bits(RANGE);
    n2b.in <== in - 1;
    n2b.out ==> bits;
    
    signal counter[RANGE];
    signal sum[RANGE];
    
    counter[0] <== bits[RANGE - 1];
    sum[0] <== counter[0];
    
    for (var i = 1; i < RANGE; i++){
        counter[i] <== (1 - counter[i - 1]) * bits[RANGE - 1 - i] + counter[i - 1];
        sum[i] <== sum[i - 1] + counter[i];
    }
    
    out <== sum[RANGE - 1];
}
