pragma circom 2.1.6;

function process_padding(LEN, LEN_PADDED){
    
    var tmp_len = LEN;
    var bit_len[128];
    var len_bit_len = 0;
    var is_zero = 0;
    for (var i = 0; i < 128; i++){
        bit_len[i] = tmp_len % 2;
        tmp_len = tmp_len \ 2;
        if (tmp_len == 0 && is_zero == 0){
            len_bit_len = i + 1;
            is_zero = 1;
            
        }
    }
    var padding[1536]; 
   
    padding[0] = 1;
    for (var i = 1; i < LEN_PADDED - LEN - len_bit_len; i++){
        padding[i] = 0;
    }
    for (var i = LEN_PADDED - LEN - 1; i >= LEN_PADDED - LEN - len_bit_len; i--){
        padding[i] = bit_len[LEN_PADDED - LEN - 1 - i];
    }

    return padding;
}

// Universal sha-1 and sha-2 padding.
// HASH_BLOCK_SIZE is 512 for sha-1, sha2-224, sha2-256
// HASH_BLOCK_SIZE is 1024 for sha2-384, sha2-512
// LEN is bit len of message
template ShaPadding(LEN, HASH_BLOCK_SIZE){

    var CHUNK_NUMBER = ((LEN + 1 + 128) + HASH_BLOCK_SIZE - 1) \ HASH_BLOCK_SIZE;

    signal input in[LEN];
    signal output out[CHUNK_NUMBER * HASH_BLOCK_SIZE];

    for (var i = 0; i < LEN; i++){
        out[i] <== in[i];
    }

    var padding[1536] = process_padding(LEN, CHUNK_NUMBER * HASH_BLOCK_SIZE);
    for (var i = LEN; i < CHUNK_NUMBER * HASH_BLOCK_SIZE; i++){
        out[i] <== padding[i - LEN];
    }
}