const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Soulbound = await hre.ethers.getContractFactory("Soulbound");

  console.log("Deploying soulbound...");

  const baseURI = "example";

  const soulbound = await upgrades.deployProxy(
    Soulbound,
    [process.env.ACCESS_RESTRICTION_CONTRACT, baseURI],
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
