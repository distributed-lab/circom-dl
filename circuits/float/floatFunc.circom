pragma circom 2.1.6;

function log_float(float, n){
    
    var div = float \ 2**n;
    var mod = float % 2**n;
    mod = mod * 10**n \ 2**n;
    var leading_zeros = 0;
    var counter = n - 1;
    while (mod < 10 ** counter){
        leading_zeros++;
        counter--;
    }
    if (leading_zeros == 0){
        log(div, ".", mod);
    }
    if (leading_zeros == 1){
        log(div, ".0", mod);
    }
    if (leading_zeros == 2){
        log(div, ".00", mod);
    }
    if (leading_zeros == 3){
        log(div, ".000", mod);
    }
    if (leading_zeros == 4){
        log(div, ".0000", mod);
    }
    if (leading_zeros == 5){
        log(div, ".00000", mod);
    }
    if (leading_zeros == 6){
        log(div, ".000000", mod);
    }
    if (leading_zeros == 7){
        log(div, ".0000000", mod);
    }
    if (leading_zeros == 8){
        log(div, ".00000000", mod);
    }
    if (leading_zeros == 9){
        log(div, ".000000000", mod);
    }
    if (leading_zeros == 10){
        log(div, ".0000000000", mod);
    }
    if (leading_zeros == 11){
        log(div, ".00000000000", mod);
    }
    if (leading_zeros == 12){
        log(div, ".000000000000", mod);
    }
    if (leading_zeros == 13){
        log(div, ".0000000000000", mod);
    }
    if (leading_zeros == 14){
        log(div, ".00000000000000", mod);
    }
    if (leading_zeros == 15){
        log(div, ".000000000000000", mod);
    }
    if (leading_zeros == 16){
        log(div, ".0000000000000000", mod);
    }
    if (leading_zeros == 17){
        log(div, ".00000000000000000", mod);
    }
    if (leading_zeros == 18){
        log(div, ".000000000000000000", mod);
    }
    if (leading_zeros == 19){
        log(div, ".0000000000000000000", mod);
    }
    if (leading_zeros == 20){
        log(div, ".00000000000000000000", mod);
    }
    if (leading_zeros == 21){
        log(div, ".000000000000000000000", mod);
    }
    if (leading_zeros == 22){
        log(div, ".0000000000000000000000", mod);
    }
    if (leading_zeros == 23){
        log(div, ".00000000000000000000000", mod);
    }
    if (leading_zeros == 24){
        log(div, ".000000000000000000000000", mod);
    }
    if (leading_zeros == 25){
        log(div, ".0000000000000000000000000", mod);
    }
    if (leading_zeros == 26){
        log(div, ".00000000000000000000000000", mod);
    }
    if (leading_zeros == 27){
        log(div, ".000000000000000000000000000", mod);
    }
    if (leading_zeros == 28){
        log(div, ".0000000000000000000000000000", mod);
    }
    if (leading_zeros == 29){
        log(div, ".00000000000000000000000000000", mod);
    }
    if (leading_zeros == 30){
        log(div, ".000000000000000000000000000000", mod);
    }
    if (leading_zeros == 31){
        log(div, ".0000000000000000000000000000000", mod);
    }
    if (leading_zeros == 32){
        log(div, ".00000000000000000000000000000000", mod);
    }
    if (leading_zeros == 33){
        log(div, ".000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 34){
        log(div, ".0000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 35){
        log(div, ".00000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 36){
        log(div, ".000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 37){
        log(div, ".0000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 38){
        log(div, ".00000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 39){
        log(div, ".000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 40){
        log(div, ".0000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 41){
        log(div, ".00000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 42){
        log(div, ".000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 43){
        log(div, ".0000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 44){
        log(div, ".00000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 45){
        log(div, ".000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 46){
        log(div, ".0000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 47){
        log(div, ".00000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 48){
        log(div, ".000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 49){
        log(div, ".0000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 50){
        log(div, ".00000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 51){
        log(div, ".000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 52){
        log(div, ".0000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 53){
        log(div, ".00000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 54){
        log(div, ".000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 55){
        log(div, ".0000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 56){
        log(div, ".00000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 57){
        log(div, ".000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 58){
        log(div, ".0000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 59){
        log(div, ".00000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 60){
        log(div, ".000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 61){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 62){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 63){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 64){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 65){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 66){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 67){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 68){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 69){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 70){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 71){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 72){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 73){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 74){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 75){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 76){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 77){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 78){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 79){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 80){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 81){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 82){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 83){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 84){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 85){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 86){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 87){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 88){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 89){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 90){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 91){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 92){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 93){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 94){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 95){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 96){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 97){
        log(div, ".0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 98){
        log(div, ".00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }
    if (leading_zeros == 99){
        log(div, ".000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", mod);
    }

    return 0;
}

function factorial(n){
    var result = 1;
    for (var i = 2; i <= n; i++){
        result *= i;
    }
    return result;
}

function fraction_convertor(a, b, n){
    // log((a * 2**n) \ b, (a * 2**n) % b);
    return (a * 2**n) \ b;
}

function precompute_exp_constants(k, n){
    var res[100];
    res[0] = 2**n;
    for (var i = 1; i < k; i++){
        res[i] = fraction_convertor(1, factorial(i), n);
    }
    

    return res;
}

function abs_in_bits(value) {
    var out[253];
    var x;
    if (0 - value > value) {
        value = -value;
    }
    for (var i = 0; i < 253; i++) {
        out[i] = (value >> i) & 1;
    }
    return out;
}