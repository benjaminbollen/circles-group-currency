// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IGroupMembershipDiscriminator.sol";
import "./IHub.sol";
import "./MintingMode.sol";

contract GroupCurrencyToken is Ownable, ERC20  {

    using SafeERC20 for ERC20;

    uint256 constant private FULL_TRUST_PERCENTAGE = 100;
    uint256 constant private NO_TRUST_PERCENTAGE = 0;
    uint256 constant private DIVISOR_THOUSAND = 1000;

    uint8 public mintFeePerThousand;

    MintingMode public currentMintingMode;

    address public discriminator; // the address of the discriminator contract that determines who is a member, can be changed by owner
    address immutable public hub; // the address of the hub this token is associated with
    address immutable public treasury; // account which gets the personal tokens for whatever later usage

    event MemberAdded(address indexed _member);
    event MemberRemoved(address indexed _member);
    event Minted(address indexed _receiver, uint256 _amount, uint256 _mintAmount, uint256 _mintFee);
    event MintingModeChanged(address indexed _owner, MintingMode oldMode, MintingMode newMode);
    event DiscriminatorChanged(address indexed _old, address indexed _new);

    constructor(MintingMode _initialMintingMode, address _discriminator, address _hub, address _treasury, address _owner, uint8 _mintFeePerThousand, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        currentMintingMode = _initialMintingMode;
        discriminator = _discriminator;
        hub = _hub;
        treasury = _treasury;
        mintFeePerThousand = _mintFeePerThousand;
        transferOwnership(_owner);
        IHub(hub).organizationSignup();
    }

    function changeMintingMode(MintingMode _newMode) external onlyOwner {
        require(currentMintingMode != MintingMode.PermanentlySuspended, "Minting is permanently suspended.");
        if (_newMode == currentMintingMode) {
            return;
        }
        emit MintingModeChanged(owner(), currentMintingMode, _newMode);
        currentMintingMode = _newMode;
    }

    function changeDiscriminator(address _discriminator) external onlyOwner {
        emit DiscriminatorChanged(discriminator, _discriminator);
        discriminator = _discriminator;
    }

    function addMember(address _user) external {
        // Discriminator can add anyone.
        require(_user != address(0), "member must be valid address");
        IGroupMembershipDiscriminator(discriminator).requireIsMember(_user);

        _directTrust(_user, FULL_TRUST_PERCENTAGE);
        emit MemberAdded(_user);
    }

    function removeMember(address _user) external {
        // Discriminator can remove anyone.
        // Members can remove themself.
        // Owner can remove anyone.
        require(_user != address(0), "member must be valid address");
        require(!IGroupMembershipDiscriminator(discriminator).isMember(_user)
          || msg.sender == _user
          || msg.sender == owner(), "Only members themself or the owner can remove members if they're still accepted by the discriminator.");

        _directTrust(_user, NO_TRUST_PERCENTAGE);
        emit MemberRemoved(_user);
    }

    // Group currently is created from collateral tokens, which have to be transferred to this Token before.
    // Note: This function is not restricted, so anybody can mint with the collateral Token! The function call must be transactional to be safe.
    function mint(address[] calldata _collateral, uint256[] calldata _amount) external returns (uint256) {
        require(currentMintingMode != MintingMode.PermanentlySuspended, "Minting is permanently suspended.");
        require(currentMintingMode != MintingMode.TemporarilySuspended, "Minting is temporarily suspended.");
        // Check status
        if (currentMintingMode == MintingMode.OnlyOwnerCanMint) {
            require(msg.sender == owner(), "Only owner can mint");
        }
        if (currentMintingMode == MintingMode.OnlyMembersCanMint) {
            require(IGroupMembershipDiscriminator(discriminator).isMember(msg.sender), "Only members can mint");
            require(IHub(hub).limits(address(this), msg.sender) > 0, "You're not yet trusted. Call 'addMember' first.");
        }
        uint mintedAmount;
        for (uint i = 0; i < _collateral.length; i++) {
            mintedAmount += _mintGroupCurrencyTokenForCollateral(_collateral[i], _amount[i]);
        }
        return mintedAmount;
    }

    function transfer(address _dst, uint256 _wad) public override returns (bool) {
        // this code shouldn't be necessary, but when it's removed the gas estimation methods
        // in the gnosis safe no longer work, still true as of solidity 7.1
        return super.transfer(_dst, _wad);
    }

    function _mintGroupCurrencyTokenForCollateral(address _collateral, uint256 _amount) internal returns (uint256) {
        // Check if the Collateral Owner is trusted by this GroupCurrencyToken
        address collateralOwner = IHub(hub).tokenToUser(_collateral);
        require(IGroupMembershipDiscriminator(discriminator).isMember(collateralOwner), "collateral owner not a member");
        require(IHub(hub).limits(address(this), collateralOwner) > 0, "collateral owner not trusted");

        uint256 mintFee = (_amount * mintFeePerThousand) / DIVISOR_THOUSAND;
        require(mintFeePerThousand == 0 || mintFee > 0);
        uint256 mintAmount = _amount - mintFee;

        // mint amount-fee to msg.sender
        _mint(msg.sender, mintAmount);
        // Token Swap, send CRC from GCTO to Treasury (has been transferred to GCTO by transferThrough)
        ERC20(_collateral).safeTransfer(treasury, _amount);
        emit Minted(msg.sender, _amount, mintAmount, mintFee);

        return mintAmount;
    }

    // Trust must be called by this contract (as a delegate) on Hub
    function _directTrust(address _trustee, uint _amount) internal {
        IHub(hub).trust(_trustee, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
