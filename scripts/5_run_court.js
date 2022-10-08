const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Court = await hre.ethers.getContractFactory("Court");

  let courtAddress = "0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82";
  let insiderContractAddress = "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318";
  let soulboundAddress = "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e";

  let court = await Court.attach(courtAddress);

  //----------->add address
  await court.setInsiderContract(insiderContractAddress);

  await court.setSoulboundContract(soulboundAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
