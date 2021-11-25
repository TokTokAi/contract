const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const web3 = require('web3');
const Social = artifacts.require('Social');

module.exports = async function (deployer) {
  const socialInstance = await deployProxy(Social, [], { deployer });
};
