// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AMM {
    using SafeMath for uint256;

    uint256 public totalShares;
    uint256 public totalToken1;
    uint256 public totalToken2;
    uint256 public K;

    uint256 constant PRECISION = 1_000_000;

    error InsufficientBalance();

    mapping(address => uint256) public shares;

    mapping(address => uint256) public token1Balance;
    mapping(address => uint256) public token2Balance;

    modifier validAmountCheck(
        mapping(address => uint256) storage _balance,
        uint256 _qty
    ) {
        require(_qty > 0, "Amount cannot be zero!");
        // require(_qty <= _balance[msg.sender], "Insufficient amount");
        if (_qty > _balance[msg.sender]) {
            revert InsufficientBalance();
        }
        _;
    }

    modifier activePool() {
        require(totalShares > 0, "Zero Liquidity");
        _;
    }

    function faucet(uint256 _amountToken1, uint256 _amountToken2) external {
        token1Balance[msg.sender] = token1Balance[msg.sender].add(
            _amountToken1
        );
        token2Balance[msg.sender] = token2Balance[msg.sender].add(
            _amountToken2
        );
    }

    function getMyHoldings()
        external
        view
        returns (
            uint256 amountToken1,
            uint256 amountToken2,
            uint256 myShare
        )
    {
        amountToken1 = token1Balance[msg.sender];
        amountToken2 = token2Balance[msg.sender];
        myShare = shares[msg.sender];
    }

    function getPoolDetails()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (totalToken1, totalToken2, totalShares);
    }

    function getEquivalentToken1Estimate(uint256 _amountToken2)
        public
        view
        activePool
        returns (uint256 reqToken1)
    {
        reqToken1 = totalToken1.mul(_amountToken2).div(totalToken2);
    }

    function getEquivalentToken2Estimate(uint256 _amountToken1)
        public
        view
        activePool
        returns (uint256 reqToken2)
    {
        reqToken2 = totalToken2.mul(_amountToken1).div(totalToken1);
    }

    function provide(uint256 _amountToken1, uint256 _amountToken2)
        external
        validAmountCheck(token1Balance, _amountToken1)
        validAmountCheck(token2Balance, _amountToken2)
        returns (uint256 share)
    {
        if (totalShares == 0) {
            // Genesis liquidity is issued 100 Shares
            share = 100 * PRECISION;
        } else {
            uint256 share1 = totalShares.mul(_amountToken1).div(totalToken1);
            uint256 share2 = totalShares.mul(_amountToken2).div(totalToken2);
            require(
                share1 == share2,
                "Equivalent value of tokens not provided..."
            );
            share = share1;
        }

        require(share > 0, "Asset value less than threshold for contribution!");
        token1Balance[msg.sender] -= _amountToken1;
        token2Balance[msg.sender] -= _amountToken2;

        totalToken1 += _amountToken1;
        totalToken2 += _amountToken2;
        K = totalToken1.mul(totalToken2);

        totalShares += share;
        shares[msg.sender] += share;
    }

    function getWithdrawEstimate(uint256 _share)
        public
        view
        activePool
        returns (uint256 amountToken1, uint256 amountToken2)
    {
        require(_share <= totalShares, "Share should be less than totalShare");
        amountToken1 = _share.mul(totalToken1).div(totalShares);
        amountToken2 = _share.mul(totalToken2).div(totalShares);
    }

    function withdraw(uint256 _share)
        external
        activePool
        validAmountCheck(shares, _share)
        returns (uint256 amountToken1, uint256 amountToken2)
    {
        (amountToken1, amountToken2) = getWithdrawEstimate(_share);

        shares[msg.sender] -= _share;
        totalShares -= _share;

        totalToken1 -= amountToken1;
        totalToken2 -= amountToken2;
        K = totalToken1.mul(totalToken2);

        token1Balance[msg.sender] += amountToken1;
        token2Balance[msg.sender] += amountToken2;
    }

    function getSwapToken1Estimate(uint256 _amountToken1)
        public
        view
        activePool
        returns (uint256 amountToken2)
    {
        uint256 token1After = totalToken1.add(_amountToken1);
        uint256 token2After = K.div(token1After);
        amountToken2 = totalToken2.sub(token2After);

        if (amountToken2 == totalToken2) amountToken2--;
    }

    function getSwapToken1EstimateGivenToken2(uint256 _amountToken2)
        public
        view
        activePool
        returns (uint256 amountToken1)
    {
        require(_amountToken2 < totalToken2, "Insufficient pool balance");
        uint256 token2After = totalToken2.sub(_amountToken2);
        uint256 token1After = K.div(token2After);
        amountToken1 = token1After.sub(totalToken1);
    }

    function swapToken1(uint256 _amountToken1)
        external
        activePool
        validAmountCheck(token1Balance, _amountToken1)
        returns (uint256 amountToken2)
    {
        amountToken2 = getSwapToken1Estimate(_amountToken1);

        token1Balance[msg.sender] -= _amountToken1;
        totalToken1 += _amountToken1;
        totalToken2 -= amountToken2;
        token2Balance[msg.sender] += amountToken2;
    }

    function getSwapToken2Estimate(uint256 _amountToken2)
        public
        view
        activePool
        returns (uint256 amountToken1)
    {
        uint256 token2After = totalToken2.add(_amountToken2);
        uint256 token1After = K.div(token2After);
        amountToken1 = totalToken1.sub(token1After);

        if (amountToken1 == totalToken1) amountToken1--;
    }

    function getSwapToken2EstimateGivenToken1(uint256 _amountToken1)
        public
        view
        activePool
        returns (uint256 amountToken2)
    {
        require(_amountToken1 < totalToken1, "Insufficient pool balance");
        uint256 token1After = totalToken1.sub(_amountToken1);
        uint256 token2After = K.div(token1After);
        amountToken2 = token2After.sub(totalToken2);
    }

    function swapToken2(uint256 _amountToken2)
        external
        activePool
        validAmountCheck(token2Balance, _amountToken2)
        returns (uint256 amountToken1)
    {
        amountToken1 = getSwapToken2Estimate(_amountToken2);

        token2Balance[msg.sender] -= _amountToken2;
        totalToken2 += _amountToken2;
        totalToken1 -= amountToken1;
        token1Balance[msg.sender] += amountToken1;
    }
}
