// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../../IGroupMembershipDiscriminator.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract ERC20BalanceHigherOrEqualDiscriminator is Ownable, IGroupMembershipDiscriminator {

    address public erc20Contract;
    uint256 public balanceThreshold;

    event ERC20ContractChanged(address indexed _old, address indexed _new);
    event BalanceThresholdChanged(uint256 _old, uint256 _new);

    constructor(address _owner, address _erc20Contract, uint256 _balanceThreshold) {
        transferOwnership(_owner);
        erc20Contract = _erc20Contract;
        balanceThreshold = _balanceThreshold;
    }

    function requireIsMember(address _user) external view {
        require(IERC20(erc20Contract).balanceOf(_user) >= balanceThreshold, "Not a member. Your ERC20 balance is below the required threshold.");
    }

    function isMember(address _user) external view returns(bool) {
        return IERC20(erc20Contract).balanceOf(_user) >= balanceThreshold;
    }

    function changeERC20Contract(address _erc20Contract) external onlyOwner {
        emit ERC20ContractChanged(erc20Contract, _erc20Contract);
        erc20Contract = _erc20Contract;
    }

    function changeBalanceThreshold(uint256 _balanceThreshold) external onlyOwner {
        emit BalanceThresholdChanged(balanceThreshold, _balanceThreshold);
        balanceThreshold = _balanceThreshold;
    }
}
