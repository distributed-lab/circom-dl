const { assert, log } = require("console");
const path = require("path");
const Scalar = require("ffjavascript").Scalar;
const wasm_tester = require("circom_tester").wasm;


async function testSort(input, circuit){

    const real_result = input.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
    
    const w = await circuit.calculateWitness({ in: input}, true);

    let circuit_result = w.slice(1, 1+12);

    for (var i = 0; i < 12; i++){
        assert(circuit_result[i] == real_result[i], `Sort`);
    }
}


describe("Heap sort", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "sort", "heapSort.circom"));
    });

    it("sort([12,3,5,6,7,8,9,3,2,1,5,6])", async function () {
        await testSort([12n,3n,5n,6n,7n,8n,9n,3n,2n,1n,5n,6n], circuit);
    });

});

describe("NonSignalSort sort", function () {

    this.timeout(100000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "sort", "nonSignalSort.circom"));
    });

    it("sort([12,3,5,6,7,8,9,3,2,1,5,6])", async function () {
        await testSort([12n,3n,5n,6n,7n,8n,9n,3n,2n,1n,5n,6n], circuit);
    });

});


