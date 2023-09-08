// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";

contract XorAggregateDiscriminator is IGroupMembershipDiscriminator {

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
        require(newOwner != address(0), "New owner is the zero address");
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
        require(this.isMember(_user), "Not a member according to XOR logic");
    }

    function isMember(address _user) external view returns(bool) {
        uint256 trueCount = 0;
        for(uint i = 0; i < discriminators.length; i++) {
            if(discriminators[i].isMember(_user)) {
                trueCount += 1;
            }
        }
        return trueCount == 1;
    }
}
