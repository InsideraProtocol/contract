const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Court = await hre.ethers.getContractFactory("Court");

  let courtAddress = "0xd09FE5674b0bBec59821B9343F361C0627dE2049";
  let insiderContractAddress = "0x77A9B213c2CfCE61a4BA95AC50424D8BE8Fc5Bf8";
  let soulboundAddress = "0xFCe2FB75E40fC1bb718b5f32fdb13178F423906B";

  let court = await Court.attach(courtAddress);

  //----------->add address
  await court.setInsiderContract(insiderContractAddress);

  await court.setSoulboundContract(soulboundAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
