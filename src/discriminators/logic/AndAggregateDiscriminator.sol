// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";

contract AndAggregateDiscriminator is IGroupMembershipDiscriminator {

    IGroupMembershipDiscriminator[] public discriminators;
    address public owner;

    event DiscriminatorAdded(address discriminator);
    event DiscriminatorRemoved(address discriminator);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor(address _owner, IGroupMembershipDiscriminator[] memory _discriminators) {
        owner = _owner;
        discriminators = _discriminators;
    }

    function changeOwner(address newOwner) external onlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function addDiscriminator(IGroupMembershipDiscriminator _discriminator) external onlyOwner {
        discriminators.push(_discriminator);
        emit DiscriminatorAdded(address(_discriminator));
    }

    function removeDiscriminator(uint256 index) external onlyOwner {
        require(index < discriminators.length, "Index out of bounds");
        emit DiscriminatorRemoved(address(discriminators[index]));
        discriminators[index] = discriminators[discriminators.length - 1];
        discriminators.pop();
    }

    function requireIsMember(address _user) external view {
        for(uint i = 0; i < discriminators.length; i++) {
            discriminators[i].requireIsMember(_user);
        }
    }

    function isMember(address _user) external view returns(bool) {
        for(uint i = 0; i < discriminators.length; i++) {
            if(!discriminators[i].isMember(_user)) {
                return false;
            }
        }
        return true;
    }
}
