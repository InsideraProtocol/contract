const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Insider = await hre.ethers.getContractFactory("Insider");

  console.log("Deploying insider...");

  const insider = await upgrades.deployProxy(
    Insider,
    [process.env.ACCESS_RESTRICTION_CONTRACT],
    {
      kind: "uups",
      initializer: "initialize",
    }
  );

  await insider.deployed();

  console.log("insider deployed to:", insider.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
