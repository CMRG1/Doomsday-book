pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0

import "../lib/Util.sol";

import "./Shop.sol";
import "../lib/UInteger.sol";

abstract contract ShopLucky is Shop {
    using UInteger for uint256;

    uint256[] public rarityWeights;
    uint256 public rarityWeightTotal;
    uint256 public rarityWeightRandomTotal;
    uint256[] public rarityAmounts;
    uint256[] public RarityRandomNums;

//    struct BoxFactory {
//        uint256 id;
//        uint8 bunnyId; // A
//        string tokenURI;
//        uint256 price;
//        uint256 limit;
//        uint256 minted;
//    }
    // cid=====> box
//    mapping(uint256 => BoxFactory) public _boxFactories;
//    mapping(uint256 => uint256) public boxSold;
    uint256 public price;
    uint256 public _boxFactoriesId;

    uint256 public tokenAmount;

//    function addBoxFactory(
//        uint8 bunnyId,
//        string memory tokenURI,
//        uint256 limit
//    ) public CheckPermit("config") returns (uint256) {
//        _boxFactoriesId++;
//        BoxFactory memory boxFactory;
//        boxFactory.id = _boxFactoriesId;
//        boxFactory.bunnyId = bunnyId;
//        boxFactory.tokenURI = tokenURI;
//        boxFactory.limit = limit;
//        _boxFactories[_boxFactoriesId] = boxFactory;
//        return _boxFactoriesId;
//    }

    function setRarityAmounts(uint256[] memory amounts) external CheckPermit("config") {
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

    function setRarityWeights(uint256[] memory weights) external CheckPermit("config") {
        rarityWeights = weights;

        uint256 total = 0;
        uint256 length = weights.length;

        for (uint256 i = 0; i != length; ++i) {
            total += weights[i];
        }
        rarityWeightTotal = total;
    }

    function setPrice(uint256 _price) external CheckPermit("config") {
        price = _price;
    }

    function setTokenAmount(uint256 amount) external CheckPermit("config") {
        tokenAmount = amount;
    }

    function _buyLucky(uint256 quantity) internal {
        _buy(msg.sender, address(0), tokenAmount, quantity, 0);
    }

    function onOpenPackage(
        address,
        uint256 packageId,
        bytes32 bh
    ) external view override returns (uint256[] memory) {
         uint256 amount = uint64(packageId >> 160);
        uint256 quantity = uint16(packageId >> 144);

        uint256[] memory cardIdPres = new uint256[](quantity);

        for (uint256 i = 0; i != quantity; ++i) {
            bytes memory seed = abi.encode(bh, packageId, i, 1);

            uint256 rarity = Util.randomWeight(seed,rarityWeights,rarityWeightTotal);
            uint256 cardTpe =1;
            if(rarity == 0){
                cardTpe = 7;
            }else if(rarity == 1){
                cardTpe = 6;
            }else if(rarity == 2){
                cardTpe = 5;
            }else if(rarity == 3){
                cardTpe = 4;
            }else if(rarity == 4){
                cardTpe = 3;
            }else if(rarity == 5){
                cardTpe = 2;
            }else if(rarity == 6){
                cardTpe = 1;
            }else{
                cardTpe = 7;
            }

            uint256 random = 1;

            amount = amount.div(1e10);

//            BoxFactory storage boxFactory = _boxFactories[cardTpe];
//            if (boxFactory.limit > 0) {
//                if (boxFactory.limit.sub(boxFactory.minted) == 0){
//                    cardTpe += 1;
//                    BoxFactory storage boxFactories = _boxFactories[cardTpe];
//                    boxFactories.minted ++;
//                }else{
//                    boxFactory.minted ++;
//                }
//            }
            cardIdPres[i] = (cardTpe << 245) | (rarity << 237) | (amount << 173) | (random << 169) ;

        }

        return cardIdPres;
    }

    function getRarityWeights(uint256)
        external
        view
        override
        returns (uint256[] memory)
    {
        return rarityWeights;
    }
}
