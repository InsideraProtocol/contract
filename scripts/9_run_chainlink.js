const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const VRFv2Consumer = await hre.ethers.getContractFactory("VRFv2Consumer");

  let vRFv2Consumer = await VRFv2Consumer.attach(
    process.env.CHAIN_LINK_CONTRACT
  );

  //----------->add address

  await vRFv2Consumer.setInsiderContract(process.env.INSIDER_CONTRACT);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
