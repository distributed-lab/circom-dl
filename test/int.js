const { assert } = require("console");
const path = require("path");

const Scalar = require("ffjavascript").Scalar;
const wasm_tester = require("circom_tester").wasm;

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

async function testInverse(input, circuit){
    let real_result = [1n]
    if (input == 2n){
        real_result = [10944121435919637611123202872628637544274182200208017171849102093287904247809n];
    }

    const w = await circuit.calculateWitness({in: input}, true);

    let circuit_result = w.slice(1, 1+1);

    for (var i = 0; i < 1; i++){
        assert(circuit_result[i] == real_result[i], `1 / ${input}`);
    }

}
async function testDivision(input1, input2, circuit){
    let input = [input1, input2];

    let real_result = [input1 / input2, input1 % input2];

    const w = await circuit.calculateWitness({in: input}, true);

    let circuit_result = w.slice(1, 1+2);

    for (var i = 0; i < 2; i++){
        assert(circuit_result[i] == real_result[i], `in: ${input1} / ${input2}`)
    }
}

async function testDivisionStrict(input1, input2, circuit){
    let input = [input1, input2];

    let real_result = [input1 / input2, input1 % input2];

    const w = await circuit.calculateWitness({in: input}, true);

    let circuit_result = w.slice(1, 1+2);


    for (var i = 0; i < 2; i++){
        assert(circuit_result[i] == real_result[1-i], `in: ${input1} / ${input2}, ${i}: ${real_result[i]}`)
    }
}

describe("Inverse test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "int", "inverse.circom"));
    });

    it("1 \\ 1", async function () {
        await testInverse(1n, circuit);
    });

    it("1 \\ 2", async function () {
        await testInverse(2n, circuit);
    });

});

describe("Division test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "int", "division.circom"));
    });

    it("7 / 3", async function () {
        await testDivision(7n, 3n, circuit);
    });

    it("500 / 34", async function () {
        await testDivision(500n, 34n, circuit);
    });

    it("140 / 20", async function () {
        await testDivision(140n, 20n, circuit);
    });

});

describe("Division (strict) test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "int", "divisionStrict.circom"));
    });

    it("7 / 3", async function () {
        await testDivisionStrict(7n, 3n, circuit);
    });

    it("500 / 34", async function () {
        await testDivisionStrict(500n, 34n, circuit);
    });

    it("140 / 20", async function () {
        await testDivisionStrict(140n, 20n, circuit);
    });
});