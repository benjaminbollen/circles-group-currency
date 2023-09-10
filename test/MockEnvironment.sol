// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../src/GroupCurrencyTokenFactory.sol";
import "./MockHub.sol";
import "./MockUser.sol";

contract MockEnvironment {

    function hub() external view returns (MockHub) {
        return _hub;
    }
    MockHub public _hub;

    function gctFactory() external view returns (GroupCurrencyTokenFactory) {
        return _gctFactory;
    }
    GroupCurrencyTokenFactory public _gctFactory;

    constructor() {
        _hub = new MockHub();
        _gctFactory = new GroupCurrencyTokenFactory();
    }

    function signup(uint256 initialCrcBalance) external returns (MockUser) {
        MockUser mockUser = new MockUser(this, initialCrcBalance);
        _hub.setTokenToUser(address(mockUser.circlesToken()), mockUser.getUserAddress());

        return mockUser;
    }
}
