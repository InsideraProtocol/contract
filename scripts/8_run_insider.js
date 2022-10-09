const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Insider = await hre.ethers.getContractFactory("Insider");

  let insider = await Insider.attach(process.env.INSIDER_CONTRACT);

  //----------->add address

  await insider.setChainLinkContract(process.env.CHAIN_LINK_CONTRACT);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
