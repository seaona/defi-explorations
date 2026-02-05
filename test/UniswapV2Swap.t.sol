// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";

contract UniswapV2SwapTest is Test {
    // Mainnet addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant UNISWAP_V2_ROUTER_02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);

    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);

    address private constant user = address(100);

    function setUp() public {
        deal(user, 100 *1e18);
        vm.startPrank(user);
        weth.deposit{value: 1e18}();
        weth.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    // swap all input tokens for as many output tokens as possible
    function test_swapExactTokensForTokens() public {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1e18;
        uint256 amountOutMin = 1;

        vm.prank(user);
        uint256[] memory amounts = router.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            path: path,
            to: user,
            deadline: block.timestamp
        });

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);

        assertGe(mkr.balanceOf(user), amountOutMin, "MKR balance of user");
    }

    // receive an exact amount of output tokens for as few input tokens as possible
    function test_swapTokensForExactTokens() public {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;
        
        uint256 amountOut = 0.01 * 1e18; // Must be less than pool reserves (~0.047 MKR)
        uint256 amountInMax = 1e18;

        vm.prank(user);
        uint256[] memory amounts = router.swapTokensForExactTokens({
            amountOut: amountOut,
            amountInMax: amountInMax,
            path: path,
            to: user,
            deadline: block.timestamp
        });

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);

        assertGe(mkr.balanceOf(user), amountOut, "MKR balance of user");
    }

}
