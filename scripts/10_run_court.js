const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Court = await hre.ethers.getContractFactory("Court");

  let court = await Court.attach(process.env.COURT_CONTRACT);

  //----------->add address

  await court.setGovernanceToken(process.env.GOVERNANCE_TOKEN);

  await court.setInsiderContract(process.env.INSIDER_CONTRACT);

  await court.setSoulboundContract(process.env.SOUL_BOUND_CONTRACT);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
