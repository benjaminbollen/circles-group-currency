// SPDX-License-Identifier: MIT
import "../IGroupMembershipDiscriminator.sol";

contract MembershipListDiscriminator is IGroupMembershipDiscriminator {

    mapping(address=>bool) public members;

    address public owner;

    event OwnerChanged(address indexed _old, address indexed _new);
    event MemberAdded(address indexed _member);
    event MemberRemoved(address indexed _member);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function requireIsMember(address _user) external view {
        require(members[_user], "Not a member. Ask the owner to add you.");
    }

    function isMember(address _user) external view returns(bool) {
        return members[_user];
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerChanged(msg.sender, owner);
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
