// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract DiscriminatorList is Ownable {
    IGroupMembershipDiscriminator[] public discriminators;

    event DiscriminatorAdded(address discriminator);
    event DiscriminatorRemoved(address discriminator);

    function addDiscriminator(IGroupMembershipDiscriminator _discriminator) external virtual onlyOwner {
        discriminators.push(_discriminator);
        emit DiscriminatorAdded(address(_discriminator));
    }

    function removeDiscriminator(uint256 index) external virtual onlyOwner {
        require(index < discriminators.length, "Index out of bounds");
        emit DiscriminatorRemoved(address(discriminators[index]));
        discriminators[index] = discriminators[discriminators.length - 1];
        discriminators.pop();
    }
}
