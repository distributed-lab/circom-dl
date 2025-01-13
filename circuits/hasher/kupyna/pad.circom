pragma circom 2.1.6;

// Reference implementation: github.com/Roman-Oliynykov/Kupyna-reference.git
template Pad(nbytes, msg_nbits) {
    signal input data[msg_nbytes];
    signal output padding[pad_nbytes];

    var msg_nbytes = msg_nbits / 8;
    var nblocks = msg_nbytes / nbytes;
    var pad_nbytes = msg_nbytes - (nblocks * nbytes);
    var data_nbytes = msg_nbytes - pad_nbytes;
    var extra_bits = msg_nbits % 8;
    var zero_nbytes;
    var mask;
    var pad_bit;

    // Copy data to padding
    for (var i = 0; i < pad_nbytes; i++) {
        padding[i] <== data[data_nbytes + i];
    }

    // Handle extra bits
    if (extra_bits != 0) {
        mask = ~(0xFF >> extra_bits);
        pad_bit = 1 << (7 - extra_bits);
        padding[pad_nbytes - 1] <== (padding[pad_nbytes - 1] & mask) | pad_bit;
    } else {
        padding[pad_nbytes] <== 0x80;
        pad_nbytes += 1;
    }

    // Calculate zero_nbytes
    zero_nbytes = ((-msg_nbits - 97) % (nbytes * 8)) / 8;

    // Set zero bytes
    for (var i = 0; i < zero_nbytes; i++) {
        padding[pad_nbytes + i] <== 0;
    }
    pad_nbytes += zero_nbytes;

    // Append message length
    for (var i = 0; i < 12; i++) { // 96 bits / 8 = 12 bytes
        if (i < sizeof(size_t)) {
            padding[pad_nbytes + i] <== (msg_nbits >> (i * 8)) & 0xFF;
        } else {
            padding[pad_nbytes + i] <== 0;
        }
    }
}