// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../IGroupMembershipDiscriminator.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MembershipListDiscriminator is Ownable, IGroupMembershipDiscriminator {

    mapping(address=>bool) public members;

    event MemberAdded(address indexed _member);
    event MemberRemoved(address indexed _member);

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function requireIsMember(address _user) external view {
        require(members[_user], "Not a member. Ask the owner to add you.");
    }

    function isMember(address _user) external view returns(bool) {
        return members[_user];
    }

    function addMember(address _user) external onlyOwner {
        members[_user] = true;
        emit MemberAdded(_user);
    }

    function removeMember(address _user) external onlyOwner {
        members[_user] = false;
        emit MemberRemoved(_user);
    }
}
