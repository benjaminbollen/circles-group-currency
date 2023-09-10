// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "./MockEnvironment.sol";
import "./MockToken.sol";
import "../src/discriminators/MembershipListDiscriminator.sol";
import "../src/GroupCurrencyToken.sol";
import "./GroupTokenAndDiscriminator.sol";
import "./MockHub.sol";

contract MockUser {
    function environment() external view returns (MockEnvironment) {
        return _environment;
    }
    MockEnvironment private _environment;
    function circlesToken() external view returns (MockToken) {
        return _circlesToken;
    }
    MockToken private _circlesToken;

    constructor(MockEnvironment env, uint256 initialCrcBalance) {
        _circlesToken = new MockToken("Circles", "CRC", initialCrcBalance);
        _environment = env;
    }

    function getUserAddress() public view returns (address) {
        return address(this);
    }

    function discriminatorAddMember(MembershipListDiscriminator _discriminator, address _user) external {
        _discriminator.addMember(_user);
    }

    function discriminatorRemoveMember(MembershipListDiscriminator _discriminator, address _user) external {
        _discriminator.removeMember(_user);
    }

    function gctAddMember(GroupCurrencyToken _groupToken, address _user) external {
        _groupToken.addMember(_user);
    }

    function gctRemoveMember(GroupCurrencyToken _groupToken, address _user) external {
        _groupToken.removeMember(_user);
    }

    function gctMint(GroupCurrencyToken _groupToken, MockToken _collateralToken, uint256 _amount) external {
        _mint(_groupToken, _collateralToken, _amount);
    }

    function gctSetOnlyOwnerCanMint(GroupCurrencyToken _groupToken) external {
        _groupToken.changeMintingMode(MintingMode.OnlyOwnerCanMint);
    }

    function gctSetOnlyMemberCanMint(GroupCurrencyToken _groupToken) external {
        _groupToken.changeMintingMode(MintingMode.OnlyMembersCanMint);
    }

    function gctSetEveryoneCanMint(GroupCurrencyToken _groupToken) external {
        _groupToken.changeMintingMode(MintingMode.EveryoneCanMint);
    }

    function gctSuspendTemporarily(GroupCurrencyToken _groupToken) external {
        _groupToken.changeMintingMode(MintingMode.TemporarilySuspended);
    }

    function gctSuspendPermanently(GroupCurrencyToken _groupToken) external {
        _groupToken.changeMintingMode(MintingMode.PermanentlySuspended);
    }

    function gctChangeDiscriminator(GroupCurrencyToken _groupToken, address _discriminator) external {
        _groupToken.changeDiscriminator(_discriminator);
    }

    function gctAddMyself(GroupCurrencyToken _groupToken) external {
        _groupToken.addMember(getUserAddress());
    }

    function gctRemoveMyself(GroupCurrencyToken _groupToken) external {
        _groupToken.removeMember(getUserAddress());
    }

    function gctBurn(GroupCurrencyToken _groupToken, uint256 _amount) external {
        _groupToken.burn(_amount);
    }

    function gctTransfer(GroupCurrencyToken _groupToken, address _to, uint256 _amount) external {
        _groupToken.transfer(_to, _amount);
    }

    function crcTransfer(MockToken token, address _to, uint256 _amount) public {
        token.transfer(_to, _amount);
    }

    function _mint(GroupCurrencyToken _groupToken, MockToken collateralToken, uint256 _amount) private {
        address[] memory _collateral = new address[](1);
        _collateral[0] = address(collateralToken);
        uint256[] memory _amountArr = new uint256[](1);
        _amountArr[0] = _amount;
        _groupToken.mint(_collateral, _amountArr);
    }

    function createEmptyGroupCurrency(
        MintingMode _initialMintingMode,
        uint8 _mintFeePerThousand
    ) external returns (GroupTokenAndDiscriminator) {
        address[] memory emtpyAllowedUsers = new address[](0);
        return createGroupCurrency(_initialMintingMode, emtpyAllowedUsers, false, _mintFeePerThousand);
    }

    function createGroupCurrency(
        MintingMode _initialMintingMode
    , address[] memory allowedUsers
    , bool addAllowedUsers
    , uint8 _mintFeePerThousand
    ) public returns (GroupTokenAndDiscriminator) {
        MembershipListDiscriminator discriminator = new MembershipListDiscriminator(this.getUserAddress(), allowedUsers);
        GroupCurrencyToken groupToken = this.environment()._gctFactory().create(
            _initialMintingMode
            , address(discriminator)
            , address(this.environment().hub())
            , this.getUserAddress()
            , this.getUserAddress()
            , _mintFeePerThousand
            , "GCT"
            , "GCT"
        );
        if (addAllowedUsers) {
            for(uint i = 0; i < allowedUsers.length; i++) {
                groupToken.addMember(allowedUsers[i]);
            }
        }
        return new GroupTokenAndDiscriminator(this, groupToken, discriminator);
    }

    function createSingleMemberGroupCurrency(MintingMode initialMintingMode, address allowedUser, bool addUser, uint8 _mintFeePerThousand) external returns (GroupTokenAndDiscriminator) {
        address[] memory allowedUsers = new address[](1);
        allowedUsers[0] = allowedUser;
        GroupTokenAndDiscriminator gct = createGroupCurrency(initialMintingMode, allowedUsers, addUser, _mintFeePerThousand);
        if (addUser) {
            gct.groupToken().addMember(allowedUser);
        }
        return gct;
    }
}
