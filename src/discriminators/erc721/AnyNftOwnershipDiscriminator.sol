// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

    contract AnyNftOwnershipDiscriminator is IGroupMembershipDiscriminator {

    address public owner;
    address public nftContract;

    event OwnerChanged(address indexed _old, address indexed _new);
    event NftContractChanged(address indexed _old, address indexed _new);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    constructor(address _owner, address _nftContract) {
        owner = _owner;
        nftContract = _nftContract;
    }

    function requireIsMember(address _user) external view {
        require(IERC721(nftContract).balanceOf(_user) > 0, "Not a member. You do not own any NFT of the specified contract.");
    }

    function isMember(address _user) external view returns(bool) {
        return IERC721(nftContract).balanceOf(_user) > 0;
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerChanged(msg.sender, owner);
    }

    function changeNftContract(address _nftContract) external onlyOwner {
        emit NftContractChanged(nftContract, _nftContract);
        nftContract = _nftContract;
    }
}
