pragma circom 2.0.0;

//------------------------------------------------------------------------------
// decompose a 2-bit number into a high and a low bit

template Bits2() {
    signal input  xy;
    signal output lo;
    signal output hi;
    
    lo <-- xy & 1;
    hi <-- (xy >> 1) & 1;
    
    lo * (1 - lo) === 0;
    hi * (1 - hi) === 0;
    
    xy === 2 * hi + lo;
}

//------------------------------------------------------------------------------
// XOR 3 bits together

template XOR3_v1() {
    signal input  x;
    signal input  y;
    signal input  z;
    signal output out;
    
    component bs = Bits2();
    bs.xy <== x + y + z;
    bs.lo ==> out;
}

//------------------
// same number of constraints (that is, 2), in the general case
// however circom can optimize y=0 or z=0, unlike with the above
// and hopefully also x=0.

template XOR3_v2() {
    signal input  x;
    signal input  y;
    signal input  z;
    signal output out;
    
    signal tmp <== y * z;
    out <== x * (1 - 2 * y - 2 * z + 4 * tmp) + y + z - 2 * tmp;
}

// for many xors use this one

template XOR3_v3(n) {
    signal input a[n];
    signal input b[n];
    signal input c[n];
    signal output out[n];
    signal mid[n];
    
    for (var k = 0; k < n; k++) {
        mid[k] <== b[k] * c[k];
        out[k] <== a[k] * (1 - 2 * b[k] - 2 * c[k] + 4 * mid[k]) + b[k] + c[k] - 2 * mid[k];
    }
}

