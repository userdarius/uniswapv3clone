//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "solmate/tokens/ERC20.sol";

/**
/* This contract inherits all functionality from ERC20.sol and we additionally 
/* implement public mint method which will allow us to mint any num of tokens
 */
contract ERC20Mintable is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
