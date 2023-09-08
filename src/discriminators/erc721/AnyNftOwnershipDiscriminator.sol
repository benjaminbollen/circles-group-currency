// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract AnyNftOwnershipDiscriminator is Ownable, IGroupMembershipDiscriminator {

    address public nftContract;

    event NftContractChanged(address indexed _old, address indexed _new);

    constructor(address _owner, address _nftContract) {
        transferOwnership(_owner);
        nftContract = _nftContract;
    }

    function requireIsMember(address _user) external view {
        require(IERC721(nftContract).balanceOf(_user) > 0, "Not a member. You do not own any NFT of the specified contract.");
    }

    function isMember(address _user) external view returns(bool) {
        return IERC721(nftContract).balanceOf(_user) > 0;
    }

    function changeNftContract(address _nftContract) external onlyOwner {
        emit NftContractChanged(nftContract, _nftContract);
        nftContract = _nftContract;
    }
}
