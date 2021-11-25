// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CreatorToken.sol";

contract BuddyFactory is Initializable {

    IERC20 public buddyToken;
    uint256 public reserveRatio;
    
    mapping(address => address) public creators;
    mapping(address => address) public tokens;

    address public owner;
    address public platformFeeAddress;
    uint256 public platformFeePercent10000;
    uint32 private next_event_id;


    event NewCreator(
        uint32 event_id,
        address creator,
        address token,
        string name,
        string symbol,

        uint32  reward_percent // 0-10000
    );

    function initialize(IERC20 _buddyToken, uint256 _reserveRatio)
        public
        initializer
    {
        buddyToken = _buddyToken;
        reserveRatio = _reserveRatio;
        next_event_id = 0;
        platformFeeAddress = msg.sender;
        owner = msg.sender;
        platformFeePercent10000 = 100;
    }

    function newCreatorToken(string memory _name, string memory _symbol, uint32 _reward_percent)
        public
        returns (IERC20)
    {
        require(creators[msg.sender] == address(0), "invalid creator");
        IERC20 token = new CreatorToken(
            _name,
            _symbol,
            buddyToken,
            reserveRatio,
            msg.sender,
            _reward_percent,
            this
        );
        creators[msg.sender] = address(token);
        tokens[address(token)] = msg.sender;
        emit NewCreator(next_event_id++, msg.sender, address(token), _name, _symbol, _reward_percent);

        return token;
    }

    function getCreatorToken(address creator) public view returns (address) {
        return creators[creator];
    }

    function getTokenCreator(address token) public view returns (address) {
        return tokens[token];
    }


    function changeOwner(address _newOwner) public {
        require(msg.sender == owner);

        owner = _newOwner;
    }

    function setPlatformFeePercent(uint256 _percent10000) public{
        require(msg.sender == owner);
        require(_percent10000>=0 && _percent10000<=10000);

        platformFeePercent10000 = _percent10000;
    }

    function setPlatformFeeAddress(address _newPlatformFeeAddress) public {
        require(msg.sender == owner);

        platformFeeAddress = _newPlatformFeeAddress;
    }

    function transferBT(address recipient, uint256 amount) public returns(bool) {
        require(msg.sender == owner);

        return buddyToken.transfer(recipient, amount);
    }

}
