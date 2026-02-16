// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";

contract UniswapV2Arb1 {
    struct SwapParams {
        // router to execute first swap - tokenIn for tokenOut
        address router0;
        // router to execute second swap - tokenOut for tokenIn
        address router1;
        // token in of first swap
        address tokenIn;
        // token out of first swap
        address tokenOut;
        // amount in of first swap
        uint256 amountIn;
        // revert the arbitrage if profit is less than this minimum
        uint256 minProfit;
    }

    function _swap(SwapParams memory params) private returns (uint256 amountOut) {
        // swap on router0 (tokenIn -> tokenOut)
        IERC20(params.tokenIn).approve(params.router0, params.amountIn);

        address[] memory path = new address[](2);
        path[0] = params.tokenIn;
        path[1] = params.tokenOut;

        uint256[] memory amounts = IUniswapV2Router02(params.router0).swapExactTokensForTokens({
            amountIn: params.amountIn,
            amountOutMin: 0,
            path: path,
            to: address(this),
            deadline: block.timestamp
        });

        // swap on router1 (tokenOut -> tokenIn)
        IERC20(params.tokenOut).approve(params.router1, amounts[1]);

        path[0] = params.tokenOut;
        path[1] = params.tokenIn;

        amounts = IUniswapV2Router02(params.router1).swapExactTokensForTokens({
            amountIn: amounts[1],
            amountOutMin: 0,
            path: path,
            to: address(this),
            deadline: block.timestamp
        });

        amountOut = amounts[1];
    }

    // Exercise 1
    // execute an arbitrage between router0 and router1
    // pull tokenIn from msg.sender
    // send amountIn + profit back to msg.sender
    function swap(SwapParams calldata params) external {
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        // execute swap on router0
        uint amountOut = _swap(params);
        require(amountOut - params.amountIn >= params.minProfit, "profit < min");
        IERC20(params.tokenIn).transfer(msg.sender, amountOut);
    }

    // Exercise 2
    // execute an arbitrage between router0 and router1 with a flash swap
    // borrow tokenIn with flash swap from pair
    // send profit back to msg.sender
     function flashSwap(address router, bool isToken0, SwapParams calldata params) external {
        address factory = IUniswapV2Router02(router).factory();
        address pair = IUniswapV2Factory(factory).getPair(params.tokenIn, params.tokenOut);

        // Calculate how much tokenOut we get for amountIn on this pair
        address[] memory path = new address[](2);
        path[0] = params.tokenIn;
        path[1] = params.tokenOut;
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(params.amountIn, path);

        // Flash borrow tokenOut (not tokenIn) — the flash borrow IS the first swap leg
        bytes memory data = abi.encode(msg.sender, pair, params);
        IUniswapV2Pair(pair).swap({
            amount0Out: isToken0 ? 0 : amounts[1],
            amount1Out: isToken0 ? amounts[1] : 0,
            to: address(this),
            data: data
        });
     }

     // Uniswap V2 callback
     function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
     ) external {
        (address caller, address pair, SwapParams memory params) = abi.decode(data, (address, address, SwapParams));

        // We received tokenOut from the flash swap
        uint256 borrowedAmount = amount0 > 0 ? amount0 : amount1;

        // Only execute the second leg: tokenOut -> tokenIn on router1
        IERC20(params.tokenOut).approve(params.router1, borrowedAmount);
        address[] memory path = new address[](2);
        path[0] = params.tokenOut;
        path[1] = params.tokenIn;
        uint256[] memory amounts = IUniswapV2Router02(params.router1).swapExactTokensForTokens({
            amountIn: borrowedAmount,
            amountOutMin: 0,
            path: path,
            to: address(this),
            deadline: block.timestamp
        });

        uint256 daiReceived = amounts[1];

        // Repay the flash swap pair with tokenIn (amountIn satisfies K invariant)
        IERC20(params.tokenIn).transfer(pair, params.amountIn);

        // Send profit to caller
        uint256 profit = daiReceived - params.amountIn;
        require(profit >= params.minProfit, "profit < minProfit");
        IERC20(params.tokenIn).transfer(caller, profit);
     }
}