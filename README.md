# LI.FI Contract Examples

This repository contains examples of the smart contracts that interact with LI.FI Diamond.

## What is LI.FI?

LI.FI is a cross-chain bridge aggregation protocol that supports any-2-any swaps by aggregating bridges and connecting them to DEX aggregators.
For more information about LI.FI
- [LI.FI Documentation](https://docs.li.fi)
- [LI.FI Smart Contracts](https://github.com/lifinance/contracts)

## How It Works<a name="how-it-works"></a>

1. Send request to the LI.FI API.<br/>
   For more information about LI.FI API, you can check [here](https://docs.li.fi/li.fi-api).
3. Get calldata from the LI.FI API.<br/>
   You can check how to get a quote for a token transfer [here](https://apidocs.li.fi/reference/get_quote).<br/>
   Once you request the quote for a token transfer, you can find the calldata in the `transactionRequest` in response.
5. Pass the calldata, the address of LI.FI Diamond contract and token information to demo contracts.
6. Custom logics can be implemented(as ForwardWithCustomLogic) to do some actions such as swaps, unstaking, etc before forwarding calldata.
7. In the contracts, they set approval for the LI.FI Diamond.
8. Execute the call data on the LI.FI contracts.

## Contract Flow<a name="contract-flow"></a>

```mermaid
graph TD;
    U{dApp}-- 1. Request -->A([LI.FI API])-- 2. calldata -->U;
    U-- 3. Call -->F{Forward Contract};
    F-- 4. Forward calldata -->D{LiFiDiamond};
    D-- DELEGATECALL -->AcrossFacet;
    D-- DELEGATECALL -->HopFacet;
    D-- DELEGATECALL -->HyphenFacet;
    D-- DELEGATECALL -->StargateFacet;
    subgraph Facets
    AcrossFacet
    HopFacet
    HyphenFacet
    StargateFacet
    end
    F{Forward Contract}<-.->C(Custom Logic)<-->P1[Protocol 1] & Pn[Protocol n]
    subgraph Protocols
    P1
    ...:::transparent
    classDef transparent fill:#0000
    classDef transparent stroke:#0000
    Pn
    end
```

To learn more about LI.FI contracts, please check [here](https://docs.li.fi/smart-contracts).

## Repository Structure<a name="repository-structure"></a>

```
contracts
│ README.md                         // you are here
│ ...                               // setup and development configuration files
│
├─── src                            // the contract code
│   ├── interfaces                  // interface definitions
│   ├── utils                       // utility contracts
│   ├── Forward.sol                 // example contract to forward calldata
│   └── ForwardWithCustomLogic.sol  // example contract to forward calldata with custom logic
│
└─── test                           // contract unit tests
    ├─── Forward                    // tests for Forward contract
    └─── ForwardWithCustomLogic     // tests for ForwardWithCustomLogic contract
```
