const { assert } = require("console");
const path = require("path");

const Scalar = require("ffjavascript").Scalar;
const wasm_tester = require("circom_tester").wasm;

function floatToNum(x, n){
    return BigInt((x * 2.0 ** n) - (x * 2.0 ** n % 1))
}

function floatToNumCeil(x, n){
    return (x * 2.0 ** n) % 1 < 0.5 ? BigInt((x * 2.0 ** n) - (x * 2.0 ** n % 1)) : BigInt((x * 2.0 ** n) - (x * 2.0 ** n % 1)) + 1n
}

async function testMult(input1, input2, circuit){

    let input = [floatToNum(input1, 16), floatToNum(input2, 16)];

    let real_result = [floatToNum(Number(floatToNum(input1, 16)) / 2**16 * Number(floatToNum(input2, 16)) / 2**16, 16)]

    const w = await circuit.calculateWitness({in: input}, true);

    let circuit_result = w.slice(1, 1+1);

    for (var i = 0; i < 1; i++){
        assert(circuit_result[i] == real_result[i], `${real_result[i]} != ${circuit_result[i]}`)
    }

}
async function testMultCeil(input1, input2, circuit){

    let input = [floatToNum(input1, 16), floatToNum(input2, 16)];

    let real_result = [floatToNumCeil(Number(floatToNum(input1, 16)) / 2**16 * Number(floatToNum(input2, 16)) / 2**16, 16)]

    const w = await circuit.calculateWitness({in: input}, true);

    let circuit_result = w.slice(1, 1+1);

    for (var i = 0; i < 1; i++){
        assert(circuit_result[i] == real_result[i], `${real_result[i]} != ${circuit_result[i]}`)
    }

}

describe("Float mult ceil test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "float", "multceil.circom"));
    });

    it("7.5 * 6.5", async function () {
        await testMultCeil(7.5, 6.5, circuit);
    });
    it("0.5 * 6.5", async function () {
        await testMultCeil(0.5, 6.5, circuit);
    });
    it("123.123 * 123.123", async function () {
        await testMultCeil(123.123, 123.123, circuit);
    });
    it("0.5 * 0.5", async function () {
        await testMultCeil(0.5, 0.5, circuit);
    });
    it("3.35 * 6.5", async function () {
        await testMultCeil(3.35, 6.5, circuit);
    });
    it("0 * 6.5", async function () {
        await testMultCeil(0, 6.5, circuit);
    });
    it("712.5 * 6.335", async function () {
        await testMultCeil(712.5, 6.335, circuit);
    });
    it("7.53 * 6.51", async function () {
        await testMultCeil(7.53, 6.51, circuit);
    });
});


describe("Float mult test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "float", "mult.circom"));
    });

    it("7.5 * 6.5", async function () {
        await testMult(7.5, 6.5, circuit);
    });
    it("0.5 * 6.5", async function () {
        await testMult(0.5, 6.5, circuit);
    });
    it("123.123 * 123.123", async function () {
        await testMult(123.123, 123.123, circuit);
    });
    it("0.5 * 0.5", async function () {
        await testMult(0.5, 0.5, circuit);
    });
    it("3.35 * 6.5", async function () {
        await testMult(3.35, 6.5, circuit);
    });
    it("0 * 6.5", async function () {
        await testMult(0, 6.5, circuit);
    });
    it("712.5 * 6.335", async function () {
        await testMult(712.5, 6.335, circuit);
    });
    it("7.76 * 6.67", async function () {
        await testMult(7.76, 6.67, circuit);
    });
});
