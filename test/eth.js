const { assert, log } = require("console");
const path = require("path");
const fs = require('fs');
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

async function testEthAddr(input1, input2, circuit){


    const w = await circuit.calculateWitness({in: [bigintToArray(64, 4,input1), bigintToArray(64, 4, input2)]}, true);

    let circuit_result = w.slice(1, 1+1).join("");

    real_result = 341387108538807672739838887701090094225924754711n

    assert(circuit_result == real_result, `${real_result} != ${circuit_result}`);
}

describe("Eth addr from pub test", function () {

    this.timeout(10000000);
    let circuit;

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "eth", "eth.circom"));
    });

   
    it("Eth addr from pub(52998851949074665569915962708831544046706035742159923591431460742897172595126; 38313223394552538998639807107003002404426096331086715999893772380695643434224)", async function () {
        await testEthAddr(
            52998851949074665569915962708831544046706035742159923591431460742897172595126n, 38313223394552538998639807107003002404426096331086715999893772380695643434224n, circuit);
    })

});