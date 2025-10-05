// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Stowaway {
    /**
     * @notice If Pointer is equal to 0, then nothing was found. Pointer would be 0 IFF the pointer was found in the first word. However, the first word is skipped.
     */
    function searchAndCall(bytes4 searchFor) internal {
        // We expect calldata to be encoded somewhere as abi-encoded bytes.
        // As a result, assuming that a function took 3 arguments the expected calldata will look something like:
        // bytes4(selector)     // offset 0
        // bytes32(word)        // offset 4
        // bytes32(offset to bytes)      // offset 36
        // bytes32(word)        // offset 68
        // bytes32(length of bytes) // offset 100
        // bytes.... // offset 132
        // In that case, we need to detect the function selector in the first 4 bytes of the word of offset 132
        bool skip;
        bytes32 searchForInvert;
        assembly ("memory-safe") {
            // For compatible with Solady's LibZip , we will skip if we discover the function selector to be the invert of _functionSelector.
            searchForInvert := shr(mul(8, 28), not(searchFor))
            skip := eq(shr(mul(8, 28), calldataload(0)), searchForInvert)
        }
        if (skip) return;

        assembly ("memory-safe") {
            // Clean lower bits of searchFor
            searchFor := shr(mul(8, 28), searchFor)

            // The first word that can contain the function selector is the third word. I.e: `call(bytes)` would have encoding:
            // 5a6535fc // Selector
            // 0000000000000000000000000000000000000000000000000000000000000020 // Offset
            // 0000000000000000000000000000000000000000000000000000000000000024 // Length
            // 2b096926.... // Payload
            // Thus init calldataIndex := 4 + 32 + 32
            for { let calldataIndex := 68 } gt(calldatasize(), calldataIndex) {
                calldataIndex := add(calldataIndex, 0x20)
            } {
                let word := shr(mul(8, 28), calldataload(calldataIndex)) // Select 4 leftmost bytes
                let found := or(eq(searchFor, word), eq(searchForInvert, word))
                if found {
                    // Do bounds check and skip if it wouldn't work.
                    let length := calldataload(sub(calldataIndex, 0x20))
                    if gt(add(length, calldataIndex), calldatasize()) { continue }

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
}
