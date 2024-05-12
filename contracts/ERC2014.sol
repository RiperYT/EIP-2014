// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC2014.sol";
import "./IERC2014Receiver.sol";

contract ERC2014 is IERC2014{
    uint private _tokenCounter = 0;
    uint private _balance;
    mapping(uint => mapping(address => uint)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string private _baseURI;
    mapping(uint => string) private _tokenURIs;

    uint[] private _issuedTokens;
    mapping(uint => uint) private _countTokens;
    mapping(uint => uint) private _limits;
    mapping(uint => uint) private _purchasePrices;
    mapping(uint => bool) private _purchasePermissions;
    
    address private _owner; 

    constructor(address owner) {
        _owner = owner;
        _balance = address(this).balance;
    }

    function balanceOf(address account, uint id) public view returns(uint) {
        require(account != address(0));
        return _balances[id][account];
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint[] calldata ids
    ) public view returns(uint[] memory batchBalances) {
        require(accounts.length == ids.length);

        batchBalances = new uint[](accounts.length);

        for(uint i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view returns(bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes calldata data
    ) external {
        require(
            from == msg.sender ||
            isApprovedForAll(from, msg.sender)
        );

        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint[] calldata ids,
        uint[] calldata amounts,
        bytes calldata data
    ) external {
        require(
            from == msg.sender ||
            isApprovedForAll(from, msg.sender)
        );

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setBaseURI(
        string calldata uri
    ) onlyOwner external {
        _baseURI = uri;
    }

    function getBaseURI() external view returns (string memory) {
        return _baseURI;
    }

    function setCustomURI(
        uint id,
        string calldata uri
    ) onlyOwner external {
        require(_isTokenIssued(id));
        _tokenURIs[id] = uri;
    }

    function setCustomURIBatch(
        uint[] calldata ids,
        string[] calldata uris
    ) onlyOwner external {
        require(ids.length == uris.length, "IDs and URIs length mismatch");
        for (uint i = 0; i < ids.length; i++) {
            require(_isTokenIssued(ids[i]));
            _tokenURIs[ids[i]] = uris[i];
        }
    }

    function removeCustomURI(
        uint id
    ) onlyOwner external {
        delete _tokenURIs[id];
    }

    function removeCustomURIBatch(
        uint[] calldata ids
    ) onlyOwner external {
        for (uint i = 0; i < ids.length; i++) {
            delete _tokenURIs[ids[i]];
        }
    }

    function getURI(
        uint id
    ) external view returns (string memory) {
        string memory customUri = _tokenURIs[id];

        bool custURI = bytes(customUri).length > 0;
        bool baseURI = bytes(_baseURI).length > 0;
        require(custURI || baseURI, "Token URI and base URI not issued");

        return custURI ? customUri : _baseURI;
    }

    function getURIBatch(
        uint[] calldata ids
    ) external view returns (string[] memory) {
        string[] memory uris = new string[](ids.length);
        bool baseURI = bytes(_baseURI).length > 0;
        for (uint i = 0; i < ids.length; i++) {
            string memory customUri = _tokenURIs[ids[i]];

            bool custURI = bytes(customUri).length > 0;
            require(custURI || baseURI, "Token URI and base URI not issued");

            uris[i] = custURI ? customUri : _baseURI;
        }
        return uris;
    }
    
    function setTokenIssuanceLimit(
        uint id,
        uint limit
    ) onlyOwner external {
        require(_isTokenIssued(id), "Token must be issued before setting a limit");
        uint totalIssued = _countTokens[id];
        require(limit >= totalIssued, "Cannot set limit belonlyOwner current total issued tokens");
        _limits[id] = limit;
    }

    function setTokenIssuanceLimitBatch(
        uint[] calldata ids,
        uint[] calldata limits
    ) onlyOwner external {
        require(ids.length == limits.length, "IDs and limits length mismatch");
        for (uint i = 0; i < ids.length; i++) {
            require(_isTokenIssued(ids[i]), "Token must be issued before setting a limit");
            uint totalIssued = _countTokens[ids[i]];
            require(limits[i] >= totalIssued, "Cannot set limit belonlyOwner current total issued tokens");
            _limits[ids[i]] = limits[i];
        }
    }

    function removeTokenIssuanceLimit(
        uint id
    ) onlyOwner external {
        delete _limits[id];
    }

    function removeTokenIssuanceLimitBatch(
        uint[] calldata ids
    ) onlyOwner external {
        for (uint i = 0; i < ids.length; i++) {
            delete _limits[ids[i]];
        }
    }

    function getTokenIssuanceLimit(uint id) external view returns (uint) {
        require(_isTokenIssued(id), "Token must be issued before setting a limit");
        return _limits[id];
    }

    function getTokenIssuanceLimitBatch(uint[] calldata ids) external view returns (uint[] memory) {
        uint[] memory limits = new uint[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            require(_isTokenIssued(ids[i]), "Token must be issued before setting a limit");
            limits[i] = _limits[ids[i]];
        }
        return limits;
    }

    function setPurchasePermit(
        uint id,
        bool permitted
    ) onlyOwner external {
        require(_isTokenIssued(id), "Token not issued");
        _purchasePermissions[id] = permitted;
    }

    function setPurchasePermitBatch(
        uint[] calldata ids,
        bool[] calldata permissions
    ) onlyOwner external {
        require(ids.length == permissions.length, "IDs and permissions length mismatch");
        for (uint i = 0; i < ids.length; i++) {
            require(_isTokenIssued(ids[i]), "Token not issued");
            _purchasePermissions[ids[i]] = permissions[i];
        }
    }

    function getPurchasePermission(
        uint id
    ) external view returns(bool) {
        require(_isTokenIssued(id), "Token not issued");
        return _purchasePermissions[id];
    }

    function getPurchasePermissionBatch(
        uint[] calldata ids
    ) external view returns(bool[] memory) {
        bool[] memory permissions = new bool[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            require(_isTokenIssued(ids[i]), "Token not issued");
            permissions[i] = _purchasePermissions[ids[i]];
        }
        return permissions;
    }

    function setPurchasePrice(
        uint id, uint price
    ) onlyOwner external {
        require(_isTokenIssued(id), "Token not issued");
        _purchasePrices[id] = price;
    }

    function setPurchasePriceBatch(
        uint[] calldata ids,
        uint[] calldata prices
    ) onlyOwner external {
        require(ids.length == prices.length, "IDs and prices length mismatch");
        for (uint i = 0; i < ids.length; i++) {
            require(_isTokenIssued(ids[i]), "Token not issued");
            _purchasePrices[ids[i]] = prices[i];
        }
    }

    function removePurchasePrice(
        uint id
    ) onlyOwner external {
        delete _purchasePrices[id];
    }

    function removePurchasePriceBatch(
        uint[] calldata ids
    ) onlyOwner external {
        for (uint i = 0; i < ids.length; i++) {
            delete _purchasePrices[ids[i]];
        }
    }

    function getPurchasePrice(uint id) external view returns(uint) {
        require(_isTokenIssued(id), "Token not issued");
        return _purchasePrices[id];
    }

    function getPurchasePriceBatch(uint[] calldata ids) external view returns(uint[] memory) {
        uint[] memory prices = new uint[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            require(_isTokenIssued(ids[i]), "Token not issued");
            prices[i] = _purchasePrices[ids[i]];
        }
        return prices;
    }

    function issueToken(
        uint price,
        bool purchasePermission,
        uint limit,
        string calldata uri
    ) onlyOwner external returns (uint) {
      uint newTokenId = _tokenCounter;
      _tokenCounter += 1;

      require(bytes(_baseURI).length > 0 || bytes(uri).length > 0, "Base URI or custom URI must be provided");

      _issuedTokens.push(newTokenId);

      _purchasePrices[newTokenId] = price;
      _purchasePermissions[newTokenId] = purchasePermission;
      if (limit > 0) {
        _limits[newTokenId] = limit;
      }
      if (bytes(uri).length > 0) {
        _tokenURIs[newTokenId] = uri;
      }

      // Emit an Issued event
      emit Issued(newTokenId, price, purchasePermission, limit, uri);

      return newTokenId;
    }

    function issueTokenBatch(
        uint[] memory prices,
        bool[] memory purchasePermissions,
        uint[] memory limits,
        string[] memory uris
    ) onlyOwner external returns (uint[] memory) {
        require(prices.length == purchasePermissions.length && prices.length == limits.length && prices.length == uris.length, "Input arrays must have the same length");

        uint[] memory issuedTokenIds = new uint[](prices.length);

        for (uint i = 0; i < prices.length; i++) {
            // Generate a unique token ID
            uint newTokenId = _tokenCounter;
            _tokenCounter += 1;

            require(bytes(_baseURI).length > 0 || bytes(uris[i]).length > 0, "Base URI or custom URI must be provided");

            _issuedTokens.push(newTokenId);

            _purchasePrices[newTokenId] = prices[i];
            _purchasePermissions[newTokenId] = purchasePermissions[i];
            if (limits[i] > 0) {
                _limits[newTokenId] = limits[i];
            }
            if (bytes(uris[i]).length > 0) {
                _tokenURIs[newTokenId] = uris[i];
            }

            emit Issued(newTokenId, prices[i], purchasePermissions[i], limits[i], uris[i]);

            issuedTokenIds[i] = newTokenId;
        }

        return issuedTokenIds;
    }

    function purchaseToken(
        uint id
    ) external payable {
        require(_isTokenIssued(id), "Token not issued");
        require(_purchasePrices[id] > 0, "Purchase price not set");
        require(_purchasePermissions[id], "Purchase not permitted");
        require(msg.value >= _purchasePrices[id], "Insufficient payment");

        uint numTokens = msg.value / _purchasePrices[id];
        uint availableTokens = (_limits[id] == 0 ? type(uint256).max : _limits[id]) - _countTokens[id];
        uint tokensToPurchase = (numTokens <= availableTokens) ? numTokens : availableTokens;
        
        require(tokensToPurchase > 0, "No tokens available for purchase or limit reached");

        uint256 requiredPayment = tokensToPurchase * _purchasePrices[id];
        uint balance = address(this).balance;
        require(balance >= _balance + requiredPayment, "Payment not verified");
        _balance = balance;

        _balances[id][msg.sender] += tokensToPurchase;
        _countTokens[id] += tokensToPurchase;
    }

    function upgradeToken(
        uint tokenId,
        uint newTokenId,
        uint amount,
        uint newAmount,
        address account
    ) onlyOwner public {
        require(_isTokenIssued(tokenId), "Token not issued");
        require(_isTokenIssued(newTokenId), "New token not issued");
        require(_balances[tokenId][account] >= amount);

        uint limit = _limits[newTokenId];
        uint availableTokens = (limit == 0 ? type(uint256).max : limit) - _countTokens[newTokenId];
        require(availableTokens >= newAmount);

        _balances[tokenId][account] -= amount;
        _balances[newTokenId][account] += newAmount;

        _countTokens[tokenId] -= amount;
        _countTokens[newTokenId] += newAmount;
    }
        
    function upgradeTokenBatch(
        uint[] memory tokenIds,
        uint[] memory newTokenIds,
        uint[] memory amounts,
        uint[] memory newAmounts,
        address[] memory accounts
    ) onlyOwner external {
        require(tokenIds.length == newTokenIds.length && tokenIds.length == amounts.length && tokenIds.length == newAmounts.length && tokenIds.length == accounts.length, "Mismatched input array lengths");
    
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            uint newTokenId = newTokenIds[i];
            uint amount = amounts[i];
            uint newAmount = newAmounts[i];
            address account = accounts[i];
    
            // Perform the same checks and operations as in the single upgradeToken function
            require(_isTokenIssued(tokenId), "Token not issued");
            require(_isTokenIssued(newTokenId), "New token not issued");
            require(_balances[tokenId][account] >= amount, "Insufficient balance");
    
            uint limit = _limits[newTokenId];
            uint availableTokens = (limit == 0 ? type(uint256).max : limit) - _countTokens[newTokenId];
            require(availableTokens >= newAmount, "Insufficient available tokens");
    
            // Update balances
            _balances[tokenId][account] -= amount;
            _balances[newTokenId][account] += newAmount;
    
            // Update issued tokens counts
            _issuedTokens[tokenId] -= amount;
            _issuedTokens[newTokenId] += newAmount;
        }
    }

    function issueTokenCount(
        uint id
    ) external view returns (uint)
    {
        require(_isTokenIssued(id), "Token not issued");
        return _countTokens[id];
    }
    
    function issueTokenCountBatch(
        uint[] memory ids
    ) external view returns (uint[] memory)
    {
        uint[] memory countTokens = new uint[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
        require(_isTokenIssued(ids[i]), "Token not issued");
            countTokens[i] = _countTokens[ids[i]];
        }

        return countTokens;
    }

    function withdrawFunds() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        payable(_owner).transfer(address(this).balance);
        _balance = address(this).balance;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes calldata data
    ) internal {
        require(to != address(0));

        address operator = msg.sender;
        uint[] memory ids = _asSingletonArray(id);
        uint[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint fromBalance = _balances[id][from];
        require(fromBalance >= amount);
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint[] calldata ids,
        uint[] calldata amounts,
        bytes calldata data
    ) internal {
        require(ids.length == amounts.length);

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for(uint i = 0; i < ids.length; ++i) {
            uint id = ids[i];
            uint amount = amounts[i];
            uint fromBalance = _balances[id][from];

            require(fromBalance >= amount);

            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator);
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint id,
        uint amount,
        bytes calldata data
    ) private {
        if(to.code.length > 0) {
            try IERC2014Receiver(to).onERC1155Received(operator, from, id, amount, data) returns(bytes4 resp) {
                if(resp != IERC2014Receiver.onERC1155Received.selector) {
                    revert("Rejected tokens!");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Non-ERC1155 receiver!");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes calldata data
    ) private {
        if(to.code.length > 0) {
            try IERC2014Receiver(to).onERC2014BatchReceived(operator, from, ids, amounts, data) returns(bytes4 resp) {
                if(resp != IERC2014Receiver.onERC2014BatchReceived.selector) {
                    revert("Rejected tokens!");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Non-ERC1155 receiver!");
            }
        }
    }

    function _asSingletonArray(uint el) private pure returns(uint[] memory result) {
        result = new uint[](1);
        result[0] = el;
    }

    function _isTokenIssued(uint id) internal view returns (bool) {
        for (uint i = 0; i < _issuedTokens.length; i++) {
            if (_issuedTokens[i] == id) {
                return true;
            }
        }
        return false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }
}