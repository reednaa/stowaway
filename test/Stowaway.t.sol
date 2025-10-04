// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {EmitEvent} from "../src/mock/EmitEvent.sol";

interface RandomCallback {
    function randomCallback(uint256 a, uint256 b, bytes calldata c) external;

    struct CallbackStruct {
        uint256 a;
        bytes call;
        uint256[] amounts;
    }

    function randomCallback(CallbackStruct calldata s) external;
}

contract StowawayTest is Test {
    event GotData(uint256 a, bytes b, bytes32 c);

    EmitEvent emev;

    function setUp() public {
        emev = new EmitEvent();
    }

    function test_gotData() public {
        uint256 a = uint256(keccak256(bytes("uint256")));
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        vm.expectEmit();
        emit GotData(a, b, c);

        emev.gotData(a, b, c);
    }

    function test_gotData_as_callback(uint256 noiseA, uint256 noiseB) public {
        // uint256 a = uint256(keccak256(bytes("uint256")));
        uint256 a = 0;
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(EmitEvent.gotData, (a, b, c));
        console.logBytes(encodedCall);

        vm.expectEmit();
        emit GotData(a, b, c);

        RandomCallback(address(emev)).randomCallback(noiseA, noiseB, encodedCall);
    }

    function test_gotData_as_struct_callback() public {
        // uint256 a = uint256(keccak256(bytes("uint256")));
        uint256 a = 0;
        bytes memory b = bytes("bytes");
        bytes32 c = keccak256(bytes("bytes32"));

        bytes memory encodedCall = abi.encodeCall(EmitEvent.gotData, (a, b, c));
        console.logBytes(encodedCall);

        uint256[] memory amounts = new uint256[](5);

        RandomCallback.CallbackStruct memory cbs =
            RandomCallback.CallbackStruct({a: 0, call: encodedCall, amounts: amounts});

        vm.expectEmit();
        emit GotData(a, b, c);

        RandomCallback(address(emev)).randomCallback(cbs);
    }
}
