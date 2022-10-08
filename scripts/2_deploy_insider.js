const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Insider = await hre.ethers.getContractFactory("Insider");

  console.log("Deploying insider...");

  const accessRestrictionAddress = "0xa513e6e4b8f2a923d98304ec87f64353c4d5c853";

  const insider = await upgrades.deployProxy(
    Insider,
    [accessRestrictionAddress],
    {
      kind: "uups",
      initializer: "initialize",
    },
  );

  await insider.deployed();

  console.log("insider deployed to:", insider.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
