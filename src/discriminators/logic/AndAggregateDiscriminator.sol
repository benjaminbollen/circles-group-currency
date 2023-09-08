// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "./DiscriminatorList.sol";
import "../../IGroupMembershipDiscriminator.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract AndAggregateDiscriminator is Ownable, DiscriminatorList, IGroupMembershipDiscriminator {
    constructor(address _owner, IGroupMembershipDiscriminator[] memory _discriminators) {
        transferOwnership(_owner);
        discriminators = _discriminators;
    }

    function requireIsMember(address _user) external view {
        for(uint i = 0; i < discriminators.length; i++) {
            discriminators[i].requireIsMember(_user);
        }
    }

    function isMember(address _user) external view returns(bool) {
        for(uint i = 0; i < discriminators.length; i++) {
            if(!discriminators[i].isMember(_user)) {
                return false;
            }
        }
        return true;
    }
}
