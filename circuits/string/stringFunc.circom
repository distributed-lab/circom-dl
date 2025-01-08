pragma circom 2.1.6;

function log_str(x, LEN){
    for (var i = 0; i < LEN; i++){
        log(x[i]);
    }
    return 0;
}