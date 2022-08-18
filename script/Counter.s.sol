// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Counter} from "src/Counter.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        // vm.startBroadcast();
        Counter c = new Counter();
        c.setNumber(1);
        // vm.stopBroadcast();
    }
}
