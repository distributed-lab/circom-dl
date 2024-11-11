// template BigMultOptimised4(CHUNK_SIZE, CHUNK_NUMBER){
    
//     signal input dummy;
//     signal input in[2][CHUNK_NUMBER];
//     signal output out[CHUNK_NUMBER * 4];
    
//     component bigMultNoCarry = BigMultNoCarry(CHUNK_SIZE, CHUNK_NUMBER);
//     bigMultNoCarry.in <== in;
//     bigMultNoCarry.dummy <== dummy;

//     component bigMultNoCarry2 = BigMultNoCarry(CHUNK_SIZE, CHUNK_NUMBER * 2 - 1);
//         bigMultNoCarry2.in[0] <== bigMultNoCarry.out;
//         bigMultNoCarry2.in[1] <== bigMultNoCarry.out;
//     bigMultNoCarry2.dummy <== dummy;

//     component getLastNBits[CHUNK_NUMBER * 4 - 1];
//     component bits2Num[CHUNK_NUMBER * 4 - 1];
    
//     for (var i = 0; i < CHUNK_NUMBER * 4 - 3; i++){
//         getLastNBits[i] = GetLastNBits(CHUNK_SIZE);
//         bits2Num[i] = Bits2Num(CHUNK_SIZE);
        
//         if (i == 0) {
//             getLastNBits[i].in <== bigMultNoCarry2.out[i];
//         } else {
//             getLastNBits[i].in <== bigMultNoCarry2.out[i] + getLastNBits[i - 1].div;
//         }
//         bits2Num[i].in <== getLastNBits[i].out;
//     }
    
//     for (var i = 0; i < CHUNK_NUMBER * 4 - 3; i++){
//         out[i] <== bits2Num[i].out;
//     }
//     getLastNBits[CHUNK_NUMBER * 4 - 3] = GetLastNBits(CHUNK_SIZE);
//     getLastNBits[CHUNK_NUMBER * 4 - 3].in <== getLastNBits[CHUNK_NUMBER * 4 - 4].div;

//     bits2Num[CHUNK_NUMBER * 4 - 3] = Bits2Num(CHUNK_SIZE);
//     bits2Num[CHUNK_NUMBER * 4 - 3].in <== getLastNBits[CHUNK_NUMBER * 4 - 3].out;
    
//     out[CHUNK_NUMBER * 4 - 3] <== bits2Num[CHUNK_NUMBER * 4 - 3].out;

//     getLastNBits[CHUNK_NUMBER * 4 - 2] = GetLastNBits(CHUNK_SIZE);
//     getLastNBits[CHUNK_NUMBER * 4 - 2].in <== getLastNBits[CHUNK_NUMBER * 4 - 3].div;

//     bits2Num[CHUNK_NUMBER * 4 - 2] = Bits2Num(CHUNK_SIZE);
//     bits2Num[CHUNK_NUMBER * 4 - 2].in <== getLastNBits[CHUNK_NUMBER * 4 - 2].out;

//     out[CHUNK_NUMBER * 4 - 2] <== bits2Num[CHUNK_NUMBER * 4 - 2].out;
//     out[CHUNK_NUMBER * 4 - 1] <== getLastNBits[CHUNK_NUMBER * 4 - 2].div;
// }


// template BigAdd(CHUNK_SIZE, CHUNK_NUMBER){
    
//     signal input in[2][CHUNK_NUMBER];
//     signal output out[CHUNK_NUMBER + 1];
//     signal input dummy;
    
//     component bigAddNoCarry = BigAddNoCarry(CHUNK_SIZE, CHUNK_NUMBER);
//     bigAddNoCarry.in <== in;
//     bigAddNoCarry.dummy <== dummy;
    
//     component greaterThan[CHUNK_NUMBER];
    
//     for (var i = 0; i < CHUNK_NUMBER; i++){
//         greaterThan[i] = GreaterEqThan(CHUNK_SIZE + 1);
        
//         //if >= 2**CHUNK_SIZE, overflow
//         if (i == 0){
//             greaterThan[i].in[0] <== bigAddNoCarry.out[i];
//             greaterThan[i].in[1] <== 2 ** CHUNK_SIZE;
//         } else {
//             greaterThan[i].in[0] <== bigAddNoCarry.out[i] + greaterThan[i - 1].out;
//             greaterThan[i].in[1] <== 2 ** CHUNK_SIZE;
//         }
//     }
    
//     for (var i = 0; i < CHUNK_NUMBER; i++){
//         if (i == 0){
//             out[i] <== bigAddNoCarry.out[i] - (greaterThan[i].out) * (2 ** CHUNK_SIZE);
//         }
//         else {
//             out[i] <== bigAddNoCarry.out[i] - (greaterThan[i].out) * (2 ** CHUNK_SIZE) + greaterThan[i - 1].out;
//         }
//     }
//     out[CHUNK_NUMBER] <== greaterThan[CHUNK_NUMBER - 1].out;
// }