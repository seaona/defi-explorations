// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}