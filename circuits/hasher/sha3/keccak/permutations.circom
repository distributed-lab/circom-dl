pragma circom 2.0.0;

include "./utils.circom";

template D(n, shl, shr) {
    
    signal input a[n];
    signal input b[n];
    signal output out[n];
    var i;
    
    component aux0 = ShR(64, shr);
    for (i = 0; i < 64; i++) {
        aux0.in[i] <== a[i];
    }
    component aux1 = ShL(64, shl);
    for (i = 0; i < 64; i++) {
        aux1.in[i] <== a[i];
    }
    component aux2 = OrArray(64);
    for (i = 0; i < 64; i++) {
        aux2.a[i] <== aux0.out[i];
        aux2.b[i] <== aux1.out[i];
    }
    component aux3 = XorArray(64);
    for (i = 0; i < 64; i++) {
        aux3.a[i] <== b[i];
        aux3.b[i] <== aux2.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[i] <== aux3.out[i];
    }
}

template Theta() {
    signal input in[25 * 64];
    signal output out[25 * 64];
    
    var i;
    
    component c0 = Xor5(64);
    for (i = 0; i < 64; i++) {
        c0.a[i] <== in[i];
        c0.b[i] <== in[5 * 64 + i];
        c0.c[i] <== in[10 * 64 + i];
        c0.d[i] <== in[15 * 64 + i];
        c0.e[i] <== in[20 * 64 + i];
    }
    
    component c1 = Xor5(64);
    for (i = 0; i < 64; i++) {
        c1.a[i] <== in[1 * 64 + i];
        c1.b[i] <== in[6 * 64 + i];
        c1.c[i] <== in[11 * 64 + i];
        c1.d[i] <== in[16 * 64 + i];
        c1.e[i] <== in[21 * 64 + i];
    }
    
    component c2 = Xor5(64);
    for (i = 0; i < 64; i++) {
        c2.a[i] <== in[2 * 64 + i];
        c2.b[i] <== in[7 * 64 + i];
        c2.c[i] <== in[12 * 64 + i];
        c2.d[i] <== in[17 * 64 + i];
        c2.e[i] <== in[22 * 64 + i];
    }
    
    component c3 = Xor5(64);
    for (i = 0; i < 64; i++) {
        c3.a[i] <== in[3 * 64 + i];
        c3.b[i] <== in[8 * 64 + i];
        c3.c[i] <== in[13 * 64 + i];
        c3.d[i] <== in[18 * 64 + i];
        c3.e[i] <== in[23 * 64 + i];
    }
    
    component c4 = Xor5(64);
    for (i = 0; i < 64; i++) {
        c4.a[i] <== in[4 * 64 + i];
        c4.b[i] <== in[9 * 64 + i];
        c4.c[i] <== in[14 * 64 + i];
        c4.d[i] <== in[19 * 64 + i];
        c4.e[i] <== in[24 * 64 + i];
    }
    
    component d0 = D(64, 1, 64 - 1);
    for (i = 0; i < 64; i++) {
        d0.a[i] <== c1.out[i];
        d0.b[i] <== c4.out[i];
    }
    component r0 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r0.a[i] <== in[i];
        r0.b[i] <== d0.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[i] <== r0.out[i];
    }
    component r5 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r5.a[i] <== in[5 * 64 + i];
        r5.b[i] <== d0.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[5 * 64 + i] <== r5.out[i];
    }
    component r10 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r10.a[i] <== in[10 * 64 + i];
        r10.b[i] <== d0.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[10 * 64 + i] <== r10.out[i];
    }
    component r15 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r15.a[i] <== in[15 * 64 + i];
        r15.b[i] <== d0.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[15 * 64 + i] <== r15.out[i];
    }
    component r20 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r20.a[i] <== in[20 * 64 + i];
        r20.b[i] <== d0.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[20 * 64 + i] <== r20.out[i];
    }
    
    component d1 = D(64, 1, 64 - 1);
    for (i = 0; i < 64; i++) {
        d1.a[i] <== c2.out[i];
        d1.b[i] <== c0.out[i];
    }

    component r1 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r1.a[i] <== in[1 * 64 + i];
        r1.b[i] <== d1.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[1 * 64 + i] <== r1.out[i];
    }

    component r6 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r6.a[i] <== in[6 * 64 + i];
        r6.b[i] <== d1.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[6 * 64 + i] <== r6.out[i];
    }
    component r11 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r11.a[i] <== in[11 * 64 + i];
        r11.b[i] <== d1.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[11 * 64 + i] <== r11.out[i];
    }
    component r16 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r16.a[i] <== in[16 * 64 + i];
        r16.b[i] <== d1.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[16 * 64 + i] <== r16.out[i];
    }
    component r21 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r21.a[i] <== in[21 * 64 + i];
        r21.b[i] <== d1.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[21 * 64 + i] <== r21.out[i];
    }
    
    component d2 = D(64, 1, 64 - 1);
    for (i = 0; i < 64; i++) {
        d2.a[i] <== c3.out[i];
        d2.b[i] <== c1.out[i];
    }
    component r2 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r2.a[i] <== in[2 * 64 + i];
        r2.b[i] <== d2.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[2 * 64 + i] <== r2.out[i];
    }
    component r7 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r7.a[i] <== in[7 * 64 + i];
        r7.b[i] <== d2.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[7 * 64 + i] <== r7.out[i];
    }
    component r12 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r12.a[i] <== in[12 * 64 + i];
        r12.b[i] <== d2.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[12 * 64 + i] <== r12.out[i];
    }
    component r17 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r17.a[i] <== in[17 * 64 + i];
        r17.b[i] <== d2.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[17 * 64 + i] <== r17.out[i];
    }
    component r22 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r22.a[i] <== in[22 * 64 + i];
        r22.b[i] <== d2.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[22 * 64 + i] <== r22.out[i];
    }
    
    component d3 = D(64, 1, 64 - 1);
    for (i = 0; i < 64; i++) {
        d3.a[i] <== c4.out[i];
        d3.b[i] <== c2.out[i];
    }
    component r3 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r3.a[i] <== in[3 * 64 + i];
        r3.b[i] <== d3.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[3 * 64 + i] <== r3.out[i];
    }
    component r8 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r8.a[i] <== in[8 * 64 + i];
        r8.b[i] <== d3.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[8 * 64 + i] <== r8.out[i];
    }
    component r13 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r13.a[i] <== in[13 * 64 + i];
        r13.b[i] <== d3.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[13 * 64 + i] <== r13.out[i];
    }
    component r18 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r18.a[i] <== in[18 * 64 + i];
        r18.b[i] <== d3.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[18 * 64 + i] <== r18.out[i];
    }
    component r23 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r23.a[i] <== in[23 * 64 + i];
        r23.b[i] <== d3.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[23 * 64 + i] <== r23.out[i];
    }
    
    component d4 = D(64, 1, 64 - 1);
    for (i = 0; i < 64; i++) {
        d4.a[i] <== c0.out[i];
        d4.b[i] <== c3.out[i];
    }
    component r4 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r4.a[i] <== in[4 * 64 + i];
        r4.b[i] <== d4.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[4 * 64 + i] <== r4.out[i];
    }
    component r9 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r9.a[i] <== in[9 * 64 + i];
        r9.b[i] <== d4.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[9 * 64 + i] <== r9.out[i];
    }
    component r14 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r14.a[i] <== in[14 * 64 + i];
        r14.b[i] <== d4.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[14 * 64 + i] <== r14.out[i];
    }
    component r19 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r19.a[i] <== in[19 * 64 + i];
        r19.b[i] <== d4.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[19 * 64 + i] <== r19.out[i];
    }
    component r24 = XorArray(64);
    for (i = 0; i < 64; i++) {
        r24.a[i] <== in[24 * 64 + i];
        r24.b[i] <== d4.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[24 * 64 + i] <== r24.out[i];
    }
}


