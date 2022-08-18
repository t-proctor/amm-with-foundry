// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    // uint256[] public nums;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(1);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 2);
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function testDecrement() public {
        counter.decrement();
        assertEq(counter.number(), 0);
    }

    function testNums() public {
        counter.addNums(1);
        counter.addNums(2);
        assertEq(counter.getNumIndex(0), 1);
        assertEq(counter.getNumIndex(1), 2);
        emit log_named_uint("Hello", counter.getNumIndex(1));
    }
}
