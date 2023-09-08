// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract SpecificNftOwnershipDiscriminator is IGroupMembershipDiscriminator {

    address public owner;
    address public nftContract;
    uint256 public tokenId;

    event OwnerChanged(address indexed _old, address indexed _new);
    event NftContractChanged(address indexed _old, address indexed _new);
    event TokenIdChanged(uint256 _old, uint256 _new);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    constructor(address _owner, address _nftContract, uint256 _tokenId) {
        owner = _owner;
        nftContract = _nftContract;
        tokenId = _tokenId;
    }

    function requireIsMember(address _user) external view {
        require(IERC721(nftContract).ownerOf(tokenId) == _user, "Not a member. You do not own the specified NFT.");
    }

    function isMember(address _user) external view returns(bool) {
        return IERC721(nftContract).ownerOf(tokenId) == _user;
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerChanged(msg.sender, owner);
    }

    function changeNftContract(address _nftContract) external onlyOwner {
        nftContract = _nftContract;
        emit NftContractChanged(nftContract, _nftContract);
    }

    function changeTokenId(uint256 _tokenId) external onlyOwner {
        tokenId = _tokenId;
        emit TokenIdChanged(tokenId, _tokenId);
    }
}
