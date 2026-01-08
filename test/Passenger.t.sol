// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Passenger } from "../src/examples/Passenger.sol";
import { Test } from "forge-std/Test.sol";
import { RandomCallback} from "./Luggage.t.sol";

contract PassengerTest is Test {
    event Smuggled(uint256 a, bytes b, bytes32 c);

    Passenger passenger;

    function setUp() public {
        passenger = new Passenger();
    }

    /// @dev Reference test
    function test_smuggle() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        vm.expectEmit();
        emit Smuggled(a, b, c);

        passenger.smuggle(a, b, c);
    }

    function test_smuggle_as_callback(
        uint256 noiseA,
        uint256 noiseB
    ) public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Passenger.smuggle, (a, b, c));

        vm.expectEmit();
        emit Smuggled(a, b, c);

        RandomCallback(address(passenger)).randomCallback(noiseA, noiseB, encodedCall);
    }

    function test_smuggle_as_struct_callback() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Passenger.smuggle, (a, b, c));

        uint256[] memory amounts = new uint256[](5);

        RandomCallback.CallbackStruct memory cbs =
            RandomCallback.CallbackStruct({ a: 0, call: encodedCall, amounts: amounts });

        vm.expectEmit();
        emit Smuggled(a, b, c);

        RandomCallback(address(passenger)).randomCallback(cbs);
    }

    function test_smuggle_false_first_hit() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(Passenger.smuggle, (a, b, c));

        bytes32 functionSelector = bytes32(Passenger.smuggle.selector);

        vm.expectEmit();
        emit Smuggled(a, b, c);

        // THis should only hit the proper onces, since all "lengths" exceed the call.
        RandomCallback(address(passenger))
            .randomCallbackLarge(functionSelector, functionSelector, 500, functionSelector, encodedCall);
    }
}
