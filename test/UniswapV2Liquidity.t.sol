// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {ERC20} from "../src/ERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";

contract UniswapV2LiquidityTest is Test {
       // Mainnet addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant UNISWAP_V2_ROUTER_02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant UNISWAP_V2_PAIR_DAI_WETH = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;

    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);

    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Pair private constant pair = IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);

    address private constant user = address(100);

    function setUp() public {
        // Fund WETH to user
        deal(user, 100*1e18);
        vm.startPrank(user);
        weth.deposit{value: 100 * 1e18}();
        weth.approve(address(router), type(uint256).max);
        vm.stopPrank();

        // Fund DAI to user
        deal(DAI, user, 1000000*1e18);
        vm.startPrank(user);
        dai.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function test_addLiquidity() public {
        vm.prank(user);
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            DAI,
            WETH,
            1e6 * 1e18,
            100 * 1e18,
            1,
            1,
            user,
            block.timestamp
        );
        assertGt(pair.balanceOf(user), 0, "LP = 0");
        console2.log("DAI", amountA);
        console2.log("WETH", amountB);
        console2.log("LP", liquidity);
    }

    function test_removeLiquidity() public {
        vm.startPrank(user);
        // add liquidity
        (, , uint liquidity) = router.addLiquidity(
            DAI, // tokenA
            WETH, // tokenB
            1e6 * 1e18, // amountADesired
            100 * 1e18, // amountBDesired
            1, // amountAMin
            1, // amountBMin
            user,
            block.timestamp
        );

        console2.log("Liquidity Before", pair.balanceOf(user));

        pair.approve(address(router), liquidity);

        router.removeLiquidity(
            DAI, // tokenA
            WETH, // tokenB
            pair.balanceOf(user), // liquidity
            1, // amountAMin
            1, // amountBMin
            user,
            block.timestamp
        );

        vm.stopPrank();
        assertEq(pair.balanceOf(user), 0, "LP = 0");
        console2.log("Liquidity After Burn", pair.balanceOf(user));
    }
}
