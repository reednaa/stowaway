// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Stowaway } from "../Stowaway.sol";
import { LibZip } from "../solady/LibZip.sol";

contract Luggage {
    event Smuggled(uint256 a, bytes b, bytes32 c);

    function smuggle(uint256 a, bytes calldata b, bytes32 c) external {
        emit Smuggled(a, b, c);
    }

    fallback() external payable {
        Stowaway.searchAndCall(this.smuggle.selector);
        LibZip.cdFallback();
    }

    receive() external payable { }
}
