pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0

interface IEDC {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function onOpenPackage(address, uint256 packageId, bytes32 bh) external view returns (uint256[] memory);
    function getRarityWeights(uint256 packageId) external view  returns (uint256[] memory);

    // Mutative

    function stake(uint256 amount) external;

    function stake() external payable;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}