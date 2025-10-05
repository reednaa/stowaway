## Stowaway

Stowaway is a call injection fallback library. It allows a recipient to receive calls they normally wouldn't be able to, by calldata into a bytes field.

### Issue

Many contract callbacks like ERC721, ERC1155, atomic loans, cross-chain swaps, or other types of receive functions use dedicated external calls to embed context & to differentiate their call. There are many ways to handle these calls, one of the these is to identify an embedded call in one of their data fields and then execute the call on self.

### Implementation

it is assumed that all calls that would be caught are _standard_: 4 bytes selector, a number of words, and variable length objects appended after the words. An example of such a call could be

```solidity
function callback(uint256 index, bytes calldata _data) external;
```

This function would have calldata:
```
b2bcfb71 // function selector
0000000000000000000000000000000000000000000000000000000000000001 // uint256 index
0000000000000000000000000000000000000000000000000000000000000040 // Offset to _data
000000000000000000000000000000000000000000000000000000000000000a // Length of _data
48656c6c6f576f726c6400000000000000000000000000000000000000000000 // _data
^^^^^^^^00000000000000000000000000000000000000000000000000000000 // Padding
```

If the bytes field is an encoded payload, the first word of the payload would have the desired function selector. In the above example the examined bytes are marked with `^`.

The search function will go over every word checking if the first 4 bytes of each word matches the expected lookup. Then the previous word (expected to be the length) is checked to be within `calldatassize()`. If both match, the payload will be extracted and delegated-called on self.

### LibZip

In many usecases for this library, calldata may be submitted multiple times on-chain. This techniquie already introduces overhead by double-encoding a solidity call. To mitigate some of this, the library can be used in conjunction with Solady's LibZip:
- If the inverse of the provided function selector is found, no search will be executed.
- If the inverse of the provided function selectir is found, the calldata will also be delegated called on self.

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