template stepRhoPi(shl, shr) {
    signal input a[64];
    signal output out[64];
    var i;
    
    component aux0 = ShR(64, shr);
    for (i = 0; i < 64; i++) {
        aux0.in[i] <== a[i];
    }
    component aux1 = ShL(64, shl);
    for (i = 0; i < 64; i++) {
        aux1.in[i] <== a[i];
    }
    component aux2 = OrArray(64);
    for (i = 0; i < 64; i++) {
        aux2.a[i] <== aux0.out[i];
        aux2.b[i] <== aux1.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[i] <== aux2.out[i];
    }
}

template RhoPi() {
    signal input in[25 * 64];
    signal output out[25 * 64];
    
    var i;
    
    component s10 = stepRhoPi(1, 64 - 1);
    for (i = 0; i < 64; i++) {
        s10.a[i] <== in[1 * 64 + i];
    }
    component s7 = stepRhoPi(3, 64 - 3);
    for (i = 0; i < 64; i++) {
        s7.a[i] <== in[10 * 64 + i];
    }
    component s11 = stepRhoPi(6, 64 - 6);
    for (i = 0; i < 64; i++) {
        s11.a[i] <== in[7 * 64 + i];
    }
    component s17 = stepRhoPi(10, 64 - 10);
    for (i = 0; i < 64; i++) {
        s17.a[i] <== in[11 * 64 + i];
    }
    component s18 = stepRhoPi(15, 64 - 15);
    for (i = 0; i < 64; i++) {
        s18.a[i] <== in[17 * 64 + i];
    }
    component s3 = stepRhoPi(21, 64 - 21);
    for (i = 0; i < 64; i++) {
        s3.a[i] <== in[18 * 64 + i];
    }
    component s5 = stepRhoPi(28, 64 - 28);
    for (i = 0; i < 64; i++) {
        s5.a[i] <== in[3 * 64 + i];
    }
    component s16 = stepRhoPi(36, 64 - 36);
    for (i = 0; i < 64; i++) {
        s16.a[i] <== in[5 * 64 + i];
    }
    component s8 = stepRhoPi(45, 64 - 45);
    for (i = 0; i < 64; i++) {
        s8.a[i] <== in[16 * 64 + i];
    }
    component s21 = stepRhoPi(55, 64 - 55);
    for (i = 0; i < 64; i++) {
        s21.a[i] <== in[8 * 64 + i];
    }
    component s24 = stepRhoPi(2, 64 - 2);
    for (i = 0; i < 64; i++) {
        s24.a[i] <== in[21 * 64 + i];
    }
    component s4 = stepRhoPi(14, 64 - 14);
    for (i = 0; i < 64; i++) {
        s4.a[i] <== in[24 * 64 + i];
    }
    component s15 = stepRhoPi(27, 64 - 27);
    for (i = 0; i < 64; i++) {
        s15.a[i] <== in[4 * 64 + i];
    }
    component s23 = stepRhoPi(41, 64 - 41);
    for (i = 0; i < 64; i++) {
        s23.a[i] <== in[15 * 64 + i];
    }
    component s19 = stepRhoPi(56, 64 - 56);
    for (i = 0; i < 64; i++) {
        s19.a[i] <== in[23 * 64 + i];
    }
    component s13 = stepRhoPi(8, 64 - 8);
    for (i = 0; i < 64; i++) {
        s13.a[i] <== in[19 * 64 + i];
    }
    component s12 = stepRhoPi(25, 64 - 25);
    for (i = 0; i < 64; i++) {
        s12.a[i] <== in[13 * 64 + i];
    }
    component s2 = stepRhoPi(43, 64 - 43);
    for (i = 0; i < 64; i++) {
        s2.a[i] <== in[12 * 64 + i];
    }
    component s20 = stepRhoPi(62, 64 - 62);
    for (i = 0; i < 64; i++) {
        s20.a[i] <== in[2 * 64 + i];
    }
    component s14 = stepRhoPi(18, 64 - 18);
    for (i = 0; i < 64; i++) {
        s14.a[i] <== in[20 * 64 + i];
    }
    component s22 = stepRhoPi(39, 64 - 39);
    for (i = 0; i < 64; i++) {
        s22.a[i] <== in[14 * 64 + i];
    }
    component s9 = stepRhoPi(61, 64 - 61);
    for (i = 0; i < 64; i++) {
        s9.a[i] <== in[22 * 64 + i];
    }
    component s6 = stepRhoPi(20, 64 - 20);
    for (i = 0; i < 64; i++) {
        s6.a[i] <== in[9 * 64 + i];
    }
    component s1 = stepRhoPi(44, 64 - 44);
    for (i = 0; i < 64; i++) {
        s1.a[i] <== in[6 * 64 + i];
    }
    
    for (i = 0; i < 64; i++) {
        out[i] <== in[i];
        out[10 * 64 + i] <== s10.out[i];
        out[7 * 64 + i] <== s7.out[i];
        out[11 * 64 + i] <== s11.out[i];
        out[17 * 64 + i] <== s17.out[i];
        out[18 * 64 + i] <== s18.out[i];
        out[3 * 64 + i] <== s3.out[i];
        out[5 * 64 + i] <== s5.out[i];
        out[16 * 64 + i] <== s16.out[i];
        out[8 * 64 + i] <== s8.out[i];
        out[21 * 64 + i] <== s21.out[i];
        out[24 * 64 + i] <== s24.out[i];
        out[4 * 64 + i] <== s4.out[i];
        out[15 * 64 + i] <== s15.out[i];
        out[23 * 64 + i] <== s23.out[i];
        out[19 * 64 + i] <== s19.out[i];
        out[13 * 64 + i] <== s13.out[i];
        out[12 * 64 + i] <== s12.out[i];
        out[2 * 64 + i] <== s2.out[i];
        out[20 * 64 + i] <== s20.out[i];
        out[14 * 64 + i] <== s14.out[i];
        out[22 * 64 + i] <== s22.out[i];
        out[9 * 64 + i] <== s9.out[i];
        out[6 * 64 + i] <== s6.out[i];
        out[1 * 64 + i] <== s1.out[i];
    }
}


