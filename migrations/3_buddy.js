const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const web3 = require('web3');
const TestERC20Token = artifacts.require('TestERC20Token');
const BuddyFactory = artifacts.require('BuddyFactory');
const BN = require("bn.js");

module.exports = async function (deployer) {
  
  await deployer.deploy(TestERC20Token);



  await deployProxy(BuddyFactory, [TestERC20Token.address, 333333], { deployer });
};
