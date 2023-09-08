// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SpecificNftOwnershipDiscriminator is Ownable, IGroupMembershipDiscriminator {

    address public nftContract;
    uint256 public tokenId;

    event NftContractChanged(address indexed _old, address indexed _new);
    event TokenIdChanged(uint256 _old, uint256 _new);

    constructor(address _owner, address _nftContract, uint256 _tokenId) {
        transferOwnership(_owner);
        nftContract = _nftContract;
        tokenId = _tokenId;
    }

    function requireIsMember(address _user) external view {
        require(IERC721(nftContract).ownerOf(tokenId) == _user, "Not a member. You do not own the specified NFT.");
    }

    function isMember(address _user) external view returns(bool) {
        return IERC721(nftContract).ownerOf(tokenId) == _user;
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
