const hre = require("hardhat");
async function main() {
  const MockDai = await hre.ethers.getContractFactory("MockDai");
  const mockDai = await MockDai.deploy("MockDai", "mockDai");

  await mockDai.deployed();

  console.log(`MockDai deployed to ${mockDai.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
