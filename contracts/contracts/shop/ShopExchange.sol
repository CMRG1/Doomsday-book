pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0

import "../lib/Util.sol";
import "../lib/UInteger.sol";
import "../interface/IERC20.sol";
import "./Shop.sol";

abstract contract ShopExchange is Shop {
    using UInteger for uint256;


    uint256 public rarityWeightRandomTotal;
    uint256[] public RarityRandomNums;

    uint256[] public rarityAmounts = [
        10**18 * 120,
        10**18 * 240,
        10**18 * 480,
        10**18 * 960,
        10**18 * 1920,
        10**18 * 3480
    ];

    function getRarityAmounts() public view returns (uint256[] memory) {
        return rarityAmounts;
    }

    function setRarityAmounts(uint256[] memory amounts)
        external
        CheckPermit("config")
    {
        rarityAmounts = amounts;
    }

    function setRarityRandomNum(uint256[] memory RandomNums) external CheckPermit("config") {
        RarityRandomNums = RandomNums;
        uint256 total = 0;
        uint256 length = RandomNums.length;

        for (uint256 i = 0; i != length; ++i) {
            total += RandomNums[i];
        }
        rarityWeightRandomTotal = total;
    }


    function _buyExchange(address tokenSender, uint256 tokenAmount,uint256 quantity, uint256 padding) internal {
        require(tokenAmount >= rarityAmounts[0], "too little token");
        _buy(msg.sender, tokenSender, tokenAmount, quantity, padding);
    }

    function onOpenPackage(address,uint256 packageId,bytes32 bh) external view override returns (uint256[] memory) {
        uint256 intialAmount = uint64(packageId >> 160);
        uint256 tokenAmount = uint256(intialAmount).mul(1e10);
        uint256 quantity = uint16(packageId >> 144);

        uint256 length = rarityAmounts.length;
        uint256 rarity = 0;
        uint256 weight0 = 0;
        uint256 weight1 = 1;

        if (tokenAmount >= rarityAmounts[length - 1]) {
            rarity = length;
            weight0 = 999;
        } else {
            while (tokenAmount > rarityAmounts[rarity]) {
                ++rarity;
            }

            if (tokenAmount < rarityAmounts[rarity]) {
                weight0 = rarityAmounts[rarity] - tokenAmount;
                weight1 = tokenAmount - rarityAmounts[rarity - 1];
            }
        }

        uint256[] memory cardIdPres = new uint256[](quantity);

        for (uint256 i = 0; i != quantity; ++i) {
            bytes memory seed = abi.encode(bh, packageId, i, 1);
            uint256 rar = rarity;

            if (weight0 != 0) {
                uint256 random = Util.randomUint(seed, 1, weight0 + weight1);

                if (random <= weight0) {
                    rar = rarity - 1;
                }
            }
            uint256 rand = Util.randomWeight(seed, RarityRandomNums, rarityWeightRandomTotal);
            rand ++;
            uint256 cardType = calcCardType(seed,rand);
            cardIdPres[i] =(cardType << 224) | (rar << 192) | (intialAmount << 128) | (rand << 104);
        }

        return cardIdPres;
    }

    function getRarityWeights(uint256 packageId)external view override returns (uint256[] memory)
    {
        uint256 tokenAmount = uint256(uint64(packageId >> 160)).mul(1e18);

        uint256[] memory weights = new uint256[](6);
        if (tokenAmount <= rarityAmounts[0]) {
            weights[0] = 1;
        } else if (tokenAmount >= rarityAmounts[4]) {
            weights[4] = 999;
            weights[5] = 1;
        } else {
            uint256 rarity = 0;
            while (tokenAmount > rarityAmounts[rarity]) {
                rarity++;
            }
            if (tokenAmount == rarityAmounts[rarity]) {
                weights[rarity] = 1;
            } else {
                weights[rarity - 1] = rarityAmounts[rarity] - tokenAmount;
                weights[rarity] = tokenAmount - rarityAmounts[rarity - 1];
            }
        }

        return weights;
    }
}
