pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0

import "./interface/IERC20.sol";

import "./lib/String.sol";
import "./lib/Util.sol";
import "./lib/UInteger.sol";

import "./ERC721Ex.sol";
import "./Slot.sol";

// nftSign  cardType    skin    rarity tokenAmount  padding mintTime    index
// 1        31          16      16     64           24      40          64
// 255      224         208     192    128          104     64          0

//-----------------------------------------------------------------------------
// nftSign  nftType   rarity  tokenAmount  random  strength   intelligence    endurance   agile    lucky    padding    mintTime  index
//   1        10       8      64            4      10         10              10          10        10      15         40        64
// 255       245      237     173           169    159        149             139         129       119     104        64        0

contract Card is ERC721Ex {
    using String for string;
    using UInteger for uint256;

    uint256 public constant UPGRADE_LOCK_DURATION = 60 * 60 * 24 * 2;

    uint256 public constant ID_PREFIX_MASK = uint256(~uint152(0)) << 104;

    struct LockedToken {
        uint256 locked;
        uint256 lockTime;
        int256 unlocked;
    }

    mapping(uint256 => int256) public rarityFights;

    mapping(address => LockedToken) public upgradeLockedTokens;
    uint256 public burnLockDuration = 60 * 60 * 24 * 2;
    uint256 public feeRatio = 20;
    uint256 public constant FEE_DENOMINATOR = 1000;
    mapping(address => bool) public packages;
//
    mapping(uint256 => uint256) public boxSold;
    uint256 public _boxFactoriesId;
    mapping(uint256 => BoxFactory) public _boxFactories;
    event cardIdPreId(uint256 _old,uint256 _new);

    struct BoxFactory {
        uint256 id;
        uint8 bunnyId;
        string tokenURIs;
        uint256 price;
        uint256 limit;
        uint256 minted;
    }


    function addBoxFactory(
        uint8 bunnyId,
        string memory tokenURIs,
        uint256 limit
    ) public CheckPermit("config") returns (uint256) {
        _boxFactoriesId++;
        BoxFactory memory boxFactory;
        boxFactory.id = _boxFactoriesId;
        boxFactory.bunnyId = bunnyId;
        boxFactory.tokenURIs = tokenURIs;
        boxFactory.limit = limit;
        _boxFactories[_boxFactoriesId] = boxFactory;
        return _boxFactoriesId;
    }

    function setBoxFactory(
        uint256 cardId,
        uint256 sold
    ) external CheckPermit("config") {
        BoxFactory storage bf = _boxFactories[cardId];
        bf.minted = sold;
        boxSold[cardId] = sold;
    }
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol) {
        rarityFights[Util.RARITY_WHITE] = 1000;
        rarityFights[Util.RARITY_GREEN] = 2000;
        rarityFights[Util.RARITY_BLUE] = 4000;
        rarityFights[Util.RARITY_PURPLE] = 8000;
        rarityFights[Util.RARITY_GOLD] = 16000;
        rarityFights[Util.RARITY_RED] = 32000;
    }


    function setRarityFight(uint256 rarity, int256 fight)
        external CheckPermit("config") {

        rarityFights[rarity] = fight;
    }
    function setBurnLockDuration(uint256 duration)
        external CheckPermit("config") {

        burnLockDuration = duration;
    }
    function setFeeRatio(uint256 fee) external CheckPermit("config") {
        feeRatio = fee;
    }

    function checkCardBox(uint256 cardId) public returns (uint256){
        uint256 cardType = (cardId ^ (1 << 255)) >> 245;
        uint256 rarity = uint8(cardId >> 237);
        BoxFactory storage boxF = _boxFactories[cardType];
        if (boxF.limit > 0) {
            if (boxF.limit.sub(boxF.minted) == 0 || boxSold[cardType] == boxF.limit ){
                cardType ++;
                rarity ++;
                BoxFactory storage boxFactories = _boxFactories[cardType];
                boxFactories.minted ++;
                boxSold[cardType] ++;
            }else{
                boxF.minted += 1;
                boxSold[cardType] +=1;
            }
        }
        return (cardType << 245) | (rarity << 237) | (199 << 173) | (1 << 169) ;
    }
    function setPackage(address package, bool enable)
        external CheckPermit("config") {
        packages[package] = enable;
    }
    //铸卡

    function mint(address to, uint256 cardIdPre) external {
        require(packages[msg.sender], "package only") ;
//        uint256 cardIdNew = checkCardBox(cardIdPre);
//        emit cardIdPreId(cardIdPre,cardIdNew);

        uint256 cardId = NFT_SIGN_BIT | (cardIdPre & ID_PREFIX_MASK) |
            (block.timestamp << 64) | uint64(totalSupply + 1);

        _mint(to, cardId);
    }
