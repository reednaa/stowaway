// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Stowaway } from "../Stowaway.sol";

contract Transit {
    error Caught(bytes);

    function pass(
        bool success,
        bytes calldata b
    ) external pure returns (bytes calldata) {
        if (!success) revert Caught(b);
        return b;
    }

    fallback() external payable {
        Stowaway.searchAndCall(this.pass.selector);
    }

    receive() external payable { }
}
