const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const INSIDER_PROTOCOL_CONTRACT_ROLE = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("INSIDER_PROTOCOL_CONTRACT_ROLE")
  );

  const AccessRestriction = await hre.ethers.getContractFactory(
    "AccessRestriction"
  );

  let accessRestriction = await AccessRestriction.attach(
    process.env.ACCESS_RESTRICTION_CONTRACT
  );

  //-----------> grant Role
  await accessRestriction.grantRole(
    INSIDER_PROTOCOL_CONTRACT_ROLE,
    process.env.COURT_CONTRACT
  );

  await accessRestriction.grantRole(
    INSIDER_PROTOCOL_CONTRACT_ROLE,
    process.env.INSIDER_CONTRACT
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
