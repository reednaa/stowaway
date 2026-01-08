// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Transit } from "../src/examples/Transit.sol";
import { Test, console } from "forge-std/Test.sol";

/// @dev Arbitrary callback functions to try to hide calldata inside.
interface RandomCallback {
    /// @dev Hide the calldata inside a bytes payload as the last word.
    function randomCallback(
        uint256 a,
        uint256 b,
        bytes calldata c
    ) external returns (bytes memory);
}

contract TransitTest is Test {
    Transit transit;

    function setUp() public {
        transit = new Transit();
    }

    function test_pass_data(
        bytes calldata payload
    ) public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        uint256 b = uint256(keccak256(bytes("uint256_2")));

        bytes memory encodedCall = abi.encodeCall(Transit.pass, (true, payload));

        bytes memory ret = RandomCallback(address(transit)).randomCallback(a, b, encodedCall);

        assertEq(ret, payload);
    }

    function test_revert_data(
        bytes calldata payload
    ) public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        uint256 b = uint256(keccak256(bytes("uint256_2")));

        bytes memory encodedCall = abi.encodeCall(Transit.pass, (false, payload));

        vm.expectRevert(abi.encodeWithSelector(Transit.Caught.selector, (payload)));
        RandomCallback(address(transit)).randomCallback(a, b, encodedCall);
    }
}
