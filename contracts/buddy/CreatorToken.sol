// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./TokenPriceCurve.sol";
import "./BuddyFactory.sol";

contract CreatorToken is TokenPriceCurve, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ContinuousMint(uint32 event_id, address user, uint256 amount, uint256 depositAmount, uint256 currentPrice);
    event FundCreator(uint32 event_id, address user, address creator, uint256 amount);
    event ContinuousBurn(uint32 event_id, address user, uint256 amount, uint256 reimburseAmount, uint256 currentPrice);
    event RewardPercent(uint32 event_id, uint256 percent);
    event TransferLog(uint32 event_id, address from, address to, uint256 amount);

    uint32 private next_event_id;

    IERC20 public platformToken;

    uint256 public scale = 10**18;

    uint256 public reserveBalance = 1*scale/100000;
    uint256 public reserveRatio;
    uint32 public reward_percent;
    address public creator;
    BuddyFactory factory;

    constructor(
        string memory _name,
        string memory _symbol,
        IERC20 _platformToken,
        uint256 _reserveRatio, 
        address _creator,
        uint32 _reward_percent,
        BuddyFactory _factroy
    ) ERC20(_name, _symbol) {
        platformToken = _platformToken;
        reserveRatio = _reserveRatio;
        _mint(msg.sender, 1*scale / 100); 

        next_event_id = 0;
        creator = _creator;
        reward_percent = _reward_percent;
        factory = _factroy;
    }


    function setRewardPercent(uint32 _percent) public {
        require(msg.sender == creator);
        require(_percent >= 0 && _percent <=10000);
        reward_percent = _percent;
        emit RewardPercent(next_event_id++, _percent);
    }


    function getRewardPercent() public view returns(uint32) {
        return reward_percent;
    }

    function mint(uint256 _amount, uint256 _expect_exchange_amount, uint256 _slippage_allow_in_10000) public {

        require(_amount > 0);

        uint256 platformFee = calculatePlatformFee(_amount);
        _amount = _amount - platformFee;


        uint256 actually_exhanged_amount = calculateContinuousMintReturn(_amount);
        if (actually_exhanged_amount < _expect_exchange_amount) {
            uint256 slippage_allow_amount = _expect_exchange_amount.mul(_slippage_allow_in_10000).div(10000);
            require(_expect_exchange_amount.sub(actually_exhanged_amount) <= slippage_allow_amount, "meet slippage");
        }

        platformToken.safeTransferFrom(msg.sender, address(this), _amount);
        platformToken.safeTransferFrom(msg.sender, factory.platformFeeAddress(), platformFee);
        _continuousMint(_amount);
    }

    function getCurrentPrice() public view returns (uint256){
        return 30 * totalSupply() / (10 ** decimals()) * totalSupply();
    }

    function burn(uint256 _amount, uint256 _expect_exchange_amount, uint256 _slippage_allow_in_10000) public {

        uint256 actually_exhanged_amount = calculateContinuousBurnReturn(_amount);
        if (actually_exhanged_amount < _expect_exchange_amount) {
            uint256 slippage_allow_amount = _expect_exchange_amount.mul(_slippage_allow_in_10000).div(10000);
            require(_expect_exchange_amount.sub(actually_exhanged_amount) <= slippage_allow_amount, "meet slippage");
        }

        uint256 returnAmount = _continuousBurn(_amount);
        uint256 platformFee = calculatePlatformFee(returnAmount);
        returnAmount = returnAmount - platformFee;

        platformToken.safeTransfer(msg.sender, returnAmount);
        platformToken.safeTransfer(factory.platformFeeAddress(), platformFee);
    }

    function calculatePlatformFee(uint256 _amount) public view returns(uint256){
        return factory.platformFeePercent10000().mul(_amount).div(10000);
    }

    function calculateContinuousMintReturn(uint256 _amount)
        public view returns (uint256 mintAmount)
    {
        return calculatePurchaseReturn(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
    }

    function calculateContinuousBurnReturn(uint256 _amount)
        public view returns (uint256 burnAmount)
    {
        return calculateSaleReturn(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
    }

    function _continuousMint(uint256 _deposit)
        internal returns (uint256)
    {
        require(_deposit > 0, "Deposit must be non-zero.");

        uint256 amount = calculateContinuousMintReturn(_deposit);
        

        uint256 to_creator = amount.mul(reward_percent).div(10000);
        uint256 to_sender = amount.sub(to_creator);    
        _mint(creator, to_creator);
        _mint(msg.sender, to_sender);
        
    
        reserveBalance = reserveBalance.add(_deposit);
        emit ContinuousMint(next_event_id++, msg.sender, to_sender, _deposit, getCurrentPrice());
        emit FundCreator(next_event_id++, msg.sender, creator, to_creator);

        return amount;
    }

    function _continuousBurn(uint256 _amount)
        internal returns (uint256)
    {
        require(_amount > 0, "Amount must be non-zero.");
        require(balanceOf(msg.sender) >= _amount, "Insufficient tokens to burn.");

        uint256 reimburseAmount = calculateContinuousBurnReturn(_amount);
        reserveBalance = reserveBalance.sub(reimburseAmount);
        _burn(msg.sender, _amount);
        emit ContinuousBurn(next_event_id++, msg.sender, _amount, reimburseAmount, getCurrentPrice());
        return reimburseAmount;
    }

    function transfer2(address _recipient, uint256 _amount) public returns (bool)
    {
        bool result = transfer(_recipient, _amount);
        emit TransferLog(next_event_id++, msg.sender, _recipient, _amount);
        return result;
    }
}