// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20Token is ERC20 {
    constructor() ERC20("Buddy Token", "BUDDY") {
        _mint(msg.sender, 10000*10**18);
    }
}
