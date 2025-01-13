pragma circom 2.1.6;

// Reference implementation: github.com/Roman-Oliynykov/Kupyna-reference.git
template Kupyna256Bits(LEN) {
    var STATE_BYTE_SIZE_512 = 64;
    var NR_512 = 10;   // Number of rounds for 512-bit state
    var NB_512 = 8;    // Number of 8-byte words in state for <=256-bit hash code.

    signal input in[LEN];
    signal output out[256];

    signal state[8][NB_512];

    // Reference implementation: line 245
    state[0][0] <== STATE_BYTE_SIZE_512;

    
}