// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC2014 {
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint _id,
        uint _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint[] _ids,
        uint[] _values
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    event Issued(
      uint indexed _tokenId,
      uint _price,
      bool _purchasePermission,
      uint _limit,
      string _uri
    );
    
    event URI(string _value, uint indexed _id);

    function balanceOf(address account, uint id) external view returns(uint);

    function balanceOfBatch(
        address[] calldata accounts,
        uint[] calldata ids
    ) external view returns(uint[] memory);

    function setApprovalForAll(
        address operator,
        bool approved
    ) external;

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns(bool);

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint[] calldata ids,
        uint[] calldata amounts,
        bytes calldata data
    ) external;

    // URI management
    function setBaseURI(
        string calldata uri
    ) external;

    function getBaseURI() external view returns(string memory);

    function setCustomURI(
        uint id,
        string calldata uri
    ) external;

    function setCustomURIBatch(
        uint[] calldata ids,
        string[] calldata uris
    ) external;

    function removeCustomURI(
        uint id
    ) external;

    function removeCustomURIBatch(
        uint[] calldata ids
    ) external;

    function getURI(
        uint id
    ) external view returns(string memory);

    function getURIBatch(
        uint[] calldata ids
    ) external view returns(string[] memory);

    // Token issuance limits
    function setTokenIssuanceLimit(
        uint id,
        uint limit
    ) external;

    function setTokenIssuanceLimitBatch(
        uint[] calldata ids,
        uint[] calldata limits
    ) external;

    function removeTokenIssuanceLimit(
        uint id
    ) external;

    function removeTokenIssuanceLimitBatch(
        uint[] calldata ids
    ) external;

    function getTokenIssuanceLimit(
        uint id
    ) external view returns(uint);

    function getTokenIssuanceLimitBatch(
        uint[] calldata ids
    ) external view returns(uint[] memory);

    // Purchase permit management
    function setPurchasePermit(
        uint id,
        bool permited
    ) external;

    function setPurchasePermitBatch(
        uint[] calldata ids,
        bool[] calldata prohibitions
    ) external;

    function getPurchasePermission(
        uint id
    ) external view returns(bool);

    function getPurchasePermissionBatch(
        uint[] calldata ids
    ) external view returns(bool[] memory);

    // Token purchase price management
    function setPurchasePrice(
        uint id,
        uint price
    ) external;

    function setPurchasePriceBatch(
        uint[] calldata ids,
        uint[] calldata prices
    ) external;

    function removePurchasePrice(
        uint id
    ) external;

    function removePurchasePriceBatch(
        uint[] calldata ids
    ) external;

    function getPurchasePrice(
        uint id
    ) external view returns(uint);

    function getPurchasePriceBatch(
        uint[] calldata ids
    ) external view returns(uint[] memory);

    // Token purchase and fund withdrawal management
    function purchaseToken(
        uint id
    ) external payable;

    function upgradeToken(
        uint tokenId,
        uint newTokenId,
        uint amount,
        uint newAmount,
        address account
    ) external;
    
    function upgradeTokenBatch(
        uint[] memory tokenIds,
        uint[] memory newTokenIds,
        uint[] memory amounts,
        uint[] memory newAmounts,
        address[] memory accounts
    ) external;

    function issueToken(
        uint price,
        bool purchasePermission,
        uint limit,
        string calldata uri
    ) external returns (uint);

    function issueTokenBatch(
        uint[] memory prices,
        bool[] memory purchasePermissions,
        uint[] memory limits,
        string[] memory uris
    ) external returns (uint[] memory);

    function issueTokenCount(
        uint id
    ) external view returns (uint);
    
    function issueTokenCountBatch(
        uint[] memory ids
    ) external view returns (uint[] memory);
    
    function withdrawFunds() external;
}