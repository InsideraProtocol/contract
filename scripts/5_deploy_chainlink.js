const hre = require("hardhat");
async function main() {
  const VRFv2Consumer = await hre.ethers.getContractFactory("VRFv2Consumer");
  const vRFv2Consumer = await VRFv2Consumer.deploy(
    process.env.SUBSCRIPTION_ID,
    process.env.ACCESS_RESTRICTION_CONTRACT
  );

  await vRFv2Consumer.deployed();

  console.log(`chainLink deployed to ${vRFv2Consumer.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
