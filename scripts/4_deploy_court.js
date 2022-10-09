const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Court = await hre.ethers.getContractFactory("Court");

  console.log("Deploying court...");

  const accessRestrictionAddress = "0xe0043e8185edb790BF2936e24C2067766F903678";

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
