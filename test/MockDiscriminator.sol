import "../src/IHub.sol";
import "../src/IGroupMembershipDiscriminator.sol";

contract MockAllowAllDiscriminator is IGroupMembershipDiscriminator {
    function requireIsMember(address _user) external view {

    }
    function isMember(address _user) external view returns(bool) {
        return true;
    }
}

contract MockDenyAllDiscriminator is IGroupMembershipDiscriminator {
    function requireIsMember(address _user) external  view {
        require(false, "Haha!");
    }
    function isMember(address _user) external view returns(bool) {
        return false;
    }
}

contract MockAllowArrayDiscriminator is IGroupMembershipDiscriminator {
    mapping(address=>bool) public members;

    constructor(address[] memory _members) {
        for (uint256 i = 0; i < _members.length; i++) {
            members[_members[i]] = true;
        }
    }

    function requireIsMember(address _user) external view {
        require(members[_user], "Not a member");
    }
    function isMember(address _user) external view returns(bool) {
        return members[_user];
    }
}
