import "./IGroupMembershipDiscriminator.sol";

// The default behavior of a group. Anyone who's trusted by the group is a member.
contract TrustMembershipDiscriminator is IGroupMembershipDiscriminator {
    address hubAddress;

    constructor(address _hubAddress) public {
        hubAddress = _hubAddress;
    }

    function isMember(address _group, address _user) public returns(bool) {
        return IHub(hubAddress).limits(_group, _user) > 0;
    }

    function requireIsMember(address _group, address _user) {
        require(isMember(_group, _user), "User is not trusted by the group.");
    }
}