//    function CardBox(uint256 cardId) external returns (uint256){
//        uint256 cardType = (cardId ^ (1 << 255)) >> 245;
//        uint256 rarity = uint8(cardId >> 237);
//
//        BoxFactory storage boxF = _boxFactories[cardType];
//        if (boxF.limit > 0) {
//            if (boxF.limit.sub(boxF.minted) == 0 || boxSold[cardType] == boxF.limit ){
//                cardType ++;
//                rarity ++;
//                BoxFactory storage boxFactories = _boxFactories[cardType];
//                boxFactories.minted ++;
//                boxSold[cardType] ++;
//            }else{
//                boxF.minted += 1;
//                boxSold[cardType] +=1;
//            }
//        }
//        return  (cardType << 245) | (rarity << 237) | (199 << 173) | (1 << 169) ;
//    }

    function batchMint(address to, uint256[] memory cardIdPres) external {
        require(packages[msg.sender], "package only");

        uint256 length = cardIdPres.length;

        for (uint256 i = 0; i != length; ++i) {
            uint256 cardId = NFT_SIGN_BIT | (cardIdPres[i] & ID_PREFIX_MASK) |
                (block.timestamp << 64) | uint64(totalSupply + 1);
            _mint(to, cardId);
        }
    }
    function burn(uint256 cardId) external {
        address owner = tokenOwners[cardId];

        require(msg.sender == owner
            || msg.sender == tokenApprovals[cardId]
            || approvalForAlls[owner][msg.sender],
            "msg.sender must be owner or approved");

        uint256 mintTime = uint40(cardId >> 64);
        require(mintTime + burnLockDuration < block.timestamp, "card has not unlocked");

        _burn(cardId);

        uint256 tokenAmount = uint256(uint64(cardId >> 173)).mul(1e10);
        // not check result to save gas
        // feeAccount
        uint256 fee = tokenAmount.mul(feeRatio).div(FEE_DENOMINATOR);
        IERC20(manager.members("token")).transfer(manager.members("cashier"), fee);
        IERC20(manager.members("token")).transfer(owner, tokenAmount.sub(fee));
    }
    function burnForSlot(uint256[] memory cardIds) external {
        uint256 length = cardIds.length;
        address owner = msg.sender;
        uint256 tokenAmount = 0;

        for (uint256 i = 0; i != length; ++i) {
            uint256 cardId = cardIds[i];
            require(owner == tokenOwners[cardId], "you are not owner");
            _burn(cardId);
            tokenAmount += uint256(uint64(cardId >> 173)).mul(1e10);
        }

        LockedToken storage lt = upgradeLockedTokens[owner];
        uint256 _now = block.timestamp;

        if (_now < lt.lockTime + UPGRADE_LOCK_DURATION) {
            uint256 amount = lt.locked * (_now - lt.lockTime)
                / UPGRADE_LOCK_DURATION;
            lt.locked = lt.locked - amount + tokenAmount;
            lt.unlocked += int256(amount);
        } else {
            lt.unlocked += int256(lt.locked);
            lt.locked = tokenAmount;
        }

        lt.lockTime = _now;

        Slot(manager.members("slot")).upgrade(owner, cardIds);
    }

    function burnForBonus(address owner, uint256 cardId, uint256[] memory upCardIds) external {
        uint256 length = upCardIds.length;
        for (uint256 i = 0; i != length; ++i) {
            uint256 upCdId = upCardIds[i];
            require(owner == tokenOwners[upCdId], "you are not owner");
            _burn(upCdId);
        }

        uint256 cardType = (cardId ^ (1 << 255)) >> 245;
        Slot(manager.members("slot")).removeCardForBonus(owner, cardType);

        _burn(cardId);

        uint256 rarity = uint16(cardId >> 237);
        uint256 amount = uint256(uint64(cardId >> 173));
        uint256 R = uint256(uint24(cardId >> 169));

        bool hasEbi = Slot(manager.members("slot")).hasEvolBondIndex(cardType);
        require(hasEbi, "no evol bond index");

        uint256 ebi = Slot(manager.members("slot")).cardTypeEvolBondIndex(cardType);
        uint256[] memory bond = Slot(manager.members("slot")).getBond(ebi);
        uint256 n = Util.getIndex(cardType, bond);
        require(n != type(uint256).max, "no index in evol bond");
        if(n < bond.length - 1) {
            if(cardType != 134 && cardType != 135) {
                R ++;
            }
            cardType = bond[n + 1];
        }

        uint256 cardIdPre = (cardType << 245) | (rarity << 237) | (amount << 173) | (R << 169);
        uint256 newCardId = NFT_SIGN_BIT | (cardIdPre & ID_PREFIX_MASK) |
            (block.timestamp << 64) | uint64(totalSupply + 1);

        _mint(owner, newCardId);
    }

    function withdraw() external {
        LockedToken storage lt = upgradeLockedTokens[msg.sender];
        int256 available = lt.unlocked;
        uint256 _now = block.timestamp;

        if (_now < lt.lockTime + UPGRADE_LOCK_DURATION) {
            available += int256(lt.locked * (_now - lt.lockTime)
                / UPGRADE_LOCK_DURATION);
        } else {
            available += int256(lt.locked);
        }

        require(available > 0, "no token available");

        lt.unlocked -= available;
        // not check result to save gas
        IERC20(manager.members("token")).transfer(msg.sender, uint256(available));
    }

    function getFight(uint256 cardId) external view returns(int256) {
        int256 fight = rarityFights[uint16(cardId >> 169)];
        int256 rBuffer = (uint24(cardId >> 104) - 1) * 30;
        return fight * (rBuffer + 100) / 100;
    }
    function tokenURI(uint256 cardId)
        external view override returns(string memory) {

        bytes memory bs = abi.encodePacked(cardId);

        return uriPrefix.concat("card/").concat(Util.base64Encode(bs));
    }
}
