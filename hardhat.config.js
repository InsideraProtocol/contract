require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    localhost: { url: "http://127.0.0.1:8545" },
    // rinkeby: {
    //   url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID1}`,
    //   accounts: [process.env.DEPLOYER_PRIVAE_KEY1],
    //   chainId: 4,
    //   // gas: 6700000,
    //   // gasPrice: 10000000000,
    //   timeoutBlocks: 200,
    // },
    // mumbai: {
    //   url: "https://rpc-mumbai.maticvigil.com/v1/1d9f7ef426dc3e921f0665d825e2e30bedae8b5d",
    //   accounts: [process.env.DEPLOYER_PRIVAE_KEY1],
    //   chainId: 80001,
    //   confirmations: 2,
    //   timeoutBlocks: 500,
    // },
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
