const BuddyFactory = artifacts.require("BuddyFactory");
const CreatorToken = artifacts.require("CreatorToken");
const TestERC20Token = artifacts.require("TestERC20Token");
const BN = require("bn.js");


contract("BuddyFactory", accounts => {

    // console.log(accounts);

    const ADMIN = accounts[0];
    const U1 = accounts[1];
    const U2 = accounts[2];

    async function sendGasFee(from, to, amount) {
        await web3.eth.sendTransaction({
            "from": from,
            "to": to,
            "value": amount
        });
        // console.log(result);
    }


    it("名人币", async () => {
        const factory = await BuddyFactory.deployed();
        const token = await TestERC20Token.deployed();



        await sendGasFee(ADMIN, U1, 100000000000000000000);

        // console.log(await web3.eth.getBalance(U1));

        await factory.newCreatorToken("CT1", "CT1", 200, { from: U1 });

        const u1token = await factory.getCreatorToken(U1);

        assert.equal(await factory.getTokenCreator(u1token), U1);
        await token.approve(u1token, "100000000000000000000000", { from: ADMIN })


        // 买入,卖出,确保名人币及测试币数量不变
        let contract = new web3.eth.Contract(CreatorToken.abi, u1token);
        
        let cost = new BN("10000000000000000000") // 10个币
        console.log(`${ADMIN} cost ${cost}`);
        let platformFeePercent = new BN("200");
        let platformFeeAddress = U2;
        console.log(`set platform fee percent ${platformFeePercent}`)
        await factory.setPlatformFeePercent(platformFeePercent, {from: ADMIN});
        console.log(`current platform fee percent ${await factory.platformFeePercent10000()}`)
        console.log(`set platform fee address ${platformFeeAddress}`)
        await factory.setPlatformFeeAddress(platformFeeAddress, {from: ADMIN});
        console.log(`current platform fee address ${await factory.platformFeeAddress()}`)
        
        let platformFeeShouldBe = cost * platformFeePercent / 10000;
        console.log(`platform fee should be ${platformFeeShouldBe}`);
        let platformfee = new BN(await contract.methods.calculatePlatformFee(cost).call());
        assert.equal(platformfee.toString(), platformFeeShouldBe.toString());

        let actual_exchange_bt = cost.sub(platformfee);
        console.log(`actually exchange ${actual_exchange_bt}`);

        
        let should_got = new BN(await contract.methods.calculateContinuousMintReturn(actual_exchange_bt.toString()).call());
        console.log(`should got ${should_got} CT`);
        let fund_creator_percent = await contract.methods.reward_percent().call();
        console.log(`fund reward percent ${fund_creator_percent} %00`);
        let to_creator = should_got.mul(new BN("200")).div(new BN("10000"));
        let to_sender = should_got.sub(to_creator);
        console.log(`finally should to creator ${to_creator} CT`);
        console.log(`finally should to sender ${to_sender} CT`);


        await contract.methods.mint(cost, should_got, "500").send({ from: ADMIN });
        assert.equal(await contract.methods.balanceOf(U1).call(), to_creator); // 2%
        assert.equal(await contract.methods.balanceOf(ADMIN).call(), to_sender); // 去除2%
        assert.equal((await token.balanceOf(U2)).toString(), platformfee.toString());
        

        console.log(`Selling ${to_sender} CT`);
        let willExchangeBT = await contract.methods.calculateContinuousBurnReturn(to_sender).call();
        console.log(`will get ${willExchangeBT} BT`);
        let burnPlatformFee =  new BN(await contract.methods.calculatePlatformFee(willExchangeBT).call());
        console.log(`${burnPlatformFee} as platform fee`);
        let acutalExchangedBTShouldBe = willExchangeBT.sub(burnPlatformFee);

        console.log(`actually will get ${acutalExchangedBTShouldBe} BT`);
        
        await contract.methods.burn(to_sender, willExchangeBT, "500").send({ from: ADMIN })

        assert.equal((await token.balanceOf(U2)).toString(), platformfee.add(burnPlatformFee).toString()); // 相对花费会少1,将误差损耗放在token这边
        // await contract.methods.burn(to_sender, "9999745365489247142", "500").send({ from: ADMIN });
    })
})