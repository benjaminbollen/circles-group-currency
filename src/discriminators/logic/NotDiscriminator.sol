// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract NotDiscriminator is Ownable, IGroupMembershipDiscriminator {

    IGroupMembershipDiscriminator public discriminator;

    event DiscriminatorChanged(address indexed oldDiscriminator, address indexed newDiscriminator);

    constructor(address _owner, IGroupMembershipDiscriminator _discriminator) {
        transferOwnership(_owner);
        discriminator = _discriminator;
    }

    function changeDiscriminator(IGroupMembershipDiscriminator newDiscriminator) external onlyOwner {
        emit DiscriminatorChanged(address(discriminator), address(newDiscriminator));
        discriminator = newDiscriminator;
    }

    function requireIsMember(address _user) external view {
        require(!discriminator.isMember(_user), "Not a member: The underlying discriminator returned true.");
    }

    function isMember(address _user) external view returns(bool) {
        return !discriminator.isMember(_user);
    }
}
