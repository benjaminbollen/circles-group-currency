interface IGroupMembershipDiscriminator {
    function requireIsMember(address _group, address _user) external;
    function isMember(address _group, address _user) public returns(bool);
}
