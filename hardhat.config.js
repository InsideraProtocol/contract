require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    localhost: { url: "http://127.0.0.1:8545" },
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com/v1/1d9f7ef426dc3e921f0665d825e2e30bedae8b5d",
      accounts: [
        process.env.PRIVATE_KEY,
        process.env.INSIDER_KEY,
        process.env.WITNESS1_KEY,
        process.env.WITNESS2_KEY,
        process.env.WITNESS3_KEY,
        process.env.WITNESS4_KEY,
      ],
      chainId: 80001,
      confirmations: 2,
      timeoutBlocks: 500,
    },
  },
  solidity: {
    version: "0.8.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
