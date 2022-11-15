const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber} = require("@ethersproject/bignumber");

describe("Greeter", function () {
  it("Should calculate current rewards of staker", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Ecto = await ethers.getContractFactory("Ectoplasm20");
    const ecto = await Ecto.deploy();
    const Lab = await ethers.getContractFactory("ResearchLab");
    const lab = await Lab.deploy();
    await lab.init(ecto.address, owner.address, owner.address);
    const LabBunnies = await ethers.getContractFactory("LabBunnies");
    const labBunnies = await LabBunnies.deploy(ecto.address, lab.address, 200, "QmevA6QiWHtd2jkCpgtzKUsFm4VDRTqxrDmDj1Ssirv1wM");
    
    await labBunnies.flipPauseStatus();
    await labBunnies.flipBreedingPauseStatus();

    let rounds = 3;

    await ecto.approve(labBunnies.address, ecto.totalSupply());

    await labBunnies.mint(rounds);
    
    for(let i = 1; i <= rounds; i++){
      console.log(i + ":" + await labBunnies.getTokenImage(i));
      console.log(await labBunnies.tokenURI(i));
    }
    
    await network.provider.send("evm_increaseTime", [1296000]);
    await network.provider.send("evm_mine"); 

    /*
    await labBunnies.mint(1);
    console.log(await labBunnies.tokenURI(rounds++));
    await labBunnies.mint(1);
    console.log(await labBunnies.tokenURI(rounds++));
    await labBunnies.mint(1);
    console.log(await labBunnies.tokenURI(rounds++));

    await network.provider.send("evm_increaseTime", [1296000]);
    await network.provider.send("evm_mine");
    
    await labBunnies.mint(1);
    console.log(await labBunnies.tokenURI(rounds++));
    await labBunnies.mint(1);
    console.log(await labBunnies.tokenURI(rounds++));
    await labBunnies.mint(1);
    console.log("Last" + await labBunnies.tokenURI(rounds++));

    await labBunnies.breeding(1,2);
    console.log(await labBunnies.tokenURI(rounds++));

    await network.provider.send("evm_increaseTime", [1296000]);
    await network.provider.send("evm_mine");

    await labBunnies.breeding(1,2);
    console.log(await labBunnies.tokenURI(rounds++));

    await network.provider.send("evm_increaseTime", [1296000]);
    await network.provider.send("evm_mine");

    await lab.setMiningAddress(labBunnies.address);

    await labBunnies.claim(0, 1);

    for(let i = 0; i < 29; i++){
      await network.provider.send("evm_increaseTime", [1296000]);
      await network.provider.send("evm_mine");
      await labBunnies.claim(0, 1);
    }
    
    await network.provider.send("evm_increaseTime", [1296000]);
    await network.provider.send("evm_mine");

    await labBunnies.setClaimsPerCarrotPercent(200);

    await labBunnies.recharge(1, 1);+

    console.log("RECHARGED");

    for(let i = 0; i < 6; i++){
      await network.provider.send("evm_increaseTime", [1296000]);
      await network.provider.send("evm_mine");
      await labBunnies.claim(0, 1);
    }

    await labBunnies.addToTransferBlacklist(2);
    const tx = await labBunnies.transferFrom(owner.address, addr1.address, 2);
    console.log(tx);
    console.log(owner.address);

    */
    //await labBunnies.mintTest(100);
    //await labBunnies.setTokenImage("ipfs://QmevA6QiWHtd2jkCpgtzKUsFm4VDRTqxrDmDj1Ssirv1wM/1.png", 1);
    /*console.log(await labBunnies.setTokenImage("ipfs://QmevA6QiWHtd2jkCpgtzKUsFm4VDRTqxrDmDj1Ssirv1wM/2.png", 1));
    console.log(await labBunnies.setTokenImage("ipfs://QmevA6QiWHtd2jkCpgtzKUsFm4VDRTqxrDmDj1Ssirv1wM/3.png", 2));
    console.log(await labBunnies.setTokenImage("ipfs://QmevA6QiWHtd2jkCpgtzKUsFm4VDRTqxrDmDj1Ssirv1wM/4.png", 3));
    console.log(await labBunnies.setTokenImage("ipfs://QmevA6QiWHtd2jkCpgtzKUsFm4VDRTqxrDmDj1Ssirv1wM/5.png", 4));
    console.log(await labBunnies.setTokenImage("ipfs://QmevA6QiWHtd2jkCpgtzKUsFm4VDRTqxrDmDj1Ssirv1wM/6.png", 5));
    console.log(await labBunnies.setTokenImage("ipfs://QmevA6QiWHtd2jkCpgtzKUsFm4VDRTqxrDmDj1Ssirv1wM/7.png", 6));
    */
    //const ownerBalance = await labBunnies.balanceOf(owner.address);
    //console.log("Balance of owner: " + ownerBalance.toString());
    //const ownerEthBalance = await owner.getBalance();
    //console.log("Balance: " + ownerEthBalance.toString());
    //const Staking = await ethers.getContractFactory("DanaStaking");
    //const staking = await Staking.deploy(dana.address);
    //await staking.deployed();
    //const decimals = 18;
    //const input = 200;
    //const amount = BigNumber.from(input).mul(BigNumber.from(10).pow(decimals));
    //const balanceToDeposit = BigNumber.from(ownerBalance).sub(amount);
    //const approved = await dana.approve(owner.address, amount);
    //const depositedFunds = await staking.depositFunds(balanceToDeposit);
    //console.log("Funds deposited: " + depositedFunds);
    //const startStaking = await staking.stakeTest(amount, true, "twoMonths");
    // console.log("Balance trasnferred to contract: " + startStaking.toString());
    // await network.provider.send("evm_increaseTime", [345600]);
    // await network.provider.send("evm_mine"); 
    // const rewardsMid = await staking.calculateRewardsTest(owner.address);
    // console.log("Rewards at 4 days:" + rewardsMid);
    // await network.provider.send("evm_increaseTime", [1209600]);
    // await network.provider.send("evm_mine");
    // const rewardsFinal = await staking.calculateRewardsTest(owner.address);
    // console.log("Rewards after 19 days since last call:" + rewardsFinal);
    // await staking.stopCompound();
    // await network.provider.send("evm_increaseTime", [86400]);
    // await network.provider.send("evm_mine"); 
    // const rewardsStopped = await staking.calculateRewardsTest(owner.address);
    // console.log("Rewards since compound stopped 20 days:" + rewardsStopped);
    // await network.provider.send("evm_increaseTime", [777600]);
    // await network.provider.send("evm_mine"); 
    // const rewardsStopped2 = await staking.calculateRewardsTest(owner.address);
    // console.log("Rewards since compound stopped 29 days:" + rewardsStopped2);
    // await network.provider.send("evm_increaseTime", [345600]);
    // await network.provider.send("evm_mine");
    // const rewardsStopped33 = await staking.calculateRewardsTest(owner.address);
    // console.log("Rewards since compound stopped 33 days:" + rewardsStopped33);
    // await network.provider.send("evm_increaseTime", [4838400]);
    // await network.provider.send("evm_mine");
    // const rewardsStopped89 = await staking.calculateRewardsTest(owner.address);
    // console.log("Rewards since compound stopped 89 days:" + rewardsStopped89);
    // const rewardsClaimed = await staking.claim();
    // console.log("Rewards claimed:" + rewardsClaimed.toString());
    // const rewardsAfterClaim = await staking.calculateRewardsTest(owner.address);
    // console.log("Rewards after claim:" + rewardsAfterClaim);
    // const stakeWithdrawn = await staking.withdraw(amount);
    // console.log("Stake withdrawm:" + stakeWithdrawn.toString());
    // const fundsWithdrawn = await staking.withdrawFunds(amount.mul(2));
    // console.log("Funds Withdrawn:" + fundsWithdrawn.toString());
    // const fundsWithdrawnRest = await staking.withdrawAllFunds();
    // console.log("Funds Withdrawn:" + fundsWithdrawnRest.toString());
    // wait until the transaction is mined
    //await setGreetingTx.wait();
    //expect(await staking.greet()).to.equal("Hola, mundo!");
  });
});
