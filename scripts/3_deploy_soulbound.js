const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Soulbound = await hre.ethers.getContractFactory("Soulbound");

  console.log("Deploying soulbound...");

  const accessRestrictionAddress = "0xe0043e8185edb790BF2936e24C2067766F903678";
  const baseURI = "example";

  const soulbound = await upgrades.deployProxy(
    Soulbound,
    [accessRestrictionAddress, baseURI],
    {
      kind: "uups",
      initializer: "initialize",
    }
  );

  await soulbound.deployed();

  console.log("soulbound deployed to:", soulbound.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