template stepChi() {
    signal input a[64];
    signal input b[64];
    signal input c[64];
    signal output out[64];
    var i;
    
    component bXor = XorArraySingle(64);
    for (i = 0; i < 64; i++) {
        bXor.a[i] <== b[i];
    }
    component bc = AndArray(64);
    for (i = 0; i < 64; i++) {
        bc.a[i] <== bXor.out[i];
        bc.b[i] <== c[i];
    }
    component abc = XorArray(64);
    for (i = 0; i < 64; i++) {
        abc.a[i] <== a[i];
        abc.b[i] <== bc.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[i] <== abc.out[i];
    }
}

template Chi() {
    signal input in[25 * 64];
    signal output out[25 * 64];
    
    var i;
    
    component r0 = stepChi();
    for (i = 0; i < 64; i++) {
        r0.a[i] <== in[i];
        r0.b[i] <== in[1 * 64 + i];
        r0.c[i] <== in[2 * 64 + i];
    }
    component r1 = stepChi();
    for (i = 0; i < 64; i++) {
        r1.a[i] <== in[1 * 64 + i];
        r1.b[i] <== in[2 * 64 + i];
        r1.c[i] <== in[3 * 64 + i];
    }
    component r2 = stepChi();
    for (i = 0; i < 64; i++) {
        r2.a[i] <== in[2 * 64 + i];
        r2.b[i] <== in[3 * 64 + i];
        r2.c[i] <== in[4 * 64 + i];
    }
    component r3 = stepChi();
    for (i = 0; i < 64; i++) {
        r3.a[i] <== in[3 * 64 + i];
        r3.b[i] <== in[4 * 64 + i];
        r3.c[i] <== in[0 * 64 + i];
    }
    component r4 = stepChi();
    for (i = 0; i < 64; i++) {
        r4.a[i] <== in[4 * 64 + i];
        r4.b[i] <== in[i];
        r4.c[i] <== in[1 * 64 + i];
    }
    
    component r5 = stepChi();
    for (i = 0; i < 64; i++) {
        r5.a[i] <== in[5 * 64 + i];
        r5.b[i] <== in[6 * 64 + i];
        r5.c[i] <== in[7 * 64 + i];
    }
    component r6 = stepChi();
    for (i = 0; i < 64; i++) {
        r6.a[i] <== in[6 * 64 + i];
        r6.b[i] <== in[7 * 64 + i];
        r6.c[i] <== in[8 * 64 + i];
    }
    component r7 = stepChi();
    for (i = 0; i < 64; i++) {
        r7.a[i] <== in[7 * 64 + i];
        r7.b[i] <== in[8 * 64 + i];
        r7.c[i] <== in[9 * 64 + i];
    }
    component r8 = stepChi();
    for (i = 0; i < 64; i++) {
        r8.a[i] <== in[8 * 64 + i];
        r8.b[i] <== in[9 * 64 + i];
        r8.c[i] <== in[5 * 64 + i];
    }
    component r9 = stepChi();
    for (i = 0; i < 64; i++) {
        r9.a[i] <== in[9 * 64 + i];
        r9.b[i] <== in[5 * 64 + i];
        r9.c[i] <== in[6 * 64 + i];
    }
    
    component r10 = stepChi();
    for (i = 0; i < 64; i++) {
        r10.a[i] <== in[10 * 64 + i];
        r10.b[i] <== in[11 * 64 + i];
        r10.c[i] <== in[12 * 64 + i];
    }
    component r11 = stepChi();
    for (i = 0; i < 64; i++) {
        r11.a[i] <== in[11 * 64 + i];
        r11.b[i] <== in[12 * 64 + i];
        r11.c[i] <== in[13 * 64 + i];
    }
    component r12 = stepChi();
    for (i = 0; i < 64; i++) {
        r12.a[i] <== in[12 * 64 + i];
        r12.b[i] <== in[13 * 64 + i];
        r12.c[i] <== in[14 * 64 + i];
    }
    component r13 = stepChi();
    for (i = 0; i < 64; i++) {
        r13.a[i] <== in[13 * 64 + i];
        r13.b[i] <== in[14 * 64 + i];
        r13.c[i] <== in[10 * 64 + i];
    }
    component r14 = stepChi();
    for (i = 0; i < 64; i++) {
        r14.a[i] <== in[14 * 64 + i];
        r14.b[i] <== in[10 * 64 + i];
        r14.c[i] <== in[11 * 64 + i];
    }
    
    component r15 = stepChi();
    for (i = 0; i < 64; i++) {
        r15.a[i] <== in[15 * 64 + i];
        r15.b[i] <== in[16 * 64 + i];
        r15.c[i] <== in[17 * 64 + i];
    }
    component r16 = stepChi();
    for (i = 0; i < 64; i++) {
        r16.a[i] <== in[16 * 64 + i];
        r16.b[i] <== in[17 * 64 + i];
        r16.c[i] <== in[18 * 64 + i];
    }
    component r17 = stepChi();
    for (i = 0; i < 64; i++) {
        r17.a[i] <== in[17 * 64 + i];
        r17.b[i] <== in[18 * 64 + i];
        r17.c[i] <== in[19 * 64 + i];
    }
    component r18 = stepChi();
    for (i = 0; i < 64; i++) {
        r18.a[i] <== in[18 * 64 + i];
        r18.b[i] <== in[19 * 64 + i];
        r18.c[i] <== in[15 * 64 + i];
    }
    component r19 = stepChi();
    for (i = 0; i < 64; i++) {
        r19.a[i] <== in[19 * 64 + i];
        r19.b[i] <== in[15 * 64 + i];
        r19.c[i] <== in[16 * 64 + i];
    }
    
    component r20 = stepChi();
    for (i = 0; i < 64; i++) {
        r20.a[i] <== in[20 * 64 + i];
        r20.b[i] <== in[21 * 64 + i];
        r20.c[i] <== in[22 * 64 + i];
    }
    component r21 = stepChi();
    for (i = 0; i < 64; i++) {
        r21.a[i] <== in[21 * 64 + i];
        r21.b[i] <== in[22 * 64 + i];
        r21.c[i] <== in[23 * 64 + i];
    }
    component r22 = stepChi();
    for (i = 0; i < 64; i++) {
        r22.a[i] <== in[22 * 64 + i];
        r22.b[i] <== in[23 * 64 + i];
        r22.c[i] <== in[24 * 64 + i];
    }
    component r23 = stepChi();
    for (i = 0; i < 64; i++) {
        r23.a[i] <== in[23 * 64 + i];
        r23.b[i] <== in[24 * 64 + i];
        r23.c[i] <== in[20 * 64 + i];
    }
    component r24 = stepChi();
    for (i = 0; i < 64; i++) {
        r24.a[i] <== in[24 * 64 + i];
        r24.b[i] <== in[20 * 64 + i];
        r24.c[i] <== in[21 * 64 + i];
    }
    
    for (i = 0; i < 64; i++) {
        out[i] <== r0.out[i];
        out[1 * 64 + i] <== r1.out[i];
        out[2 * 64 + i] <== r2.out[i];
        out[3 * 64 + i] <== r3.out[i];
        out[4 * 64 + i] <== r4.out[i];
        
        out[5 * 64 + i] <== r5.out[i];
        out[6 * 64 + i] <== r6.out[i];
        out[7 * 64 + i] <== r7.out[i];
        out[8 * 64 + i] <== r8.out[i];
        out[9 * 64 + i] <== r9.out[i];
        
        out[10 * 64 + i] <== r10.out[i];
        out[11 * 64 + i] <== r11.out[i];
        out[12 * 64 + i] <== r12.out[i];
        out[13 * 64 + i] <== r13.out[i];
        out[14 * 64 + i] <== r14.out[i];
        
        out[15 * 64 + i] <== r15.out[i];
        out[16 * 64 + i] <== r16.out[i];
        out[17 * 64 + i] <== r17.out[i];
        out[18 * 64 + i] <== r18.out[i];
        out[19 * 64 + i] <== r19.out[i];
        
        out[20 * 64 + i] <== r20.out[i];
        out[21 * 64 + i] <== r21.out[i];
        out[22 * 64 + i] <== r22.out[i];
        out[23 * 64 + i] <== r23.out[i];
        out[24 * 64 + i] <== r24.out[i];
    }
}

template RC(r) {
    signal output out[64];
    var rc[24] = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A,
    0x8000000080008000, 0x000000000000808B, 0x0000000080000001,
    0x8000000080008081, 0x8000000000008009, 0x000000000000008A,
    0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000000008089,
    0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
    0x000000000000800A, 0x800000008000000A, 0x8000000080008081,
    0x8000000000008080, 0x0000000080000001, 0x8000000080008008
    ];
    for (var i = 0; i < 64; i++) {
        out[i] <== (rc[r] >> i) & 1;
    }
}

template Iota(r) {
    signal input in[25 * 64];
    signal output out[25 * 64];
    var i;
    
    component rc = RC(r);
    
    component iota = XorArray(64);
    for (var i = 0; i < 64; i++) {
        iota.a[i] <== in[i];
        iota.b[i] <== rc.out[i];
    }
    for (i = 0; i < 64; i++) {
        out[i] <== iota.out[i];
    }
    for (i = 64; i < 25 * 64; i++) {
        out[i] <== in[i];
    }
}

