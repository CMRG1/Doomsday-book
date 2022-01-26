pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0

import "./interface/IBlockhashMgr.sol";
import "./interface/IEDC.sol";
import "./lib/String.sol";
import "./lib/Util.sol";
import "./lib/UInteger.sol";

import "./shop/Shop.sol";

import "./Card.sol";
import "./ERC721Ex.sol";

// nftSign  packageType tokenAmount quantity    padding mintTime    index
// 1        31          64          16          40      40          64
// 255      224         160         144         104     64          0

contract Package is ERC721Ex {
    using String for string;
    using UInteger for uint256;

    struct ShopInfo {
        uint256 id;
        bool enabled;
    }
    struct PackageInfo {
        uint256 blockNumber;
        Shop shop;
    }

    mapping(uint256 => PackageInfo) public packageInfos;

    uint256 public quantityMin = 1;
    uint256 public quantityMax = 50;

    mapping(address => ShopInfo) public shopInfos;
    uint256 public shopCount;
    mapping(uint256 => uint256) public boxSold;
    uint256 public _boxFactoriesId;
    mapping(uint256 => BoxFactory) public _boxFactories;
    event cardIdPreId(uint256 _old,uint256 _new);

    struct BoxFactory {
        uint256 id;
        uint8 bunnyId; // A
        string tokenURIs;
        uint256 price;
        uint256 limit;
        uint256 minted;
    }
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function setShop(address addr, bool enable) external CheckPermit("config") {
        ShopInfo storage si = shopInfos[addr];

        if (si.id == 0) {
            si.id = ++shopCount;
        }

        si.enabled = enable;
    }

    function setQuantityMin(uint256 min) external CheckPermit("config") {
        quantityMin = min;
    }

    function setQuantityMax(uint256 max) external CheckPermit("config") {
        quantityMax = max;
    }

    function mint(
        address to,
        uint256 tokenAmount,
        uint256 quantity,
        uint256 padding
    ) external {
        //setShop
        require(shopInfos[msg.sender].enabled, "shop not enabled");

        require(
            quantity >= quantityMin && quantity <= quantityMax,
            "invalid quantity"
        );
//        setShop
        uint256 shopId = shopInfos[msg.sender].id;
        uint256 initialAmount = tokenAmount.div(1e10);  //?
        uint256 packageId =
            NFT_SIGN_BIT |
                (uint256(uint32(shopId)) << 224) |
                (uint256(uint64(initialAmount)) << 160) |
                (uint256(uint16(quantity)) << 144) |
                (uint256(uint40(padding)) << 104) |
                (block.timestamp << 64) |
                (uint64(totalSupply + 1));

        PackageInfo storage pi = packageInfos[packageId];

        pi.blockNumber = block.number + 1;

        pi.shop = Shop(msg.sender);

        _mint(to, packageId);
    }





    function open(uint256 packageId,address shop) external {
        require(
            msg.sender == tokenOwners[packageId],
            "you not own this package"
        );

        _burn(packageId);

        PackageInfo storage pi = packageInfos[packageId];

        bytes32 bh = bytes32(blockhash(pi.blockNumber));
//        uint256[] memory cardIdPres =
//        pi.shop.onOpenPackage(msg.sender, packageId, bh);

        uint256[] memory cardIdPres = IEDC(shop).onOpenPackage(msg.sender, packageId, bh);

         Card card = Card(manager.members("card"));

         uint256 length = cardIdPres.length;

         for (uint256 i = 0; i != length; ++i) {
//             uint256 cardIdPre = checkCardBox(cardIdPres[i]);
//             emit cardIdPreId(cardIdPres[i],cardIdPre);
             card.mint(msg.sender, cardIdPres[i]);
         }

        delete packageInfos[packageId];

    }

    function batchOpen(uint256 packageId,address shop) external {
        require(
            msg.sender == tokenOwners[packageId],
            "you not own this package"
        );

        _burn(packageId);

        PackageInfo storage pi = packageInfos[packageId];

        // bytes32 bh = IBlockhashMgr(manager.members("blockhashMgr"))
        //     .getBlockhash(pi.blockNumber);
        bytes32 bh = bytes32(blockhash(pi.blockNumber + 1));

        uint256[] memory cardIdPres =
            IEDC(shop).onOpenPackage(msg.sender, packageId, bh);

//        uint256 length = cardIdPres.length;
//        uint256[] memory cardIdPre;
//        for (uint256 i = 0; i != length; ++i) {
//            cardIdPre[i] = checkCardBox(cardIdPres[i]);
//            emit cardIdPreId(cardIdPres[i],cardIdPre[i]);
//        }
        Card(manager.members("card")).batchMint(msg.sender, cardIdPres);

        delete packageInfos[packageId];
    }

    function batchOpens(uint256[] memory packageIds,address shop) external {
        uint256 length = packageIds.length;

        for (uint256 i = 0; i != length; ++i) {
            uint256 packageId = packageIds[i];
            require(
                msg.sender == tokenOwners[packageId],
                "you not own this package"
            );

            _burn(packageId);

            PackageInfo storage pi = packageInfos[packageId];

            // bytes32 bh = IBlockhashMgr(manager.members("blockhashMgr"))
            //     .getBlockhash(pi.blockNumber);
            bytes32 bh = bytes32(blockhash(pi.blockNumber + 1));

            uint256[] memory cardIdPres =
                IEDC(shop).onOpenPackage(msg.sender, packageId, bh);
//            uint256 len = cardIdPres.length;

//            uint256[] memory cardIdPre;
//            for (uint256 k = 0; k != cardIdPres.length; ++k) {
//                cardIdPre[k] = checkCardBox(cardIdPres[k]);
//                emit cardIdPreId(cardIdPres[k],cardIdPre[k]);
//            }
            Card(manager.members("card")).batchMint(msg.sender, cardIdPres);

            delete packageInfos[packageId];
        }
    }

    function tokenURI(uint256 packageId)
        external
        view
        override
        returns (string memory)
    {
        PackageInfo storage pi = packageInfos[packageId];

        bytes memory bs = abi.encodePacked(packageId);

        uint256[] memory rarityWeights = pi.shop.getRarityWeights(packageId);

        uint256 length = rarityWeights.length;
        uint256 rarityWeightTotal = 0;
        for (uint256 i = 0; i != length; ++i) {
            rarityWeightTotal += rarityWeights[i];
        }

        uint256 weightMax = ~uint16(0);

        for (uint256 i = 0; i != length; ++i) {
            bs = abi.encodePacked(
                bs,
                uint16((rarityWeights[i] * weightMax) / rarityWeightTotal)
            );
        }

        return uriPrefix.concat("package/").concat(Util.base64Encode(bs));
    }
}
