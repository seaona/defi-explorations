// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {UniswapV2Arb2} from "./UniswapV2Arb2.sol";

// test flash swap arbitrage between Uniswap and Sushiswap
// buy WETH on Uniswap (flash borrow), sell on Sushiswap
contract UniswapV2Arb2Test is Test {
    address constant UNISWAP_V2_ROUTER_02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant SUSHISWAP_V2_ROUTER_02 = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IUniswapV2Router02 private constant uni_router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IERC20 private constant dai = IERC20(DAI);
    IWETH private constant weth = IWETH(WETH);
    address constant user = address(11);

    UniswapV2Arb2 private arb;
    address private uniPair;
    address private sushiPair;

    function setUp() public {
        arb = new UniswapV2Arb2();

        // Get pair addresses from router factories
        address uniFactory = IUniswapV2Router02(UNISWAP_V2_ROUTER_02).factory();
        address sushiFactory = IUniswapV2Router02(SUSHISWAP_V2_ROUTER_02).factory();
        uniPair = IUniswapV2Factory(uniFactory).getPair(DAI, WETH);
        sushiPair = IUniswapV2Factory(sushiFactory).getPair(DAI, WETH);

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
    }

    function test_flashSwap() public {
        uint256 bal0 = dai.balanceOf(user);

        vm.prank(user);
        arb.flashSwap(
            uniPair,
            sushiPair,
            true,           // isZeroForOne: DAI (token0) in, WETH (token1) out
            10000 * 1e18,   // amountIn
            1               // minProfit
        );

        uint256 bal1 = dai.balanceOf(user);

        assertGe(bal1, bal0, "no profit");
        assertEq(dai.balanceOf(address(arb)), 0, "DAI balance of arb != 0");
        console2.log("profit", bal1 - bal0);
    }
}
