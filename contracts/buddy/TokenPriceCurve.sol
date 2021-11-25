// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Power.sol";

contract TokenPriceCurve is Power {
    using SafeMath for uint256;

    uint32 private constant MAX_RESERVE_RATIO = 1000000;

    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _depositAmount) public view returns (uint256) 
    {
        require(_supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO);
        // special case for 0 deposit amount
        if (_depositAmount == 0) {
            return 0;
        }
        // special case if the ratio = 100%
        if (_reserveRatio == MAX_RESERVE_RATIO) {
            return _supply.mul(_depositAmount).div(_reserveBalance);
        }
        uint256 result;
        uint8 precision;
        uint256 baseN = _depositAmount.add(_reserveBalance);
        (result, precision) = power(baseN, _reserveBalance, _reserveRatio, MAX_RESERVE_RATIO);
        uint256 newTokenSupply = _supply.mul(result) >> precision;
        return newTokenSupply - _supply;
    }

    function calculateSaleReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _sellAmount) public view returns (uint256)
    {
        require(_supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO && _sellAmount <= _supply);
        if (_sellAmount == 0) {
            return 0;
        }
        if (_sellAmount == _supply) {
            return _reserveBalance;
        }
        if (_reserveRatio == MAX_RESERVE_RATIO) {
            return _reserveBalance.mul(_sellAmount).div(_supply);
        }
        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_RESERVE_RATIO, _reserveRatio);
        uint256 oldBalance = _reserveBalance.mul(result);
        uint256 newBalance = _reserveBalance << precision;
        return oldBalance.sub(newBalance).div(result);
    }
}