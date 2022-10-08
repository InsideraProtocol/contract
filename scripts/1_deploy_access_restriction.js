const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const AccessRestriction = await hre.ethers.getContractFactory(
    "AccessRestriction",
  );

  console.log("Deploying accessRestriction...");

  const accessRestriction = await upgrades.deployProxy(
    AccessRestriction,
    [process.env.ADMIN_ADDRESS],
    {
      kind: "uups",
      initializer: "initialize",
    },
  );

  await accessRestriction.deployed();

  console.log("accessRestriction deployed to:", accessRestriction.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
