## Stowaway

This repository contains a proof of concept for an arbitrary calldata injection. Most cross-chain interactions or same-chain fallbacks relies on specific functions being externally called. It is a security feature to ensure nobody can execute arbitrary code on-behalf of a contract. Some alternative implementations works by sending calldata through a secondary contract that then transparently executes the calldata.

For may cross-chain interactions may want additional code to be executed on succesful delivery of assets. However, integrating every possible receive function is both nearly impossible but would also increase gas cost significantly. The alternative would be for cross-chain system to all agree to a single callback interface.

### Implementation

The search function will go over every word checking if the first 4 bytes of each word matches the expected lookup. If it does, the decoded payload will be delegate'called on itself.

## Usage

Implement the contract and expose your desired function selector to search for. Then imbed your calldata into the callback function and let your contract receive calls.

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

