// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

pragma abicoder v2;

import "../lib/forge-std/src/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/GroupCurrencyToken.sol";
import "../src/IHub.sol";
import "./MockHub.sol";
import "./MockToken.sol";
import "../src/discriminators/MembershipListDiscriminator.sol";
import "./MockEnvironment.sol";
import "./MockUser.sol";

contract GroupCurrencyTokenTest is Test {

    event Trust(address indexed _canSendTo, address indexed _user, uint256 _limit);
    event OrganizationSignup(address indexed _organization);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event MemberAdded(address indexed _Member);
    event MemberRemoved(address indexed _Member);
    event MintingModeChanged(address indexed _owner, MintingMode oldMode, MintingMode newMode);
    event DiscriminatorChanged(address indexed oldDiscriminator, address indexed newDiscriminator);
    event Minted(address indexed _receiver, uint256 _amount, uint256 _mintAmount, uint256 _mintFee);

    MockEnvironment mockEnv = new MockEnvironment();

    function _setupGctMinting(MockUser user, GroupTokenAndDiscriminator gct, MockToken collateralToken, uint256 amount, bool expectEvents) private {
        vm.expectEmit(true, true, false, false);
        emit Transfer(user.getUserAddress(), address(gct.groupToken()), amount);

        address[] memory cols = new address[](1);
        cols[0] = address(collateralToken);
        uint256[] memory tokens = new uint256[](1);
        tokens[0] = amount;
        user.crcTransfer(collateralToken, address(gct.groupToken()), amount);

        if (expectEvents) {
            vm.expectEmit(false, false, false, false);
            emit Transfer(0x0000000000000000000000000000000000000000, user.getUserAddress(), amount);
            vm.expectEmit(false, false, false, false);
            emit Transfer(address(gct.groupToken()), user.getUserAddress(), amount);

            vm.expectEmit(true, true, false, true, address(gct.groupToken()));
            emit Minted(user.getUserAddress(), amount, amount, 0);
        }
    }


    // This test validates the temporary suspension of the minting functionality.
    // Initially, it sets up a GroupCurrencyToken (GCT) and performs minting operations, after which it temporarily suspends minting.
    // The test then verifies that minting fails during the suspension period and succeeds again after resuming normal operations.
    function testSuspendTemporarily() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.EveryoneCanMint, user.getUserAddress(), true, 0);

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MintingModeChanged(address(user.getUserAddress()), MintingMode.EveryoneCanMint, MintingMode.TemporarilySuspended);

        user.gctSuspendTemporarily(gct.groupToken());

        _setupGctMinting(user, gct, user.circlesToken(), 50, false);
        try user.gctMint(gct.groupToken(), user.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Minting is temporarily suspended.");
        }

        user.gctSetOnlyOwnerCanMint(gct.groupToken());

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);
    }

    // This test validates the permanent suspension of the minting functionality.
    // It initially sets up a GCT and mints tokens.
    // It then permanently suspends minting and confirms that minting fails, and no changes can be made to the minting mode thereafter.
    function testSuspendPermanently() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.EveryoneCanMint, user.getUserAddress(), true, 0);

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MintingModeChanged(address(user.getUserAddress()), MintingMode.EveryoneCanMint, MintingMode.PermanentlySuspended);

        user.gctSuspendPermanently(gct.groupToken());

        _setupGctMinting(user, gct, user.circlesToken(), 50, false);
        try user.gctMint(gct.groupToken(), user.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Minting is permanently suspended.");
        }

        try user.gctSetOnlyOwnerCanMint(gct.groupToken()) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Minting is permanently suspended.");
        }
    }

    // This test confirms that the DiscriminatorChanged event is correctly emitted when the discriminator associated with a group token is altered.
    function testEmitDiscriminatorChanged() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createEmptyGroupCurrency(MintingMode.EveryoneCanMint, 0);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit DiscriminatorChanged(address(gct.discriminator()), gct.groupTokenOwner().getUserAddress());

        user.gctChangeDiscriminator(gct.groupToken(), gct.groupTokenOwner().getUserAddress());
    }

    // This test verifies that the minting fee is correctly applied.
    // It confirms that the minted amount is reduced by the appropriate fee and that the Minted event correctly reflects the fee applied.
    function testMintFee() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.EveryoneCanMint, user.getUserAddress(), true, 100);

        assertEq(gct.groupToken().mintFeePerThousand(), 100);

        _setupGctMinting(user, gct, user.circlesToken(), 50, false);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit Minted(user.getUserAddress(), 50, 45, 5);

        user.gctMint(gct.groupToken(), user.circlesToken(), 50);
    }

    // This test verifies the system's response to minting attempts with untrusted collateral.
    // Initially, it shows a failed minting attempt due to untrusted collateral, followed by the establishment of trust and a successful minting operation.
    function testMintWithUntrustedCollateral() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createEmptyGroupCurrency(MintingMode.EveryoneCanMint, 0);

        user.discriminatorAddMember(gct.discriminator(), user.getUserAddress());

        _setupGctMinting(user, gct, user.circlesToken(), 50, false);
        try user.gctMint(gct.groupToken(), user.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "collateral owner not trusted");
        }

        vm.expectEmit(true, true, false, true, address(user.environment().hub()));
        emit Trust(address(gct.groupToken()), user.getUserAddress(), 100);

        user.gctAddMyself(gct.groupToken());

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);
    }

    // This test validates the functionality where only the owner can mint tokens.
    // It first changes the minting mode to "OnlyOwnerCanMint" and verifies that other users can't mint.
    // It then demonstrates that only the owner can successfully mint tokens, even if other users are added to a trust relationship or the group.
    function testOnlyOwnerCanMint() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        MockUser otherUser = mockEnv.signup(50000000000000000000);
        address[] memory allowedUsers = new address[](2);
        allowedUsers[0] = user.getUserAddress();
        allowedUsers[1] = otherUser.getUserAddress();
        GroupTokenAndDiscriminator gct = user.createGroupCurrency(MintingMode.EveryoneCanMint, allowedUsers, true, 0);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MintingModeChanged(address(user.getUserAddress()), MintingMode.EveryoneCanMint, MintingMode.OnlyOwnerCanMint);

        user.gctSetOnlyOwnerCanMint(gct.groupToken());

        _setupGctMinting(otherUser, gct, otherUser.circlesToken(), 50, false);
        try otherUser.gctMint(gct.groupToken(), otherUser.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Only owner can mint");
        }

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);

        vm.expectEmit(true, true, false, true, address(user.environment().hub()));
        emit Trust(address(gct.groupToken()), otherUser.getUserAddress(), 100);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MemberAdded(otherUser.getUserAddress());

        otherUser.gctAddMyself(gct.groupToken());
        try otherUser.gctMint(gct.groupToken(), otherUser.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Only owner can mint");
        }
    }

    // This test validates the scenario where only members can mint tokens.
    // It checks the minting restrictions by trying to mint as a non-member, followed by successful minting operations as a member.
    // It also tests the removal of members and the consequent minting restrictions.
    function testOnlyMemberCanMint() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        MockUser otherUser = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.EveryoneCanMint, otherUser.getUserAddress(), true, 0);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MintingModeChanged(address(user.getUserAddress()), MintingMode.EveryoneCanMint, MintingMode.OnlyMembersCanMint);

        user.gctSetOnlyMemberCanMint(gct.groupToken());

        _setupGctMinting(user, gct, user.circlesToken(), 50, false);

        try user.gctMint(gct.groupToken(), user.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Only members can mint");
        }

        _setupGctMinting(otherUser, gct, otherUser.circlesToken(), 50, true);
        otherUser.gctMint(gct.groupToken(), otherUser.circlesToken(), 50);

        user.discriminatorAddMember(gct.discriminator(), user.getUserAddress());
        user.gctAddMyself(gct.groupToken());

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);

        user.discriminatorRemoveMember(gct.discriminator(), user.getUserAddress());
    }

    // This test confirms that in the "EveryoneCanMint" mode, any user can mint tokens using trusted collateral.
    // It tests the minting operations using trusted and untrusted collateral, and after changing minting modes, confirming that the rules apply correctly in each scenario.
    function testEveryoneCanMint() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        MockUser otherUser = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.EveryoneCanMint, user.getUserAddress(), true, 0);

        // Transfer trusted collateral from 'user' to 'otherUser'
        user.crcTransfer(user.circlesToken(), otherUser.getUserAddress(), 150);

        // Try to mint using the previously transferred collateral -> expect success
        _setupGctMinting(otherUser, gct, user.circlesToken(), 50, true);
        otherUser.gctMint(gct.groupToken(), user.circlesToken(), 50);

        // Try to mint using untrusted collateral -> expect error
        _setupGctMinting(otherUser, gct, otherUser.circlesToken(), 50, false);
        try otherUser.gctMint(gct.groupToken(), otherUser.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "collateral owner not a member");
        }

        // Change minting mode to 'OnlyMembersCanMint'
        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MintingModeChanged(address(user.getUserAddress()), MintingMode.EveryoneCanMint, MintingMode.OnlyMembersCanMint);

        user.gctSetOnlyMemberCanMint(gct.groupToken());

        // Try to mint using the previously transferred collateral -> expect error
        _setupGctMinting(otherUser, gct, user.circlesToken(), 50, false);
        try otherUser.gctMint(gct.groupToken(), user.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Only members can mint");
        }

        // Change minting mode back to 'EveryoneCanMint'
        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MintingModeChanged(address(user.getUserAddress()), MintingMode.OnlyMembersCanMint, MintingMode.EveryoneCanMint);

        user.gctSetEveryoneCanMint(gct.groupToken());

        // Try to mint using the previously transferred collateral -> expect success
        _setupGctMinting(otherUser, gct, user.circlesToken(), 50, true);
        otherUser.gctMint(gct.groupToken(), user.circlesToken(), 50);
    }

    // This function tests adding a member to a Group Token And Discriminator (GCT).
    // It verifies that only trusted users can mint tokens and members must be added first before they can mint tokens.
    function testAddMember() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.OnlyMembersCanMint, user.getUserAddress(), false, 0);

        _setupGctMinting(user, gct, user.circlesToken(), 50, false);
        try user.gctMint(gct.groupToken(), user.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            // User is qualified to be member but isn't yet trusted by the GCT and thus not a member.
            assertEq(reason, "You're not yet trusted. Call 'addMember' first.");
        }

        vm.expectEmit(true, true, false, true, address(user.environment().hub()));
        emit Trust(address(gct.groupToken()), user.getUserAddress(), 100);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MemberAdded(user.getUserAddress());

        gct.groupToken().addMember(user.getUserAddress());

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);

        try user.discriminatorAddMember(gct.discriminator(), address(0)) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "member must be valid address");
        }

        try user.gctAddMember(gct.groupToken(), address(0)) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "member must be valid address");
        }
    }

    // This function tests removing a member from a GCT.
    // It confirms that members can remove themselves or be removed by the owner even if they are still accepted by the discriminator.
    // It handles errors for invalid address input and unauthorized removal attempts.
    function testRemoveMember() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        MockUser anyUser = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.OnlyMembersCanMint, user.getUserAddress(), true, 0);

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);

        vm.expectEmit(true, true, false, true, address(user.environment().hub()));
        emit Trust(address(gct.groupToken()), user.getUserAddress(), 0);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MemberRemoved(user.getUserAddress());

        user.gctRemoveMyself(gct.groupToken());

        _setupGctMinting(user, gct, user.circlesToken(), 50, false);
        try user.gctMint(gct.groupToken(), user.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "You're not yet trusted. Call 'addMember' first.");
        }

        try user.gctRemoveMember(gct.groupToken(), address(0)) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "member must be valid address");
        }

        try anyUser.gctRemoveMember(gct.groupToken(), user.getUserAddress()) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Only members themself or the owner can remove members if they're still accepted by the discriminator.");
        }
    }

    // This function tests burning tokens in a GCT.
    // It mints some tokens first and then burns them, checking for the correct events to be emitted.
    function testBurnGCT() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.OnlyMembersCanMint, user.getUserAddress(), true, 0);

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit Transfer(user.getUserAddress(), address(0), 50);

        user.gctBurn(gct.groupToken(), 50);
    }

    // This function tests transferring GCT tokens between users.
    // It mints some tokens and then transfers them to another user, ensuring the correct events are emitted.
    function testTransferGCT() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        MockUser otherUser = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.OnlyMembersCanMint, user.getUserAddress(), true, 0);

        _setupGctMinting(user, gct, user.circlesToken(), 50, true);
        user.gctMint(gct.groupToken(), user.circlesToken(), 50);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit Transfer(user.getUserAddress(), otherUser.getUserAddress(), 50);

        user.gctTransfer(gct.groupToken(), otherUser.getUserAddress(), 50);
    }

    // This function tests if a member can remove themselves from a GCT.
    // It mints some tokens, removes the user from the GCT, and then tries to mint tokens again, which should fail.
    function testMemberCanRemoveThemselves() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        MockUser otherUser = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.OnlyMembersCanMint, otherUser.getUserAddress(), true, 0);

        _setupGctMinting(otherUser, gct, otherUser.circlesToken(), 50, true);
        otherUser.gctMint(gct.groupToken(), otherUser.circlesToken(), 50);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MemberRemoved(otherUser.getUserAddress());

        otherUser.gctRemoveMyself(gct.groupToken());

        _setupGctMinting(otherUser, gct, otherUser.circlesToken(), 50, false);
        try otherUser.gctMint(gct.groupToken(), otherUser.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "You're not yet trusted. Call 'addMember' first.");
        }
    }

    // This function tests if the owner can remove any member from a GCT.
    // It mints some tokens, removes a member using the owner account, and then attempts to mint tokens again with the removed member account, which should fail.
    function testOwnerCanRemoveAnyMember() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        MockUser anyMember = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.OnlyMembersCanMint, anyMember.getUserAddress(), true, 0);

        _setupGctMinting(anyMember, gct, anyMember.circlesToken(), 50, true);
        anyMember.gctMint(gct.groupToken(), anyMember.circlesToken(), 50);

        vm.expectEmit(true, true, false, true, address(user.environment().hub()));
        emit Trust(address(gct.groupToken()), anyMember.getUserAddress(), 0);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MemberRemoved(anyMember.getUserAddress());

        user.gctRemoveMember(gct.groupToken(), anyMember.getUserAddress());

        _setupGctMinting(anyMember, gct, anyMember.circlesToken(), 50, false);
        try anyMember.gctMint(gct.groupToken(), anyMember.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "You're not yet trusted. Call 'addMember' first.");
        }
    }

    // This function tests removing trust for denied members in a GCT.
    // It confirms that any user can remove trust for members who are denied by the discriminator, thereby removing them from the GCT, and making them unable to mint tokens.
    function testAnybodyCanRemoveTrustForDeniedMembers() external {
        MockUser user = mockEnv.signup(50000000000000000000);
        MockUser otherUser = mockEnv.signup(50000000000000000000);
        MockUser anyUser = mockEnv.signup(50000000000000000000);
        GroupTokenAndDiscriminator gct = user.createSingleMemberGroupCurrency(MintingMode.OnlyMembersCanMint, otherUser.getUserAddress(), true, 0);

        _setupGctMinting(otherUser, gct, otherUser.circlesToken(), 50, true);
        otherUser.gctMint(gct.groupToken(), otherUser.circlesToken(), 50);

        user.discriminatorRemoveMember(gct.discriminator(), otherUser.getUserAddress());

        vm.expectEmit(true, true, false, true, address(user.environment().hub()));
        emit Trust(address(gct.groupToken()), otherUser.getUserAddress(), 0);

        vm.expectEmit(true, true, false, true, address(gct.groupToken()));
        emit MemberRemoved(otherUser.getUserAddress());

        anyUser.gctRemoveMember(gct.groupToken(), otherUser.getUserAddress());

        _setupGctMinting(otherUser, gct, otherUser.circlesToken(), 50, false);
        try otherUser.gctMint(gct.groupToken(), otherUser.circlesToken(), 50) {
            fail("Should have thrown.");
        } catch Error(string memory reason) {
            assertEq(reason, "Only members can mint");
        }
    }
}
