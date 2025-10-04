// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

abstract contract RetryCall {
    function _functionSelector() internal pure virtual returns (bytes4);

    /**
     * @notice If Pointer is equal to 0, then nothing was found. Pointer would be 0 IFF the pointer was found in the first word. However, the first word is skipped.
     */
    function _searchAndCall() internal {
        // We expect calldata to be encoded somewhere as abi-encoded bytes.
        // As a result, assuming that a function took 3 arguments the expected calldata will look something like:
        // bytes4(selector)     // offset 0
        // bytes32(word)        // offset 4
        // bytes32(offset to bytes)      // offset 36
        // bytes32(word)        // offset 68
        // bytes32(length of bytes) // offset 100
        // bytes.... // offset 132
        // In that case, we need to detect the function selector in the first 4 bytes of the word of offset 132.

        bytes4 searchFor = _functionSelector();
        uint256 cdSize;

        assembly ("memory-safe") {
            // Clean lower bits of searchFor
            searchFor := shr(mul(8, 28), searchFor)

            cdSize := calldatasize()

            for { let calldataIndex := 36 } gt(cdSize, calldataIndex) { calldataIndex := add(calldataIndex, 0x20) } {
                let word := calldataload(calldataIndex)
                let found :=
                        eq(
                            // If they all match, the xor will be 0.
                            xor(searchFor, shr(mul(8, 28), word)), // Select 4 leftmost bytes
                            0
                        )
                if found {
                    // Do bounds check and skip if it wouldn't work.
                    let length := calldataload(sub(calldataIndex, 0x20))
                    if gt(add(length, calldataIndex), calldatasize()) {
                        continue
                    }
                    
                    // get the free memory pointer.
                    let m := mload(0x40)

                    // Copy the size of the calldata to memory.
                    calldatacopy(m, calldataIndex, length)

                    let success := delegatecall(gas(), address(), m, length, codesize(), 0x00)
                    returndatacopy(0x00, 0x00, returndatasize())
                    if iszero(success) { revert(0x00, returndatasize()) }
                    return(0x00, returndatasize())
                }
            }
        }
    }

    modifier fallbackSearchSelector() {
        console.logBytes(msg.data);
        _searchAndCall();
        _;
    }

    fallback() external payable virtual fallbackSearchSelector {}

    receive() external payable virtual {}
}
