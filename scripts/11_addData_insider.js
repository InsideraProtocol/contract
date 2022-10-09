const hre = require("hardhat");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const Insider = await hre.ethers.getContractFactory("Insider");

  let insider = await Insider.attach(process.env.INSIDER_CONTRACT);
  const [account1, account2, account3, account4, account5, account6] =
    await ethers.getSigners();

  //----------->add address

  const method = 1;

  // let tx = await insider.connect(account2).createRoom(method);
  // console.log(tx);

  // let tx = await insider
  //   .connect(account6)
  //   .joinWitness(3, { gasLimit: 1000000 });
  // console.log(tx);

  // const witness = await insider.chainLinkContract();
  // console.log(witness);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

//witness1 0xf8d44601cC610E44e324C016BfbC549e54953446
//witness2 0x4A0954f0AFF08A6Eab90873C1bd78E16949AC94A
//witness3 0x96D39394Af5f182Dc3ed7FB0b6973a3B0e8ddFcb
//witness4 0x434F8692EcF25124DC2CeEb23038cB3242162C33
