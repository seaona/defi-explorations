// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import { UniswapV2FlashSwap } from "../test/UniswapV2FlashSwap.sol";

contract UniswapV2FlashSwapTest is Test {
     // Mainnet addresses
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant UNISWAP_V2_ROUTER_02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant UNISWAP_V2_PAIR_DAI_WETH = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;

    IERC20 private constant dai = IERC20(DAI);
    IUniswapV2Pair private constant pair = IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);
    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    UniswapV2FlashSwap private flashSwap;

    address private constant user = address(100);

    function setUp() public {
        flashSwap = new UniswapV2FlashSwap(UNISWAP_V2_PAIR_DAI_WETH);

        deal(DAI, user, 10000 * 1e18);
        vm.startPrank(user);
        dai.approve(address(flashSwap), type(uint256).max);
        vm.stopPrank();
    }

    function test_flashSwap() public {
        uint256 dai0 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);
        vm.prank(user);
        flashSwap.flashSwap(DAI, 1e6 * 1e18);
        uint256 dai1 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);
        
        console2.log("DAI fee", dai1 - dai0);
        assertGe(dai1, dai0, "DAI balance of pair");
    }

}
