// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title Stowaway – Execute hidden bytes encoded calldata.
 * @author Alexander (reednaa.eth)
 * @notice Stowaway is a library intended to help with callback handling. It can search for a function selector in
 * calldata sent to fallback and execute found bytes encoded calldata.
 */
library Stowaway {
    /**
     * @notice Search for a specific function selector (and its inverse) in calldata and execute found function call as
     * delegate-call self.
     * @dev If this function makes an external delegate call, it will directly return the result and terminate the
     * context.
     * If called internally, it must be called at the end of fallback but before LibZip.cdFallback is called.
     * @param searchFor Function selector to search for. Both the normal and inverse function selector will be matched
     * against.
     * Random hits are unlikely given:
     * - Solidity words "small".
     * - If a hit is found, the previous word encoding the length have to be small.
     */
    function searchAndCall(
        bytes4 searchFor
    ) internal {
        // The searched calldata is assumed to be standard double abi-encoded: The calldata is encoded with a 4 bytes
        // function selector following by a number of words, with arbitrary length data prepended. If a bytes element if
        // found starting with the desired selector, the previous word should be the length.
        bool skip;
        bytes32 searchForInvert;
        assembly ("memory-safe") {
            // For compatible with Solady's LibZip, the search is skipped if the invert function selector is found.
            searchForInvert := shr(mul(8, 28), not(searchFor))
            skip := eq(shr(mul(8, 28), calldataload(0)), searchForInvert)
        }
        // exit function context without terminating the context (for libZip).
        if (skip) return;

        assembly ("memory-safe") {
            // Clean lower bits of searchFor
            searchFor := shr(mul(8, 28), searchFor)

            // The first word that can contain the function selector is the third word. I.e: `call(bytes)` would have
            // encoding:
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
