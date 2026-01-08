// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Luggage } from "../src/examples/Luggage.sol";
import { LibZip } from "../src/solady/LibZip.sol";
import { Test } from "forge-std/Test.sol";

/// @dev Arbitrary callback functions to try to hide calldata inside.
interface RandomCallback {
    function randomCallbackSmall(
        bytes calldata c
    ) external;

    /// @dev Hide the calldata inside a bytes payload as the last word.
    function randomCallback(
        uint256 a,
        uint256 b,
        bytes calldata c
    ) external;

    /// @dev Hide the calldata inside a bytes payload as the last word.
    function randomCallbackLarge(
        bytes32 a,
        bytes32 b,
        uint256 c,
        bytes32 d,
        bytes calldata e
    ) external;

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

contract LuggageTest is Test {
    event Smuggled(uint256 a, bytes b, bytes32 c);

    Luggage luggage;

    function setUp() public {
        luggage = new Luggage();
    }

    /// @dev Reference test
    function test_smuggle() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        vm.expectEmit();
        emit Smuggled(a, b, c);

        luggage.smuggle(a, b, c);
    }

    function test_smuggle_as_callback(
        uint256 noiseA,
        uint256 noiseB
    ) public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Luggage.smuggle, (a, b, c));

        vm.expectEmit();
        emit Smuggled(a, b, c);

        RandomCallback(address(luggage)).randomCallback(noiseA, noiseB, encodedCall);
    }

    function test_smuggle_as_callback_small() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Luggage.smuggle, (a, b, c));

        vm.expectEmit();
        emit Smuggled(a, b, c);

        RandomCallback(address(luggage)).randomCallbackSmall(encodedCall);
    }

    function test_smuggle_as_callback_zipped(
        uint256 noiseA,
        uint256 noiseB
    ) public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Luggage.smuggle, (a, b, c));
        bytes memory compressedCall = LibZip.cdCompress(encodedCall);

        vm.expectEmit();
        emit Smuggled(a, b, c);

        RandomCallback(address(luggage)).randomCallback(noiseA, noiseB, compressedCall);
    }

    function test_smuggle_as_struct_callback() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Luggage.smuggle, (a, b, c));

        uint256[] memory amounts = new uint256[](5);

        RandomCallback.CallbackStruct memory cbs =
            RandomCallback.CallbackStruct({ a: 0, call: encodedCall, amounts: amounts });

        vm.expectEmit();
        emit Smuggled(a, b, c);

        RandomCallback(address(luggage)).randomCallback(cbs);
    }

    function test_smuggle_false_first_hit() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Luggage.smuggle, (a, b, c));

        bytes32 functionSelector = bytes32(Luggage.smuggle.selector);

        vm.expectEmit();
        emit Smuggled(a, b, c);

        // THis should only hit the proper onces, since all "lengths" exceed the call.
        RandomCallback(address(luggage))
            .randomCallbackLarge(functionSelector, functionSelector, 500, functionSelector, encodedCall);
    }
}
