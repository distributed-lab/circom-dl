
pragma circom  2.1.6;

// Get generator by curve params
// Now there is only secp256k1 generator (64 4 chunking)
// Other curves / chunking will be added later
template EllipticCurveGetGenerator(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    assert (CHUNK_SIZE == 64 && CHUNK_NUMBER == 4);

    signal output gen[2][CHUNK_NUMBER];

    if (P[0] == 18446744069414583343 && P[1] == 18446744073709551615 && P[2] == 18446744073709551615 && P[3] == 18446744073709551615){
        gen[0] <== [6481385041966929816, 188021827762530521, 6170039885052185351, 8772561819708210092];
        gen[1] <== [11261198710074299576, 18237243440184513561, 6747795201694173352, 5204712524664259685];
    }
    if (P[0] == 2311270323689771895 && P[1] == 7943213001558335528 && P[2] == 4496292894210231666 && P[3] == 12248480212390422972){
        gen[0] <== [4198572826427273826, 13393186192988382146, 3191724131859150767, 10075307429387458507];
        gen[1] <== [6637554640278022551, 14012744714263826004, 10950579571776363977, 6088576656054338813];
    }
}

// Get "dummy" point
// We can`t if signal in circom, so we always need to do all opertions, even we won`t use results of them
// For example, in scalar mult we can have case where we shouln`t add anything (bits = [0,0, .. ,0])
// We will ignore result, but we still should get it, so we need to pout something anyway
// We use this dummy point for such purposes
// Dummy point = G * 2**256
template EllipticCurveGetDummy(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    assert (CHUNK_SIZE == 64 && CHUNK_NUMBER == 4);

    signal output dummyPoint[2][CHUNK_SIZE];

    if (P[0] == 18446744069414583343 && P[1] == 18446744073709551615 && P[2] == 18446744073709551615 && P[3] == 18446744073709551615){
        dummyPoint[0][0] <== 10590052641807177607;
        dummyPoint[0][1] <== 9925333800925632128;
        dummyPoint[0][2] <== 8387557479920400525;
        dummyPoint[0][3] <== 15939969690812260448;
        dummyPoint[1][0] <== 4032565550822761843;
        dummyPoint[1][1] <== 10670260723290159449;
        dummyPoint[1][2] <== 7050988852899951050;
        dummyPoint[1][3] <== 8797939803687366868;
    }
    if (P[0] == 2311270323689771895 && P[1] == 7943213001558335528 && P[2] == 4496292894210231666 && P[3] == 12248480212390422972){
        dummyPoint[0][0] <== 6780612927088034840;
        dummyPoint[0][1] <== 8014133780695468919;
        dummyPoint[0][2] <== 4483142094233996006;
        dummyPoint[0][3] <== 5761728430295292762;
        dummyPoint[1][0] <== 11756024211369815216;
        dummyPoint[1][1] <== 15043698037253957265;
        dummyPoint[1][2] <== 412673140429275224;
        dummyPoint[1][3] <== 7930703671170472648;
    }
}

// Get order of eliptic curve
template EllipicCurveGetOrder(CHUNK_SIZE, CHUNK_NUMBER, A, B, P){
    assert (CHUNK_SIZE == 64 && CHUNK_NUMBER == 4);

    signal output order[CHUNK_NUMBER];

    if (P[0] == 18446744069414583343 && P[1] == 18446744073709551615 && P[2] == 18446744073709551615 && P[3] == 18446744073709551615){
       order <== [13822214165235122497, 13451932020343611451, 18446744073709551614, 18446744073709551615];
    }
    if (P[0] == 2311270323689771895 && P[1] == 7943213001558335528 && P[2] == 4496292894210231666 && P[3] == 12248480212390422972){
       order <== [10384753744809580199, 10104242082523752183, 4496292894210231665, 12248480212390422972];
    }
}