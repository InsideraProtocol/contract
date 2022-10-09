const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Court = await hre.ethers.getContractFactory("Court");

  console.log("Deploying court...");

  const court = await upgrades.deployProxy(
    Court,
    [process.env.ACCESS_RESTRICTION_CONTRACT],
    {
      kind: "uups",
      initializer: "initialize",
    }
  );

  await court.deployed();

  console.log("court deployed to:", court.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
