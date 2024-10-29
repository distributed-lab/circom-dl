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

async function testIsEqual(input1, input2, circuit){
    let input = [bigintToArray(64, 4, input1), bigintToArray(64, 4, input2)];

    let real_result = 1n;

    if (input1 != input2){
        real_result == 0n
    }

    const w = await circuit.calculateWitness({in: input}, true);

    let circuit_result = w[1];

    assert(circuit_result == real_result)

}

describe("Equal test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "bigIsEqual.circom"));
    });

    it("15 === 15", async function () {
        await testIsEqual(15n, 15n, circuit);
    });

    it("15 === 16", async function () {
        await testIsEqual(15n, 16n, circuit);
    });

    it("109730872847609188478309451572148122150330802072000585050763249942403213063436 === 109730872847609188478309451572148122150330802072000585050763249942403213063436", async function () {
        await testIsEqual(109730872847609188478309451572148122150330802072000585050763249942403213063436n, 109730872847609188478309451572148122150330802072000585050763249942403213063436n, circuit);
    });

    it("15 === 109730872847609188478309451572148122150330802072000585050763249942403213063436", async function () {
        await testIsEqual(15n, 109730872847609188478309451572148122150330802072000585050763249942403213063436n, circuit);
    });

    it("ff...ff (256 bit) === ff...ff (256 bit)", async function () {
        await testIsEqual(115792089237316195423570985008687907853269984665640564039457584007913129639935n, 115792089237316195423570985008687907853269984665640564039457584007913129639935n, circuit);
    });

});
