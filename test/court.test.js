const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

const { ethers, upgrades } = require("hardhat");

const assert = require("chai").assert;
require("chai").use(require("chai-as-promised")).should();

describe("Court", async () => {
  const zeroAddress = "0x0000000000000000000000000000000000000000";

  async function handleDeploymentsAndSetAddress() {
    const [account1, account2, account3, account4, account5] =
      await ethers.getSigners();

    const Court = await ethers.getContractFactory("Court", account1);

    const courtInstance = await upgrades.deployProxy(Court, {
      kind: "uups",
      initializer: "initialize",
    });

    return {
      account1,
      account2,
      account3,
      account4,
      account5,
      courtInstance,
    };
  }

  it("test createCourt", async () => {
    let { account1, account2, account3, account4, account5, courtInstance } =
      await loadFixture(handleDeploymentsAndSetAddress);

    //-------------reject(only Owner)

    const address1 = account4.address;
    const address2 = account5.address;
    const region = 1;
    const method = 1;
    const duration = 12 * 24 * 60 * 60;
    const coinPrice = ethers.utils.parseUnits("1", "ether");
    const ipfsData = "ipfs data";

    await courtInstance
      .connect(account2)
      .createCourt(
        address1,
        address2,
        region,
        method,
        coinPrice,
        duration,
        ipfsData
      );

    const court = await courtInstance.courts(1);

    assert.equal(court.address1, address1, "");
    assert.equal(court.address2, address2, "");
    assert.equal(Number(court.region), region, "");
    assert.equal(Number(court.method), method, "");
    assert.equal(Number(court.coinPrice), Number(coinPrice), "");
    assert.equal(Number(court.duration), duration, "");
    assert.equal(court.ipfsData, ipfsData, "");
  });

  it.only("test setGovernanceToken", async () => {
    let { account1, account2, account3, account4, account5, courtInstance } =
      await loadFixture(handleDeploymentsAndSetAddress);

    //-------------reject(only Owner)

    const tokenAddress = account4.address;

    await courtInstance
      .connect(account2)
      .setGovernanceToken(tokenAddress)
      .should.be.rejectedWith("Ownable: caller is not the owner");

    await courtInstance.connect(account2).setGovernanceToken(tokenAddress);
  });
});
