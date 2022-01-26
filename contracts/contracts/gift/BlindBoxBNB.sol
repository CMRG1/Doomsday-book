pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0

import "../interface/IEDC.sol";
import "../interface/IERC20.sol";
import "../interface/ISwapRouter.sol";
import "../lib/UInteger.sol";
import "../lib/Util.sol";

import "../shop/ShopLucky.sol";

contract BlindBoxBNB is ShopLucky {
    using UInteger for uint256;
    uint256 public maxForSale = 10000;
    uint256 public maxSaleForUser = 10;
    uint256 public sold = 0;

    uint256 public startTime;
    uint256 public endTime;

    mapping(address => uint256) public userCount;
    constructor(uint256 _startTime,uint256 _endTime) {
        startTime = _startTime;
        endTime = _endTime;
    }

    function buy(uint256 quantity) external payable {
        uint256 _now = block.timestamp;
        require(_now >= startTime, "it's hasn't started yet");
        require(_now <= endTime, "it's over");
        sold += quantity;
        require(sold <= maxForSale, "Shop: sold out");
        address owner = msg.sender;
        require(quantity <= maxSaleForUser, "User: sold limit");
        require(msg.value >= price * quantity, "Insufficient balance,try again~");
        address payable _payableAddr = payable(manager.members("cashier"));
        _payableAddr.transfer(msg.value);

        userCount[owner] += quantity;
        _buyLucky(quantity);
    }

    function setMaxSale(uint256 number) external CheckPermit("config") {
        maxForSale = number;
    }


    function getSold() external view returns (uint256) {
        return maxForSale.sub(sold);
    }

    function setMaxSaleForUser(uint256 number) external CheckPermit("config") {
        maxSaleForUser = number;
    }

    function setStartTime(uint256 _startTime) external CheckPermit("config") {
        startTime = _startTime;
    }
    function setEndTime(uint256 _endTime) external CheckPermit("config") {
        endTime = _endTime;
    }

}
