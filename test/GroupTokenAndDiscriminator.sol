// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "./MockUser.sol";
import "../src/GroupCurrencyToken.sol";
import "../src/discriminators/MembershipListDiscriminator.sol";

contract GroupTokenAndDiscriminator {
    MockUser public groupTokenOwner;
    GroupCurrencyToken public groupToken;
    MembershipListDiscriminator public discriminator;

    constructor(MockUser _user, GroupCurrencyToken gct, MembershipListDiscriminator _discriminator) {
        groupTokenOwner = _user;
        groupToken = gct;
        discriminator = _discriminator;
    }

    function setGroupTokenOwner(MockUser _user) external {
        groupTokenOwner = _user;
    }

    function setDiscriminator(MembershipListDiscriminator _discriminator) external {
        discriminator = _discriminator;
    }

    function setGroupToken(GroupCurrencyToken _token) external {
        groupToken = _token;
    }
}

