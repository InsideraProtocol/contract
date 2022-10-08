const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Court = await hre.ethers.getContractFactory("Court");

  console.log("Deploying court...");

  const accessRestrictionAddress = "0xa513e6e4b8f2a923d98304ec87f64353c4d5c853";

  const court = await upgrades.deployProxy(Court, [accessRestrictionAddress], {
    kind: "uups",
    initializer: "initialize",
  });

  await court.deployed();

  console.log("court deployed to:", court.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
