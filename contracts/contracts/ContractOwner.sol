pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0

abstract contract ContractOwner {

    address public contractOwner = msg.sender;

    modifier ContractOwnerOnly {
        require(msg.sender == contractOwner, "contract owner only");
        _;
    }
}
