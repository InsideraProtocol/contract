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
    const [account1, account2, account3, account4, account5, account6] =
      await ethers.getSigners();

    const Court = await ethers.getContractFactory("Court", account1);

    const Insider = await ethers.getContractFactory("Insider", account1);

    const AccessRestriction = await ethers.getContractFactory(
      "AccessRestriction",
      account1
    );

    const Soulbound = await ethers.getContractFactory("Soulbound", account1);

    const MockDai = await ethers.getContractFactory("MockDai");
    const mockDaiInstance = await MockDai.deploy("MockDai", "mockDai");

    const accessRestrictionInstance = await upgrades.deployProxy(
      AccessRestriction,
      [account1.address],
      {
        kind: "uups",
        initializer: "initialize",
      }
    );

    const insiderInstance = await upgrades.deployProxy(
      Insider,
      [accessRestrictionInstance.address],
      {
        kind: "uups",
        initializer: "initialize",
      }
    );

    const soulboundInstance = await upgrades.deployProxy(
      Soulbound,
      [accessRestrictionInstance.address, "baseUri"],
      {
        kind: "uups",
        initializer: "initialize",
      }
    );

    const courtInstance = await upgrades.deployProxy(
      Court,
      [accessRestrictionInstance.address],
      {
        kind: "uups",
        initializer: "initialize",
      }
    );

    return {
      account1,
      account2,
      account3,
      account4,
      account5,
      account6,
      courtInstance,
      mockDaiInstance,
      insiderInstance,
      accessRestrictionInstance,
      soulboundInstance,
    };
  }

  it("test createCourt", async () => {
    let { account1, account2, account3, account4, account5, courtInstance } =
      await loadFixture(handleDeploymentsAndSetAddress);

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

  it("test setGovernanceToken", async () => {
    let { account1, account2, account3, account4, account5, courtInstance } =
      await loadFixture(handleDeploymentsAndSetAddress);

    const tokenAddress = account4.address;

    await courtInstance
      .connect(account2)
      .setGovernanceToken(tokenAddress)
      .should.be.rejectedWith("Caller not admin");

    await courtInstance.connect(account1).setGovernanceToken(tokenAddress);
    assert.equal(
      await courtInstance.governanceToken(),
      tokenAddress,
      "token address is incorrect"
    );
  });

  it("test stake", async () => {
    let {
      account1,
      account2,
      account3,
      account4,
      account5,
      courtInstance,
      mockDaiInstance,
    } = await loadFixture(handleDeploymentsAndSetAddress);
    const address1 = account4.address;
    const address2 = account5.address;
    const region = 1;
    const method = 1;
    const duration = 12 * 24 * 60 * 60;
    const coinPrice = ethers.utils.parseUnits("1", "ether");

    const stakeAmount = ethers.utils.parseUnits("10", "ether");

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
    await courtInstance
      .connect(account1)
      .setGovernanceToken(mockDaiInstance.address);

    await courtInstance
      .connect(account3)
      .stake(1, coinPrice)
      .should.be.rejectedWith("Insufficient stakeAmount");

    await courtInstance
      .connect(account3)
      .stake(1, stakeAmount)
      .should.be.rejectedWith("ERC20: insufficient allowance");

    await mockDaiInstance.setApprove(
      account3.address,
      courtInstance.address,
      stakeAmount
    );

    await courtInstance
      .connect(account3)
      .stake(1, stakeAmount)
      .should.be.rejectedWith("ERC20: transfer amount exceeds balance");

    await mockDaiInstance.setMint(account3.address, stakeAmount);

    await courtInstance.connect(account3).stake(1, stakeAmount);

    assert.equal(
      Number(await courtInstance.stakedAmount(1, account3.address)),
      Number(stakeAmount),
      "stakedAmount is incorrect"
    );

    await courtInstance
      .connect(account3)
      .stake(1, stakeAmount)
      .should.be.rejectedWith("already staked");
  });

  it("test voteGuardian", async () => {
    let {
      account1,
      account2,
      account3,
      account4,
      account5,
      courtInstance,
      mockDaiInstance,
    } = await loadFixture(handleDeploymentsAndSetAddress);
    const address1 = account4.address;
    const address2 = account5.address;
    const region = 1;
    const method = 1;
    const duration = 12 * 24 * 60 * 60;
    const coinPrice = ethers.utils.parseUnits("1", "ether");

    const stakeAmount = ethers.utils.parseUnits("10", "ether");

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
    await courtInstance
      .connect(account1)
      .setGovernanceToken(mockDaiInstance.address);

    await mockDaiInstance.setApprove(
      account3.address,
      courtInstance.address,
      stakeAmount
    );

    await mockDaiInstance.setMint(account3.address, stakeAmount);

    await courtInstance
      .connect(account3)
      .voteGuardian(1, 0)
      .should.be.rejectedWith("not staked");

    await courtInstance.connect(account3).stake(1, stakeAmount);

    await courtInstance.connect(account3).voteGuardian(1, 0);

    await courtInstance
      .connect(account3)
      .voteGuardian(1, 0)
      .should.be.rejectedWith("already voted.");

    const court = await courtInstance.courts(1);

    assert.equal(
      Number(court.address2VoteCount),
      0,
      "address2VoteCount is incorrect"
    );
    assert.equal(
      Number(court.address1VoteCount),
      1,
      "address1VoteCount is incorrect"
    );

    assert.equal(
      Number(await courtInstance.voters(1, account3.address)),
      1,
      "voters status is incorrect"
    );
    assert.equal(await courtInstance.voterListPerCourt(1, 0), account3.address);
  });

  it("test voteInsider", async () => {
    let {
      account1,
      account2,
      account3,
      account4,
      account5,
      courtInstance,
      mockDaiInstance,
      insiderInstance,
      accessRestrictionInstance,
    } = await loadFixture(handleDeploymentsAndSetAddress);
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

    await courtInstance
      .connect(account1)
      .setGovernanceToken(mockDaiInstance.address);

    await courtInstance.setInsiderContract(insiderInstance.address);

    const INSIDER_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("INSIDER_ROLE")
    );

    await accessRestrictionInstance.grantRole(INSIDER_ROLE, account3.address);

    await insiderInstance.joinInsider(region, method, account3.address);

    await courtInstance.connect(account3).voteInsider(1, 1);

    const court = await courtInstance.courts(1);

    assert.equal(
      Number(court.address2VoteCount),
      1,
      "address2VoteCount is incorrect"
    );

    assert.equal(
      Number(court.address1VoteCount),
      0,
      "address1VoteCount is incorrect"
    );

    assert.equal(
      Number(await courtInstance.voters(1, account3.address)),
      2,
      "voters status is incorrect"
    );

    assert.equal(await courtInstance.voterListPerCourt(1, 0), account3.address);
  });

  it("test settleCourt (unSettle)", async () => {
    let {
      account1,
      account2,
      account3,
      account4,
      account5,
      account6,
      courtInstance,
      mockDaiInstance,
      insiderInstance,
      accessRestrictionInstance,
    } = await loadFixture(handleDeploymentsAndSetAddress);
    const address1 = account5.address;
    const address2 = account6.address;
    const region = 1;
    const method = 1;
    const duration = 12 * 24 * 60 * 60;
    const coinPrice = ethers.utils.parseUnits("1", "ether");
    const ipfsData = "ipfs data";

    const stakeAmount = ethers.utils.parseUnits("10", "ether");

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

    await courtInstance
      .connect(account1)
      .setGovernanceToken(mockDaiInstance.address);

    await mockDaiInstance.setApprove(
      account3.address,
      courtInstance.address,
      stakeAmount
    );

    await mockDaiInstance.setMint(account3.address, stakeAmount);

    await courtInstance.connect(account3).stake(1, stakeAmount);

    await courtInstance.connect(account3).voteGuardian(1, 0);

    await courtInstance.setInsiderContract(insiderInstance.address);

    const INSIDER_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("INSIDER_ROLE")
    );

    await accessRestrictionInstance.grantRole(INSIDER_ROLE, account4.address);

    await insiderInstance.joinInsider(region, method, account4.address);

    await courtInstance.connect(account4).voteInsider(1, 1);

    const court = await courtInstance.courts(1);

    assert.equal(
      Number(court.address2VoteCount),
      1,
      "address2VoteCount is incorrect"
    );

    assert.equal(
      Number(court.address1VoteCount),
      1,
      "address1VoteCount is incorrect"
    );

    assert.equal(await courtInstance.voterListPerCourt(1, 0), account3.address);
    assert.equal(await courtInstance.voterListPerCourt(1, 1), account4.address);

    await time.increase(duration + 100);

    await courtInstance.settleCourt(1);

    const courtAfterSettlement = await courtInstance.courts(1);

    assert.equal(
      Number(courtAfterSettlement.status),
      2,
      "court status is incorrect"
    );

    await courtInstance.settleCourt(1).should.be.rejectedWith("court settled");
  });

  it("test settleCourt (address 1 is winner)", async () => {
    let {
      account1,
      account2,
      account3,
      account4,
      account5,
      account6,
      courtInstance,
      mockDaiInstance,
      insiderInstance,
      accessRestrictionInstance,
      soulboundInstance,
    } = await loadFixture(handleDeploymentsAndSetAddress);
    const address1 = account5.address;
    const address2 = account6.address;
    const region = 1;
    const method = 1;
    const duration = 12 * 24 * 60 * 60;
    const coinPrice = ethers.utils.parseUnits("1", "ether");
    const ipfsData = "ipfs data";

    const stakeAmount = ethers.utils.parseUnits("10", "ether");

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

    await courtInstance
      .connect(account1)
      .setGovernanceToken(mockDaiInstance.address);

    await mockDaiInstance.setApprove(
      account3.address,
      courtInstance.address,
      stakeAmount
    );

    await mockDaiInstance.setMint(account3.address, stakeAmount);

    await courtInstance.connect(account3).stake(1, stakeAmount);

    await courtInstance.connect(account3).voteGuardian(1, 0);

    const court = await courtInstance.courts(1);

    await courtInstance.setSoulboundContract(soulboundInstance.address);

    const INSIDER_PROTOCOL_CONTRACT_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("INSIDER_PROTOCOL_CONTRACT_ROLE")
    );

    await accessRestrictionInstance.grantRole(
      INSIDER_PROTOCOL_CONTRACT_ROLE,
      courtInstance.address
    );

    assert.equal(
      Number(court.address2VoteCount),
      0,
      "address2VoteCount is incorrect"
    );

    assert.equal(
      Number(court.address1VoteCount),
      1,
      "address1VoteCount is incorrect"
    );

    await time.increase(duration + 100);

    await courtInstance.settleCourt(1);

    const courtAfterSettlement = await courtInstance.courts(1);
    assert.equal(
      Number(courtAfterSettlement.status),
      3,
      "court status is incorrect"
    );

    assert.equal(await soulboundInstance.ownerOf(0), account5.address);
    assert.equal(await soulboundInstance.ownerOf(1), account6.address);

    const winnerAttribute = await soulboundInstance.attributes(0);
    const loserAttribute = await soulboundInstance.attributes(1);

    assert.equal(
      Number(winnerAttribute.courtId),
      1,
      "winner attr courtId is incorrect"
    );

    assert.equal(
      Number(winnerAttribute.status),
      0,
      "winner attr status is incorrect"
    );
    assert.equal(
      Number(loserAttribute.courtId),
      1,
      "loser attr courtId is incorrect"
    );
    assert.equal(
      Number(loserAttribute.status),
      1,
      "loser attr status is incorrect"
    );
  });
});
