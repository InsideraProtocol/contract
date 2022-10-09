const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Insider = await hre.ethers.getContractFactory("Insider");

  console.log("Deploying insider...");

  const accessRestrictionAddress = "0xe0043e8185edb790BF2936e24C2067766F903678";

  const insider = await upgrades.deployProxy(
    Insider,
    [accessRestrictionAddress],
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
