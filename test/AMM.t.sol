// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AMM.sol";

// import "./utils/Cheats.sol";

contract AMMTest is Test {
    AMM public amm;
    address public owner;
    mapping(address => uint256) public token1Balances;
    using stdStorage for StdStorage;

    function setUp() public {
        amm = new AMM();
        amm.faucet(100, 100);
        amm.provide(50, 50);
    }

    function testFaucet() public {
        assertEq(amm.token1Balance(address(this)), 50);
    }

    function testProvide() public {
        assertEq(amm.shares(address(this)), 100000000);
    }

    function testSwapToken1() public {
        amm.swapToken1(10);
        assertEq(amm.token1Balance(address(this)), 40);
        assertEq(amm.token2Balance(address(this)), 59);
    }

    function testSwapToken2() public {
        amm.swapToken2(10);
        assertEq(amm.token1Balance(address(this)), 59);
        assertEq(amm.token2Balance(address(this)), 40);
    }

    function testGetMyHoldings() public {
        (uint256 totalToken1, uint256 totalToken2, uint256 totalShares) = amm
            .getMyHoldings();
        assertEq(totalToken1, 50);
        assertEq(totalToken2, 50);
        assertEq(totalShares, 100000000);
    }

    //test with prank
    function testDifferentOwner() public {
        vm.startPrank(address(0xd3ad));
        vm.expectRevert(AMM.InsufficientBalance.selector);
        amm.swapToken1(50);
        vm.stopPrank();
    }

    function testZeroShares() public {
        uint256 slot = stdstore
            .target(address(amm))
            .sig("totalShares()")
            .find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedTotalShares = bytes32(abi.encode(0));
        vm.store(address(amm), loc, mockedTotalShares);
        vm.expectRevert("Zero Liquidity");
        amm.getEquivalentToken1Estimate(50);
    }

    function testWithdraw() public {
        amm.withdraw(50);
        assertEq(amm.token1Balance(address(this)), 50);
        assertEq(amm.token2Balance(address(this)), 50);
        assertEq(amm.shares(address(this)), 99999950);
    }

    function testSwapToken1Estimate() public {
        uint256 amountToken1 = amm.getEquivalentToken1Estimate(50);
        assertEq(amountToken1, 50);
    }

    function testSwapToken2Estimate() public {
        uint256 amountToken2 = amm.getEquivalentToken2Estimate(50);
        assertEq(amountToken2, 50);
    }

    function testgetSwapToken2EstimateGivenToken1() public {
        uint256 amountToken1 = amm.getSwapToken1EstimateGivenToken2(10);
        assertEq(amountToken1, 12);
    }

    function testgetSwapToken1EstimateGivenToken2() public {
        uint256 amountToken2 = amm.getSwapToken2EstimateGivenToken1(10);
        assertEq(amountToken2, 12);
    }
}
