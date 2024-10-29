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

async function testMultiplying(input1, input2, circuit){
    let input = [bigintToArray(64, 4, input1), bigintToArray(64, 4, input2)];

    let real_result = bigintToArray(64, 8, input1 * input2);

    const w = await circuit.calculateWitness({in: input}, true);

    let circuit_result = w.slice(1, 1+8);

    for (var i = 0; i < 8; i++){
        assert(circuit_result[i] == real_result[i])
    }

}

describe("Big mult test", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "bigMult.circom"));
    });

    it("15 * 15", async function () {
        await testMultiplying(15n, 15n, circuit);
    });

    it("109730872847609188478309451572148122150330802072000585050763249942403213063436 * 109730872847609188478309451572148122150330802072000585050763249942403213063436", async function () {
        await testMultiplying(109730872847609188478309451572148122150330802072000585050763249942403213063436n, 109730872847609188478309451572148122150330802072000585050763249942403213063436n, circuit);
    });

    it("15 * 109730872847609188478309451572148122150330802072000585050763249942403213063436", async function () {
        await testMultiplying(15n, 109730872847609188478309451572148122150330802072000585050763249942403213063436n, circuit);
    });

});
