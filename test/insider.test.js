const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

const { ethers, upgrades } = require("hardhat");

const assert = require("chai").assert;
require("chai").use(require("chai-as-promised")).should();

describe("Insider", async () => {
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

  it("test createRoom", async () => {
    let { account1, account2, account3, account4, account5, insiderInstance } =
      await loadFixture(handleDeploymentsAndSetAddress);

    const method = 1;

    await insiderInstance.connect(account2).createRoom(method);

    const room = await insiderInstance.rooms(1);

    assert.equal(room.insider, account2.address, "insider is incorrect");
    assert.equal(Number(room.method), method, "method is incorrect");
  });

  it("test joinVolunteers", async () => {
    let {
      account1,
      account2,
      account3,
      account4,
      account5,
      account6,
      insiderInstance,
    } = await loadFixture(handleDeploymentsAndSetAddress);

    const method = 1;
    const roomId = 1;

    await insiderInstance.connect(account2).createRoom(method);
    // joinVolunteers;

    //1st volunteers join
    await insiderInstance.connect(account3).joinVolunteers(roomId);

    assert.equal(
      await insiderInstance.getRoomVolunteers(roomId, 0),
      account3.address,
      "first volunteer is incorrect"
    );

    //2nd volunteers join
    await insiderInstance.connect(account4).joinVolunteers(roomId);

    assert.equal(
      await insiderInstance.getRoomVolunteers(roomId, 1),
      account4.address,
      "2nd volunteer is incorrect"
    );

    //3rd volunteers join
    await insiderInstance.connect(account5).joinVolunteers(roomId);

    assert.equal(
      await insiderInstance.getRoomVolunteers(roomId, 2),
      account5.address,
      "3rd volunteer is incorrect"
    );

    const roomBeforeStart = await insiderInstance.rooms(roomId);

    assert.equal(Number(roomBeforeStart.status), 0);

    //4th volunteers join
    await insiderInstance.connect(account6).joinVolunteers(roomId);

    assert.equal(
      await insiderInstance.getRoomVolunteers(roomId, 3),
      account6.address,
      "4th volunteer is incorrect"
    );

    const addresses = [
      account3.address,
      account4.address,
      account5.address,
      account6.address,
    ];

    const roomAfterStart = await insiderInstance.rooms(roomId);

    assert.equal(Number(roomAfterStart.status), 1);

    const transferData1 = await insiderInstance.getRoomTransferData(roomId, 0);
    const transferData2 = await insiderInstance.getRoomTransferData(roomId, 1);

    assert.isTrue(addresses.includes(transferData1.sender));
    assert.isTrue(addresses.includes(transferData1.receiver));
    assert.isTrue(addresses.includes(transferData2.sender));
    assert.isTrue(addresses.includes(transferData2.receiver));
  });

  it("test joinVolunteers", async () => {
    let {
      account1,
      account2,
      account3,
      account4,
      account5,
      account6,
      insiderInstance,
      accessRestrictionInstance,
    } = await loadFixture(handleDeploymentsAndSetAddress);

    const method = 1;
    const roomId = 1;
    const ipfsHash = "ipfsHash";
    const senderIpfsHash = "senderIpfsHash";
    const receiverVerifyIpfsHash = "receiverVerifyIpfsHash";
    await insiderInstance.connect(account2).createRoom(method);

    const roomData = await insiderInstance.rooms(roomId);

    //1st volunteers join
    await insiderInstance.connect(account3).joinVolunteers(roomId);

    //2nd volunteers join
    await insiderInstance.connect(account4).joinVolunteers(roomId);

    //3rd volunteers join
    await insiderInstance.connect(account5).joinVolunteers(roomId);

    //4th volunteers join
    await insiderInstance.connect(account6).joinVolunteers(roomId);

    const accounts = [account3, account4, account5, account6];

    let transferData1 = await insiderInstance.getRoomTransferData(roomId, 0);
    let transferData2 = await insiderInstance.getRoomTransferData(roomId, 1);

    let receiver1 = accounts.filter((it) => {
      return it.address == transferData1.receiver;
    })[0];

    let sender1 = accounts.filter((it) => {
      return it.address == transferData1.sender;
    })[0];

    let receiver2 = accounts.filter((it) => {
      return it.address == transferData2.receiver;
    })[0];

    let sender2 = accounts.filter((it) => {
      return it.address == transferData2.sender;
    })[0];

    await insiderInstance
      .connect(receiver1)
      .receiverUploadHash(roomId, ipfsHash);

    const transferData1AfterReceiverUploadHash =
      await insiderInstance.getRoomTransferData(roomId, 0);

    assert.equal(
      transferData1AfterReceiverUploadHash.receiverAccountHash,
      ipfsHash
    );

    assert.equal(Number(transferData1AfterReceiverUploadHash.status), 1);

    await insiderInstance
      .connect(receiver1)
      .receiverUploadHash(roomId, ipfsHash)
      .should.be.rejectedWith("hash already exist");

    await insiderInstance
      .connect(sender1)
      .senderUploadHash(roomId, senderIpfsHash);

    const transferData1AfterSenderUploadHash =
      await insiderInstance.getRoomTransferData(roomId, 0);

    assert.equal(Number(transferData1AfterSenderUploadHash.status), 2);
    assert.equal(
      transferData1AfterSenderUploadHash.senderTxHash,
      senderIpfsHash
    );

    await insiderInstance
      .connect(sender1)
      .senderUploadHash(roomId, senderIpfsHash)
      .should.be.rejectedWith("pending to receiver");

    await insiderInstance
      .connect(receiver1)
      .receiverVerifyTx(roomId, receiverVerifyIpfsHash);

    const transferData1AfterReceiverVerifyTx =
      await insiderInstance.getRoomTransferData(roomId, 0);

    assert.equal(Number(transferData1AfterReceiverVerifyTx.status), 3);
    assert.equal(
      transferData1AfterReceiverVerifyTx.recieverAccountHashForInsider,
      receiverVerifyIpfsHash
    );

    await insiderInstance
      .connect(receiver1)
      .receiverVerifyTx(roomId, receiverVerifyIpfsHash)
      .should.be.rejectedWith("pending to sender");

    await insiderInstance
      .connect(account3)
      .checkTxByInsider(roomId, 0, true)
      .should.be.rejectedWith("sender is not room insider");

    await insiderInstance.connect(account2).checkTxByInsider(roomId, 0, true);

    await insiderInstance
      .connect(account2)
      .checkTxByInsider(roomId, 0, true)
      .should.be.rejectedWith("not verified by receiver");

    const transferData1AfterTxCheckedByInsider =
      await insiderInstance.getRoomTransferData(roomId, 0);

    assert.equal(Number(transferData1AfterTxCheckedByInsider.status), 4);
    assert.equal(transferData1AfterTxCheckedByInsider.insiderAnswer, true);

    await insiderInstance
      .connect(receiver1)
      .verifyInsiderByReceiver(roomId, true);

    const roomAfterVerify = await insiderInstance.rooms(roomId);
    assert.equal(Number(roomAfterVerify.insiderScore), 1);
    assert.equal(Number(roomAfterVerify.status), 1);

    await insiderInstance
      .connect(receiver1)
      .verifyInsiderByReceiver(roomId, true)
      .should.be.rejectedWith("pending to insider");

    //////////////////////////////////// -------------- transferData2
    const ipfsHash2 = "ipfsHash2";
    const senderIpfsHash2 = "senderIpfsHash2";
    const receiverVerifyIpfsHash2 = "receiverVerifyIpfsHash2";

    await insiderInstance
      .connect(receiver2)
      .receiverUploadHash(roomId, ipfsHash2);

    const transferData2AfterReceiverUploadHash =
      await insiderInstance.getRoomTransferData(roomId, 1);

    assert.equal(
      transferData2AfterReceiverUploadHash.receiverAccountHash,
      ipfsHash2
    );

    assert.equal(Number(transferData2AfterReceiverUploadHash.status), 1);

    await insiderInstance
      .connect(sender2)
      .senderUploadHash(roomId, senderIpfsHash2);

    const transferData2AfterSenderUploadHash =
      await insiderInstance.getRoomTransferData(roomId, 1);

    assert.equal(Number(transferData2AfterSenderUploadHash.status), 2);
    assert.equal(
      transferData2AfterSenderUploadHash.senderTxHash,
      senderIpfsHash2
    );

    await insiderInstance
      .connect(receiver2)
      .receiverVerifyTx(roomId, receiverVerifyIpfsHash2);

    const transferData2AfterReceiverVerifyTx =
      await insiderInstance.getRoomTransferData(roomId, 1);

    assert.equal(Number(transferData2AfterReceiverVerifyTx.status), 3);
    assert.equal(
      transferData2AfterReceiverVerifyTx.recieverAccountHashForInsider,
      receiverVerifyIpfsHash2
    );

    await insiderInstance.connect(account2).checkTxByInsider(roomId, 1, true);

    const transferData2AfterTxCheckedByInsider =
      await insiderInstance.getRoomTransferData(roomId, 1);

    assert.equal(Number(transferData2AfterTxCheckedByInsider.status), 4);
    assert.equal(transferData2AfterTxCheckedByInsider.insiderAnswer, true);

    await insiderInstance
      .connect(receiver2)
      .verifyInsiderByReceiver(roomId, true)
      .should.be.rejectedWith("Caller not insider contract");

    const INSIDER_PROTOCOL_CONTRACT_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("INSIDER_PROTOCOL_CONTRACT_ROLE")
    );

    await accessRestrictionInstance.grantRole(
      INSIDER_PROTOCOL_CONTRACT_ROLE,
      insiderInstance.address
    );
    assert.equal(Number(await insiderInstance.insiders(roomData.insider)), 0);

    assert.equal(
      await accessRestrictionInstance.isInsider(roomData.insider),
      false
    );

    await insiderInstance
      .connect(receiver2)
      .verifyInsiderByReceiver(roomId, true);

    const roomAfterVerify2 = await insiderInstance.rooms(roomId);
    assert.equal(Number(roomAfterVerify2.insiderScore), 2);
    assert.equal(Number(roomAfterVerify2.status), 3);

    assert.equal(
      await accessRestrictionInstance.isInsider(roomData.insider),
      true
    );

    assert.equal(
      Number(await insiderInstance.insiders(roomData.insider)),
      method
    );
  });
});
