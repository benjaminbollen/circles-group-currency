import "./GroupCurrencyToken.sol";
contract GroupCurrencyTokenFactory {

    event GroupCurrencyTokenCreated(address indexed _address, address indexed _deployer);

    function createGroupCurrencyToken(address _discriminator, address _hub, address _treasury, address _owner, uint8 _mintFeePerThousand, string memory _name, string memory _symbol) public {
        GroupCurrencyToken gct = new GroupCurrencyToken(
            _discriminator,
            _hub,
            _treasury,
            _owner,
            _mintFeePerThousand,
            _name,
            _symbol
        );
        emit GroupCurrencyTokenCreated(address(gct), msg.sender);
    }

}
