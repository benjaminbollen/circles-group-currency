interface IGroupMembershipDiscriminator {
    /**
     * @dev Throws if called with a _user that's not member of the group.
     *      Must revert with a useful error message that can be displayed in UIs.
     */
    function requireIsMember(address _user) external view;

    /**
     * @dev Returns true if _user is member of the group, false otherwise.
     */
    function isMember(address _user) external view returns(bool);
}
