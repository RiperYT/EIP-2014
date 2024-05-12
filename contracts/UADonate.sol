// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC2014.sol";

contract UADonate is ERC2014{
    string public name;
    string public symbol;

    constructor(string memory Name, string memory Symbol, address ERC20address_) ERC2014(ERC20address_, msg.sender)
    {
        name = Name;
        symbol = Symbol;
    }

    function uri(
        uint _tokenId
    ) public view returns (string memory) {
        return this.getURI(_tokenId);
    }
}