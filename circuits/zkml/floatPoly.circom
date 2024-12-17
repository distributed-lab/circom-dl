pragma circom 2.1.6;

include "../float/float.circom";
include "../int/arithmetic.circom";

template CalculatePolynomial(deg, prec, intprec) {
    var maxdeg = 250 \ (prec + intprec);
    //log(1 << prec);
    signal input coef[deg+1];
    signal input value;
    signal input dummy;

    signal powers[deg+1];

    component sum = GetSumOfNElements(deg+1);
    sum.dummy <== dummy;
    component cut[(deg-1) \ (maxdeg-1) + 1];
    for (var i = 0; i < deg + 1; i++) {
        if (i == 0) {
            powers[0] <== 1;
            sum.in[0] <== coef[0] * powers[0] * (1 << ((maxdeg-1)*prec));
            //log(i, coef[0] * powers[0] * (1 << ((maxdeg-1)*prec)), powers[i]);
        }
        else {
            if (i == 1) {
                powers[1] <== value;
                sum.in[1] <== coef[1] * powers[1] * (1<<((maxdeg-2)*prec));
                //log(i, coef[1] * powers[1] * (1<<((maxdeg-2)*prec)), powers[i]);
            }
            else if (i != 1 && i % (maxdeg - 1) == 1) {
                cut[i \ (maxdeg - 1) - 1] = RemovePrecision(prec, maxdeg*prec);
                cut[i \ (maxdeg - 1) - 1].in <== powers[i-1] * value;
                powers[i] <== cut[i \ (maxdeg - 1) - 1].out;
                sum.in[i] <== coef[i] * powers[i] * (1<<((maxdeg-2)*prec));
                //log(i, coef[i] * powers[i] * (1<<((maxdeg-2)*prec)), powers[i]);
            }
            else {
                powers[i] <== powers[i-1] * value;
                sum.in[i] <== coef[i] * powers[i]* (1<<((maxdeg - 1 - ((i-1) % (maxdeg-1) + 1))*prec));
                //log(i, coef[i] * powers[i]* (1<<((maxdeg - 1 - ((i-1) % (maxdeg-1) + 1))*prec)), powers[i]);
            }
        }
    }
    component lastCut = RemovePrecision(prec, maxdeg*prec);
    lastCut.in <== sum.out;
    signal output out;
    out <== lastCut.out;
    //log(out);
}