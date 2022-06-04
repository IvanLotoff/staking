import { expect } from "chai";
import { ethers } from "hardhat";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { RewardToken } from "../typechain";
import { Staking } from "../typechain";
import { LpToken } from "../typechain";


describe("Staking", function () {
  let owner: SignerWithAddress;
  let john: SignerWithAddress;
  let nick: SignerWithAddress;
  let pmknToken: RewardToken;
  let staking: Staking;
  let lpToken: LpToken;
  
  beforeEach("Staking",async function () {
    const initialLpAmount = 1000;
    const Staking = await ethers.getContractFactory("Staking");
    const PmknToken = await ethers.getContractFactory("RewardToken");
    const LpToken = await ethers.getContractFactory("LpToken");
    lpToken = await LpToken.deploy();
    [owner, john, nick] = await ethers.getSigners();
    await Promise.all([
        lpToken.mint(owner.address, initialLpAmount),
        lpToken.mint(john.address, initialLpAmount),
        lpToken.mint(nick.address, initialLpAmount)
    ]);
    pmknToken = await PmknToken.deploy();
    staking = await Staking.deploy(lpToken.address, pmknToken.address);

    });

  it("no approved stake", async ()=> {
    await expect(staking.connect(john).stake(100)).to.be.reverted;
  })
  
  it("successful stake", async ()=> {
    await lpToken.connect(john).approve(staking.address, 100);
    await expect(staking.connect(john).stake(100));
    await expect(staking.connect(john).stake(100)).to.be.reverted;
  })

  it("emit stake event", async ()=> {
    await lpToken.connect(john).approve(staking.address, 100);
    await expect(staking.connect(john).stake(100))
    .to.emit(staking, "Stake")
    .withArgs(john.address, 100);
  })

  it("change reward share", async ()=> {
    await expect(staking.connect(john).setLockTime(10)).to.be.reverted;
    await staking.setLockTime(10);
    expect(await staking.lockTime()).to.eq(10);
  })

  it("empty unstake", async ()=> {
    await expect(staking.connect(john).unstake()).to.be.reverted;
  })

  it("immediate unstake", async ()=> {
    await lpToken.connect(john).approve(staking.address, 100);
    await expect(staking.connect(john).stake(100));
    await expect(staking.connect(john).unstake()).to.be.reverted;
  })

  it("successful unstake", async ()=> {
    const initialBalance = await lpToken.balanceOf(john.address);
    await lpToken.connect(john).approve(staking.address, 100);
    await expect(staking.connect(john).stake(100));
    await expect(staking.connect(john).unstake()).to.be.reverted;
    await ethers.provider.send("evm_increaseTime", [20 * 60 * 60 + 1]); 
    await ethers.provider.send("evm_mine", []);
    await staking.connect(john).unstake();
    expect(await lpToken.balanceOf(john.address)).to.eq(initialBalance);
  })

})
