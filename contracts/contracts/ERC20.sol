pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0

import "./interface/IERC20.sol";
import "./lib/UInteger.sol";
import "./ContractOwner.sol";

contract ERC20 is IERC20, ContractOwner {
    using UInteger for uint256;
    string public override name;
    string public override symbol;
    uint8 public override decimals;

    uint256 public override totalSupply;
    uint256 public remainedSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

//    constructor(string memory _name, string memory _symbol,
//        uint8 _decimals, uint256 _maxSupply) {
//
//        name = _name;
//        symbol = _symbol;
//        decimals = _decimals;
//        remainedSupply = _maxSupply;
//    }

    constructor()  {
        symbol = "PGO";
        name = "pokemongo";
        decimals = 18;
        balanceOf[msg.sender] = 200000000 * 10 ** uint256(decimals);
    }

    function mint(address to, uint256 amount) external ContractOwnerOnly {
        require(to != address(0), "zero address");
        require(remainedSupply >= amount, "mint too much");

        remainedSupply = remainedSupply.sub(amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[to] = balanceOf[to].add(amount);

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) private {
        require(balanceOf[from] >= amount, "balance not enough");

        balanceOf[from] = balanceOf[from].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        require(allowance[from][msg.sender] >= amount, "allowance not enough");

        allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        _burn(from, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "zero address");
        require(balanceOf[from] >= amount, "balance not enough");

        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) external override returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external override returns(bool) {

        require(allowance[from][msg.sender] >= amount, "allowance not enough");

        allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns(bool) {
        require(spender != address(0), "zero address");

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }
}
