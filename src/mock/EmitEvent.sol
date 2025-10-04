// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Stowaway} from "../Stowaway.sol";

contract EmitEvent {
    event GotData(uint256 a, bytes b, bytes32 c);

    function gotData(uint256 a, bytes calldata b, bytes32 c) external {
        emit GotData(a, b, c);
    }

    fallback() external payable {
        Stowaway.searchAndCall(this.gotData.selector);
    }
}
