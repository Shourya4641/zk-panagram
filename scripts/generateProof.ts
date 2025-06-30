import { Noir } from "@noir-lang/noir_js";
import { ethers } from "ethers";
import { UltraHonkBackend } from "@aztec/bb.js";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

const currentScriptDirectory = path.dirname(fileURLToPath(import.meta.url));

const relativeCircuitPath = "../target/zk_panagram.json";

const circuitPath = path.resolve(currentScriptDirectory, relativeCircuitPath);

const circuitContent = fs.readFileSync(circuitPath, "utf-8");

const circuit = JSON.parse(circuitContent);

console.log(circuit.bytecode);

export default async function generateProof() {
  const inputArray = process.argv.slice(2);

  try {
    const noir = new Noir(circuit);
    await noir.init();

    const backend = new UltraHonkBackend(circuit.bytecode, { threads: 1 });

    const inputs = {
      guess_hash: inputArray[0],
      answer_hash: inputArray[1],
    };

    const { witness } = await noir.execute(inputs);

    const log = console.log;
    console.log = () => {};

    const { proof } = await backend.generateProof(witness, { keccak: true });

    console.log = log;

    const encodedProof = ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes"],
      [proof]
    );

    return encodedProof;
  } catch (error) {
    console.error("Error during proof generation:", error);
    throw error;
  }
}

(async () => {
  try {
    const proof = await generateProof();
    process.stdout.write(proof);
    process.exit(0);
  } catch (error) {
    console.error("Script execution failed.");
    process.exit(1);
  }
})();
