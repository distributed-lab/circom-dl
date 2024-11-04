// pragma circom  2.1.6;


// template Num2Bits(LEN){
    
//     assert(LEN < 253);
    
//     signal input in;
//     signal output out[LEN];

//     signal sum[LEN +1];
//     sum[0] <== 1;
    
//     for (var i = 0; i < LEN; i++) {
//         out[i] <-- (in >> i) & 1;
//         // out[i] * (out[i] - 1) === 0;
//         sum[i+1] <== sum[i] + in;
//     }

// }

// template Bits2Num(LEN){
    
//     assert(LEN <= 253);
    
//     signal input in[LEN];
//     signal output out;
    
    
// }