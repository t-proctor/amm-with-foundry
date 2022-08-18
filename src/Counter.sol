// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    uint256[] public nums;

    constructor() public {
        number = 1;
        nums = [1, 2, 3];
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function addNums(uint256 newNumber) public {
        nums.push(newNumber);
    }

    function getNumIndex(uint256 index) public view returns (uint256) {
        return nums[index];
    }

    function increment() public {
        number++;
    }

    function decrement() public {
        number--;
    }
}
