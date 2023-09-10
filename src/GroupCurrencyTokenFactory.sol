// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "./GroupCurrencyToken.sol";

contract GroupCurrencyTokenFactory {

    event GroupCurrencyTokenCreated(address indexed _address, address indexed _deployer);

    function create(MintingMode _initialMintingMode, address _discriminator, address _hub, address _treasury, address _owner, uint8 _mintFeePerThousand, string memory _name, string memory _symbol) public returns (GroupCurrencyToken) {
        GroupCurrencyToken gct = new GroupCurrencyToken(
            _initialMintingMode,
            _discriminator,
            _hub,
            _treasury,
            _owner,
            _mintFeePerThousand,
            _name,
            _symbol
        );

        emit GroupCurrencyTokenCreated(address(gct), msg.sender);

        return gct;
    }
}
