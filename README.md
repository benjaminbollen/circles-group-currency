# Circles Group Currency Token

## Get started
### Prerequisites
* Clone Repo
* Install Foundry

### Run Tests
* `forge test -vvvv`

## Description
### Group Currency Contract

The Group Currency Contract is designed to create and govern a specialized currency for a specific group or community. This contract forms the backbone of your currency system where you can determine rules for creating new tokens (a process called "minting") using Circles (CRC tokens) as collateral.

The owner, a person or entity assigned during the setup of the contract, has substantial control over the contract, dictating who can mint new tokens and introducing new members into the system. Moreover, a fee structure is in place to manage the minting process, a part of which can be allocated to a treasury address for future use.

### Discriminators

In addition to the main contract, we have "discriminators," auxiliary contracts that act as filters or rules used to delineate the membership of the group. These discriminators work based on different logical principles — "AND," "OR," "XOR," and "NOT" — allowing the owner to fine-tune membership criteria through various conditions and combinations.

### How It Works

Imagine a community where you want to issue a new kind of token, a "group currency." The members of your community would then use these tokens amongst themselves for trade and other activities.

To create new tokens, members contribute CRC tokens, held as collateral. The number of new group currency tokens minted is based on the value of these CRC tokens, minus a small fee directed to the treasury for community projects or other utilities.

### Why It's Useful

This system fosters trust and collaboration within a community, providing a decentralized way to manage economic activities. It also ensures flexibility, allowing you to establish your own rules and systems for how your community's economy operates.

Through a combination of the Group Currency Contract and discriminators, communities can craft a personalized economic system, offering a practical tool for decentralized and community-focused financial management. It builds a bridge between the broader Circles ecosystem and smaller, self-governed communities, facilitating trustful economic transactions.

A group currency would define a number of individual Circles tokens directly or transitively (all accounts trusted by account X) as members. All of those members Circles could be used to mint the group currency.

_Note: The GroupCurrencyToken contract is WIP, non-tested, non-audited and not ready for Mainnet/production usage!_


### Contract Methods
* **Constructor**  
   Initializes the new contract with the specified parameters including minting mode, addresses for various roles, the name, and symbol for the new token, among other settings.

* **changeMintingMode(MintingMode _newMode)**  
   Allows the contract owner to change the minting mode to a new mode, provided minting isn't permanently suspended.

* **changeDiscriminator(address _discriminator)**  
   Allows the contract owner to change the discriminator address to a new address.

* **addMember(address _user)**  
   Allows everyone to add a new owner to the group, provided they are accepted by the discriminator.

* **removeMember(address _user)**  
   Allows everyone to remove an owner from the group, provided they aren't accepted by the discriminator.  
   Members can remove themselves from the group. The group owner can remove anyone from the group.

* **mint(address[] calldata _collateral, uint256[] calldata _amount)**  
   Enables users to mint new group currency tokens by providing collateral tokens. The minting process is governed by the current minting mode and the role of the sender in the group.

* **transfer(address _dst, uint256 _wad)**  
   Allows to transfer the group currency tokens to another address.

* **burn(uint256 _amount)**  
   Allows users to burn a specified number of tokens from their account, reducing the total supply.

### Next steps
* Examine the tests in `test/GroupCurrencyTokenTest.sol`

## Patterns
### Allow and deny lists
Use the `MembershipListDiscriminator` to create a list of allowed or denied addresses.
Then negate the deny list with the `NotDiscriminator` and combine both with the `AndAggregateDiscriminator` to create a list of allowed addresses except all the users on the deny list. 
If an address is in both lists, it will be denied.
```solidity
address owner = msg.sender;

address[] defaultAllowList = new address[1];
defaultAllowList[0] = owner;
MembershipListDiscriminator allowList = new MembershipListDiscriminator(owner, defaultAllowList);

address[] defaultDenyList = new address[0];
MembershipListDiscriminator denyList = new MembershipListDiscriminator(owner, defaultDenyList);

IDiscriminator[] discriminators = new IDiscriminator[2];
discriminators[0] = allowList;
discriminators[1] = new NotDiscriminator(owner, denyList);

AndAggregateDiscriminator andDiscriminator = new AndAggregateDiscriminator(owner, discriminators);
GroupCurrencyToken token = new GroupCurrencyToken(
    MintingMode.EverybodyCanMint,
    , address(andDiscriminator)
    , _hub
    , _treasury
    , _owner
    , _mintFeePerThousand
    , _name
    , _symbol);
```

## Call Flows for direct minting

### Direct Minting (Token was trusted by `addMember`)

![](https://i.imgur.com/X9YyadU.png)


## References

* Initial Draft: https://aboutcircles.com/t/suggestion-for-group-currencies/410/4
