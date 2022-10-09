const hre = require("hardhat");
async function main() {
  console.log("Deploying mockDai...");

  const Push = await hre.ethers.getContractFactory("Push");
  const push = await Push.deploy();

  await push.deployed();

  console.log(`push deployed to ${push.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
