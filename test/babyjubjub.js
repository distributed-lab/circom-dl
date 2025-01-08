const p = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;
const { assert } = require("console");
const path = require("path");

const Scalar = require("ffjavascript").Scalar;
const wasm_tester = require("circom_tester").wasm;

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
function mod(a, m) {
    return ((a % m) + 168697n * m) % m;
}

function scalarMult(k, x, y) {
    let R_x = 0n, R_y = 1n;  
    const base_x = BigInt(x), base_y = BigInt(y); 

    const bit_str = k.toString(2);

    for (const bit of bit_str) {
        [R_x, R_y] = add(R_x, R_y, R_x, R_y);

        if (bit === '1') {
            [R_x, R_y] = add(R_x, R_y, base_x, base_y);
        }
    }

    return [R_x, R_y];
}


function add(x1, y1, x2, y2) {
    const a = 168700n;
    const d = 168696n;

    const beta = mod(x1 * y2, p);
    const gamma = mod(x2 * y1, p);
    const delta = mod((y1 - a * x1) * (x2 + y2), p);
    const tau = mod(beta * gamma, p);

    const inv1 = modInverse(mod(1n + d * tau, p), p);
    const inv2 = modInverse(mod(1n - d * tau, p), p);

    const x3 = mod((beta + gamma) * inv1, p);
    const y3 = mod((delta + a * beta - gamma) * inv2, p);

    return [x3, y3];
}





async function testAdding(input1, input2, circuit){

    let [x1, y1] = input1;
    let [x2, y2] = input2;

    let real_result = add(x1, y1, x2, y2);

    const w = await circuit.calculateWitness({in1: input1, in2: input2}, true);

    let circuit_result = w.slice(1, 1+2);

    for (var i = 0; i < 2; i++){
        assert(circuit_result[i] == real_result[i])
    }
}

async function testDoubling(input1, circuit){

    let [x1, y1] = input1;

    let real_result = add(x1, y1, x1, y1);

    const w = await circuit.calculateWitness({in: input1}, true);

    let circuit_result = w.slice(1, 1+2);

    for (var i = 0; i < 2; i++){
        assert(circuit_result[i] == real_result[i])
    }
}

async function testScalarMult(input1, input2, circuit){

    let [x1, y1] = input1;

    let real_result = scalarMult(input2, x1, y1);

    const w = await circuit.calculateWitness({in: input1, scalar: input2}, true);

    let circuit_result = w.slice(1, 1+2);

    for (var i = 0; i < 2; i++){
        assert(circuit_result[i] == real_result[i])
    }
}
describe("Babyjubjub add test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "babyjubjub", "add.circom"));
    });


    it("(5299619240641551281634865583518297030282874472190772894086521144482721001553, 16950150798460657717958625567821834550301663161624707787222815936182638968203) + (1003126217192754014866735552636903439803088643709204510575224869955738519782, 633281375905621697187330766174974863687049529291089048651929454608812697683)", async function () {
        await testAdding([5299619240641551281634865583518297030282874472190772894086521144482721001553n, 16950150798460657717958625567821834550301663161624707787222815936182638968203n], [10031262171927540148667355526369034398030886437092045105752248699557385197826n, 633281375905621697187330766174974863687049529291089048651929454608812697683n], circuit);
    });

});


describe("Babyjubjub double test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "babyjubjub", "double.circom"));
    });

    it("(5299619240641551281634865583518297030282874472190772894086521144482721001553, 16950150798460657717958625567821834550301663161624707787222815936182638968203) * 2", async function () {
        await testDoubling([5299619240641551281634865583518297030282874472190772894086521144482721001553n, 16950150798460657717958625567821834550301663161624707787222815936182638968203n], circuit);
    });

});



describe("Babyjubjub scalar multiplication test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "babyjubjub", "scalarMult.circom"));
    });

    it("(5299619240641551281634865583518297030282874472190772894086521144482721001553, 16950150798460657717958625567821834550301663161624707787222815936182638968203) * 4234234234234234234234234243234234234234234234234234234", async function () {
        await testScalarMult([5299619240641551281634865583518297030282874472190772894086521144482721001553n, 16950150798460657717958625567821834550301663161624707787222815936182638968203n], 4234234234234234234234234243234234234234234234234234234n, circuit);
    });

});

