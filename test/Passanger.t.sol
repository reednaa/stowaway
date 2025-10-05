// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Passanger } from "../src/examples/Passanger.sol";
import { Test, console } from "forge-std/Test.sol";

/// @dev Arbitrary callback functions to try to hide calldata inside.
interface RandomCallback {
    /// @dev Hide the calldata inside a bytes payload as the last word.
    function randomCallback(uint256 a, uint256 b, bytes calldata c) external;

    struct CallbackStruct {
        uint256 a;
        uint256[] amounts;
        bytes call;
    }

    /// @dev Hide inside a struct with another variable length object.
    function randomCallback(
        CallbackStruct calldata s
    ) external;
}

contract PassangerTest is Test {
    event Smuggled(uint256 a, bytes b, bytes32 c);

    Passanger passanger;

    function setUp() public {
        passanger = new Passanger();
    }

    /// @dev Reference test
    function test_smuggle() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        vm.expectEmit();
        emit Smuggled(a, b, c);

        passanger.smuggle(a, b, c);
    }

    function test_smuggle_as_callback(uint256 noiseA, uint256 noiseB) public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Passanger.smuggle, (a, b, c));
        console.logBytes(encodedCall);

        vm.expectEmit();
        emit Smuggled(a, b, c);

        RandomCallback(address(passanger)).randomCallback(noiseA, noiseB, encodedCall);
    }

    function test_smuggle_as_struct_callback() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Passanger.smuggle, (a, b, c));
        console.logBytes(encodedCall);

        uint256[] memory amounts = new uint256[](5);

        RandomCallback.CallbackStruct memory cbs =
            RandomCallback.CallbackStruct({ a: 0, call: encodedCall, amounts: amounts });

        vm.expectEmit();
        emit Smuggled(a, b, c);

        RandomCallback(address(passanger)).randomCallback(cbs);
    }
}
