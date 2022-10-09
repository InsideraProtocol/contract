const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Push = await hre.ethers.getContractFactory("Push");

  let pushAddress = "0xEa2c54dabB8d716F63e64a75Aa90Af9a9A237FC6";

  let push = await Push.attach(pushAddress);

  //----------->add address

  await push.pu();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
