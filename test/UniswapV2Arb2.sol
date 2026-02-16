// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";

contract UniswapV2Arb2 {
    struct FlashSwapData {
        // caller of flashswap (msg.sender inside flashSwap)
        address caller;
        // pair to flash swap from
        address pair0;
        // pair to flash swap to
        address pair1;
        // true if flash swap is token0 in and token1 out
        bool isZeroForOne;
        // amount in to repay flash swap
        uint256 amountIn;
        // amount to borrow from flash swap
        uint256 amountOut;
        // revert if profit is less than this minimum
        uint256 minProfit;
    }

    // Exercise 1
    /**
     * @param pair0 pair contract to flash swap
     * @param pair1 pair contract to swap
     * @param isZeroForOne true if flash swap is token0 in and token1 out
     * @param amountIn amount in to repay flash swap
     * @param minProfit revert if profit is less than this minimum
     */
    // flash swap to borrow tokenOut
     function flashSwap(
        address pair0,
        address pair1,
        bool isZeroForOne,
        uint256 amountIn,
        uint256 minProfit
     ) external {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair0).getReserves();
        uint256 amountOut = isZeroForOne
            ? getAmountOut(amountIn, reserve0, reserve1)
            : getAmountOut(amountIn, reserve1, reserve0);

        bytes memory data = abi.encode(FlashSwapData({
            caller: msg.sender,
            pair0: pair0,
            pair1: pair1,
            isZeroForOne: isZeroForOne,
            amountIn: amountIn,
            amountOut: amountOut,
            minProfit: minProfit
        }));
        // use getAmountOut to calculate amountOut to borrow
        IUniswapV2Pair(pair0).swap({
            amount0Out: isZeroForOne ? 0 : amountOut,
            amount1Out: isZeroForOne ? amountOut : 0,
            to: address(this),
            data: data
        });
    }

     // Uniswap V2 callback
     function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
     ) external {
        FlashSwapData memory params = abi.decode(data, (FlashSwapData));

        address token0 = IUniswapV2Pair(params.pair0).token0();
        address token1 = IUniswapV2Pair(params.pair0).token1();
        (address tokenIn, address tokenOut) = params.isZeroForOne ? (token0, token1) : (token1, token0);

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(params.pair1).getReserves();
        uint256 amountOut = params.isZeroForOne
            ? getAmountOut(params.amountOut, reserve1, reserve0)
            : getAmountOut(params.amountOut, reserve0, reserve1);


        IERC20(tokenOut).transfer(params.pair1, params.amountOut);

        IUniswapV2Pair(params.pair1).swap({
            amount0Out: params.isZeroForOne ? amountOut : 0,
            amount1Out: params.isZeroForOne ? 0 : amountOut,
            to: address(this),
            data: ""
        });

        IERC20(tokenIn).transfer(params.pair0, params.amountIn);

        uint256 profit = amountOut - params.amountIn;
        require(profit >= params.minProfit, "profit < min");
        IERC20(tokenIn).transfer(params.caller, profit);
     }

     function getAmountOut(
        uint256 amountIn,
        uint256 reservesIn,
        uint256 reservesOut
     ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reservesOut;
        uint256 denominator = reservesIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
     }
}