pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0

interface IBlockhashMgr {
//    event TransferDemo(address indexed from, address indexed to, uint256 value);
//    function onOpenPackage(address, uint256 packageId, bytes32 bh) external view returns (uint256[] memory);

    function request(uint256 blockNumber) external;
    function request(uint256[] memory blockNumbers) external;
    
    function getBlockhash(uint256 blockNumber) external returns(bytes32);
}
