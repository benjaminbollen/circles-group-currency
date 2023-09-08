// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";

contract NotDiscriminator is IGroupMembershipDiscriminator {

    IGroupMembershipDiscriminator public discriminator;
    address public owner;

    event DiscriminatorChanged(address indexed oldDiscriminator, address indexed newDiscriminator);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor(address _owner, IGroupMembershipDiscriminator _discriminator) {
        owner = _owner;
        discriminator = _discriminator;
    }

    function changeOwner(address newOwner) external onlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
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
