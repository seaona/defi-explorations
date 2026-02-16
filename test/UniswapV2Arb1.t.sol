// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {UniswapV2Arb1} from "./UniswapV2Arb1.sol";

// test arbitrage between Uniswap and Sushiswap
// buy WETH on Uniswap, sell on Sushiswap
// for flashSwap, borrow DAI from DAI/MKR pair
contract UniswapV2Arb1Test is Test {
    address constant UNISWAP_V2_ROUTER_02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant SUSHISWAP_V2_ROUTER_02 = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IUniswapV2Router02 private constant uni_router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Router02 private constant sushi_router = IUniswapV2Router02(SUSHISWAP_V2_ROUTER_02);
    IERC20 private constant dai = IERC20(DAI);
    IWETH private constant weth = IWETH(WETH);
    address constant user = address(11);

    UniswapV2Arb1 private arb;

    function setUp() public {
        arb = new UniswapV2Arb1();

        // setup - WETH cheaper on Uniswap than Sushiswap
        deal(address(this), 100 * 1e18);

        weth.deposit{value: 100 * 1e18}();
        weth.approve(address(uni_router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        uni_router.swapExactTokensForTokens({
            amountIn: 100 * 1e18,
            amountOutMin: 1,
            path: path,
            to: user,
            deadline: block.timestamp
        });

        // setup - user has DAI, approves arb to spend DAI
        deal(DAI, user, 10000 * 1e18);
        vm.prank(user);
        dai.approve(address(arb), type(uint256).max);
    }

    function test_swap() public {
        uint256 bal0 = dai.balanceOf(user);
        vm.prank(user);
        arb.swap(
            UniswapV2Arb1.SwapParams({
                router0: UNISWAP_V2_ROUTER_02,
                router1: SUSHISWAP_V2_ROUTER_02,
                tokenIn: DAI,
                tokenOut: WETH,
                amountIn: 10000 * 1e18,
                minProfit: 1
            })
        );
        uint256 bal1 = dai.balanceOf(user);

        assertGe(bal1, bal0, "non profit");
        assertEq(dai.balanceOf(address(arb)), 0, "DAI balance of arb !=0" );
        console2.log("profit", bal1 - bal0);
    }

    function test_flashSwap() public {
        uint256 bal0 = dai.balanceOf(user);
        vm.prank(user);
        arb.flashSwap(
            UNISWAP_V2_ROUTER_02,
            true,
            UniswapV2Arb1.SwapParams({
                router0: UNISWAP_V2_ROUTER_02,
                router1: SUSHISWAP_V2_ROUTER_02,
                tokenIn: DAI,
                tokenOut: WETH,
                amountIn: 10000 * 1e18,
                minProfit: 1
            })
        );

        uint256 bal1 = dai.balanceOf(user);

        assertGe(bal1, bal0, "non profit");
        assertEq(dai.balanceOf(address(arb)), 0, "DAI balance of arb !=0" );
        console2.log("profit", bal1 - bal0);
    }

}