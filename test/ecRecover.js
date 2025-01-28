const { assert, log } = require("console");
const path = require("path");

const Scalar = require("ffjavascript").Scalar;
const wasm_tester = require("circom_tester").wasm;


function getRandomBigInt(max) {
    const maxDigits = max.toString(2).length; // Number of bits needed
    let randomBigInt;

    do {
        // Generate a random BigInt within the range
        randomBigInt = BigInt('0b' + Array.from({ length: maxDigits }, () => Math.random() > 0.5 ? '1' : '0').join(''));
    } while (randomBigInt < BigInt(1) || randomBigInt >= max);

    return randomBigInt;
}

function bigintToArray(n, k, x) {
    let mod = BigInt(1);
    for (let idx = 0; idx < n; idx++) {
        mod *= BigInt(2);
    }

    const ret = [];
    let xTemp = x;
    for (let idx = 0; idx < k; idx++) {
        ret.push(xTemp % mod);
        xTemp /= mod; 
    }

    return ret;
}

function modInverse(a, m) {
    a = BigInt(a);
    m = BigInt(m);
  
    let m0 = m;
    let x0 = BigInt(0);
    let x1 = BigInt(1);
  
    if (m === 1n) return 0n;
  
    while (a > 1n) {
        let q = a / m;
        let t = m;

        m = a % m;
        a = t;
        t = x0;

        x0 = x1 - q * x0;
        x1 = t;
    }

    if (x1 < 0n) {
        x1 += m0;
    }

    return x1;
}

function point_double(x1, y1, a, p) {
    x1 = BigInt(x1);
    y1 = BigInt(y1);
    a = BigInt(a);
    p = BigInt(p);

    if (y1 === 0n) {
        return { x: null, y: null }; 
    }

    let lambda_num = (3n * x1 * x1 + a) % p;
    let lambda_den = modInverse(2n * y1, p);
    let lam = (lambda_num * lambda_den) % p;

    let x3 = (lam * lam - 2n * x1) % p;
    let y3 = (lam * (x1 - x3) - y1) % p;

    if (x3 < 0n) x3 += p;
    if (y3 < 0n) y3 += p;

    return { x: x3, y: y3 };
}

function point_add(x1, y1, x2, y2, p) {
    x1 = BigInt(x1);
    y1 = BigInt(y1);
    x2 = BigInt(x2);
    y2 = BigInt(y2);
    p = BigInt(p);

    if (x1 === x2 && y1 === y2) {
        throw new Error("Points are the same; use point_double instead.");
    }

    if (x1 === x2) {
        return { x: null, y: null };
    }
    let lambda_num = (p + y2 - y1) % p;
    let lambda_den = modInverse((p + x2 - x1) % p, p);
    let lam = (lambda_num * lambda_den) % p;

    let x3 = (2n * p + lam * lam - x1 - x2) % p;
    let y3 = (p + lam * (x1 - x3) - y1) % p;

    if (x3 < 0n) x3 += p;
    if (y3 < 0n) y3 += p;

    return { x: x3, y: y3 };
}

function point_scalar_mul(x, y, k, a, p) {
    let x_res = null;
    let y_res = null;

    let x_cur = x;
    let y_cur = y;

    while (k > 0n) {
        if (k & 1n) {
            if (x_res === null && y_res === null) {
                x_res = x_cur;
                y_res = y_cur;
            } else {
                const { x: x_temp, y: y_temp } = point_add(x_res, y_res, x_cur, y_cur, p);
                x_res = x_temp;
                y_res = y_temp;
            }
        }

        const { x: x_temp, y: y_temp } = point_double(x_cur, y_cur, a, p);
        x_cur = x_temp;
        y_cur = y_temp;

        k >>= 1n; // Shift k right by 1 bit
    }

    return { x: x_res, y: y_res };
}

function ecdsa_sign(hashed, d, Gx, Gy, a, p, n){
    while (true) {
        // Step 1: Generate a random integer k in the range [1, n-1]
        const k = getRandomBigInt(n);
        // Step 2: Compute R = k * G and r = Rx mod n
        const point = point_scalar_mul(Gx, Gy, k, a, p);
        // Determine v: If Ry is even, v is 1; otherwise, v is 0
        const v = BigInt(1) - (point.y % BigInt(2));

        const r = point.x % n;

        // If r == 0, restart the process
        if (r === BigInt(0)) {
            continue;
        }

        // Step 3: Compute k^-1 mod n
        const kInv = modInverse(k, n);

        // Step 4: Compute s = k^-1 * (z + r * d) mod n
        const s = (kInv * (hashed + r * d)) % n;

        // If s == 0, restart the process
        if (s === BigInt(0)) {
            continue;
        }

        // Return the signature (v, r, s)
        return { v, r, s };
    }
}
async function testEcRecover(input1, circuit){

    p = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2fn
    a = 0x0000000000000000000000000000000000000000000000000000000000000000n
    b = 0x0000000000000000000000000000000000000000000000000000000000000007n
    Gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798n
    Gy = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8n
    n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141n

    priv = 0xaa9ba9e840d90f125898594beeabd258eb7834d6b19aba6ae81e8ce35a168e8dn
    x = 0xe3c268f54bbccbc1394d632631d6c0c9bd545c2beb697f3ac6aee7b79e92d033n
    y = 0x20d88d223a33af0770a1abb704703d9f38b6be3d5ce703916f7bd1005e3e294en

    var {v,r,s} = ecdsa_sign(input1, priv, Gx, Gy, a, p, n)
    // console.log(v, r, s)

    let real_result = bigintToArray(64, 4, x).concat(bigintToArray(64, 4, y));

    const w = await circuit.calculateWitness({r: bigintToArray(64, 4, r), s: bigintToArray(64, 4, s), hashed: bigintToArray(64, 4, input1), dummy: 0, v: BigInt(v)}, true);

    let circuit_result = w.slice(1, 1+8);

    for (var i = 0; i < 8; i++){
        assert(circuit_result[i] == real_result[i], ``);
    }
}


describe("Secp256k1 EcRecover test", function () {

    this.timeout(10000000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "signatures", "recover.circom"));
    });


    it("Recover message sha256('123')", async function () {
        await testEcRecover(0xb71de80778f2783383f5d5a3028af84eab2f18a4eb38968172ca41724dd4b3f4n, circuit);
    });

});

