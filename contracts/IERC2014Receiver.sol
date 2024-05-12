// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC2014Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint id,
        uint amount,
        bytes calldata data
    ) external returns(bytes4);

    function onERC2014BatchReceived(
        address operator,
        address from,
        uint[] calldata ids,
        uint[] calldata amounts,
        bytes calldata data
    ) external returns(bytes4);
}