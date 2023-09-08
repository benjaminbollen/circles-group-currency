# Group Currency Token Smart Contract
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

## Call Flows for direct minting and delegate minting

### Direct Minting (Token was trusted by `addMember`)

![](https://i.imgur.com/X9YyadU.png)

## Tech Walk-Through

There are two possibilities to explore the functionality of GCT:

1. Examine the unit tests in `test/GroupCurrencyTokenTest`
2. Examine the integration test in `scripts/GroupCurrencyToken.s.sol`

## Prerequisites

* Install Foundry

## Setup

* Clone Repo

## Run (Tests)

* `forge test -vvvv`

## Gnosis Chain Integration Tests

* `forge script script/GroupCurrencyToken.s.sol -vvvv --fork-url=
https://rpc.gnosischain.com`

## References

* Initial Draft: https://aboutcircles.com/t/suggestion-for-group-currencies/410/4
