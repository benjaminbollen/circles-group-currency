import "../src/IHub.sol";
import "../src/IGroupMembershipDiscriminator.sol";

contract MockAllowAllDiscriminator is IGroupMembershipDiscriminator {
    function requireIsMember(address _group, address _user) external {

    }
    function isMember(address _group, address _user) external returns(bool) {
        return true;
    }
}

contract MockDenyAllDiscriminator is IGroupMembershipDiscriminator {
    function requireIsMember(address _group, address _user) external {
        require(false, "Haha!");
    }
    function isMember(address _group, address _user) external returns(bool) {
        return false;
    }
}

contract MockAllowArrayDiscriminator is IGroupMembershipDiscriminator {
    constructor(address[] memory _members) {
        for (uint256 i = 0; i < _members.length; i++) {
            members[_members[i]] = true;
        }
    }

    function requireIsMember(address _group, address _user) external {
        require(members[_user], "Not a member");
    }
    function isMember(address _group, address _user) external returns(bool) {
        return members[_user];
    }
}
