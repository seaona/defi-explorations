// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {ERC20} from "../src/ERC20.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";

contract UniswapV2FactoryTest is Test {
    // Mainnet addresses
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    IWETH private constant weth = IWETH(WETH);

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    function test_createPair() public {
        ERC20 token = new ERC20("test", "TEST", 18);

        // Deploy token + WETH pair contract
        address pair = factory.createPair(address(token), WETH);
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        if (address(token) < WETH) {
            assertEq(token0, address(token), "token 0");
            assertEq(token1, WETH, "token 1");
        } else {
            assertEq(token0, WETH, "token 0");
            assertEq(token1, address(token), "token 1");
        }
    }

}
