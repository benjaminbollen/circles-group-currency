// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../src/IGroupMembershipDiscriminator.sol";

contract BoolDiscriminator is IGroupMembershipDiscriminator {

    bool public value;

    constructor(bool _value) {
        value = _value;
    }

    function requireIsMember(address) external view {
        require(value, "This group membership discriminator is set to 'false'.");
    }
    function isMember(address) external view returns(bool) {
        return value;
    }
}
