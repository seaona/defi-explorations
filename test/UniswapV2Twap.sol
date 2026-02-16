// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
import {FixedPoint} from "../src/libraries/FixedPoint.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";

contract UniswapV2Twap {
    using FixedPoint for *;

    // Minimum wait time in seconds before the function update can be called again
    // TWAP of time > MIN_WAIT
    uint256 private constant MIN_WAIT = 300;

    IUniswapV2Pair private immutable pair;
    address private immutable token0;
    address private immutable token1;

    // Cumulative prices are uq112x112 price * seconds
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    // Last timestamp the cumulative prices were updated
    uint32 public updatedAt;

    // TWAP of token0 and token1
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112

    // TWAP of token0 in terms of token1
    FixedPoint.uq112x112 public price0Avg;
    // TWAP of token1 in terms of token0
    FixedPoint.uq112x112 public price1Avg;

    // Exercise 1
    constructor(address _pair) {
        // set pair contract from constructor input
        pair = IUniswapV2Pair(_pair);

        // set token0 and token1 from pair contract
        token0 = pair.token0();
        token1 = pair.token1();

        // store price0CumulativeLast and price1CumulativeLast from pair contract
        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast();

        // call pair.getReserve to get last timestamp the reserves were updated
        // and store it into the state variable updatedAt
        (, , updatedAt) = pair.getReserves();
    }

    function flashSwap(address token, uint256 amount) external {
        require(token == token0 || token == token1, "Invalid token");

        // 1. Determine amount0Out and amount1Out
        (uint256 amount0Out, uint256 amount1Out) =
            token == token0 ? (amount, uint256(0)) : (uint256(0), amount);

        // 2. Encode token and msg.sender as bytes
        bytes memory data = abi.encode(token, msg.sender);
        
        // 3. Call pair.swap
        pair.swap(amount0Out, amount1Out, address(this), data);

    }

    // Exercise 2: calculate the cumulative prices up to current timestamp
    function _getCurrentCumulativePrices() internal view returns (uint256 price0Cumulative, uint256 price1Cumulative) {
        // 1. Get latest cumulative prices from the pair contract
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();

        // if current block timestamp > last timestamp reserves were updated,
        // calculate cumulative prices until current time.
        // otherwise return latest cumulative prices retrieved from the pair contract

        // 2. Get reserves and last timestamp the reserves were updated from the pair contract
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();

        // 3. Cast block.timestamp to uint32
        uint32 blockTimestamp = uint32(block.timestamp);
        if (blockTimestampLast != blockTimestamp) {
            // 4. Calculate elapsed time
            uint32 dt = blockTimestamp - blockTimestampLast;

            // Addition overflow is desired
            unchecked {
                // 5. Add spot price * elapsed time to cumulative prices
                //      Use FixedPoint.fraction to calculate the spot price
                //      FixedPoint.fraction returns UQ112x112, so cast it into uint256
                //      Multiply spot price by time elapsed
                price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * dt;
                price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * dt;
            }
        }

        // Exercise 3
        // Updates cumulative prices
        function update() external {
            // 1. Cast block.timestamp to uint32
            uint32 blockTimestamp = uint32(block.timestamp);
            // 2. Calculate elapsed time since last time cumulative prices were updated in this contract
            uint32 dt = blockTimestamp - updatedAt;

            // 3. Require time elapsed > MIN_WAIT
            require(dt > MIN_WAIT, "min wait");

            // 4. Call the internal function _getCurrentCumulativePrices to get current cumulative prices
            (uint256 price0Cumulative, uint256 price1Cumulative) = _getCurrentCumulativePrices();

            // Overflow is desired, casting never truncates
            // Substracting between two cumulative prices values will result in a number that fits within
            // the range of uint256 as long as the observations are made for periods of max 2^32 seconds, or ~ 136 years
            unchecked {
                // 5. Calculate TWAP price0Avg and price1Avg
                //      TWAP = (current cumulative price - last cumulative price) / dt
                //      Cast TWAP into uint224 and then into FixedPoint.uq112x112
                price0Avg = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / dt));
                price1Avg = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / dt));
            }

            // 6. Update state variables price0Cumulative, price1Cumulative and updatedAt
            price0CumulativeLast = price0Cumulative;
            price1CumulativeLast = price1Cumulative;
            updatedAt = blockTimestamp;

        }

        // Exercise 4
        // Returns the amount out corresponding to the amount in for a given token
        function consult(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut) {
            // 1. Require tokenIn is either token0 or token1
            require(tokenIn == token0 || tokenIn == token1, "invalid token");

            // 2. Calculate amountOut
            //      amountOut = TWAP of tokenIn * amountIn
            //      use FixedPoint.mul to multiply TWAP of tokenIn with amountIn
            //      FixedPoint.mul returns uq144x112, use FixedPoint.decode144 to return uint144
            if (tokenIn == token0) {
                // Example
                //   token0 = WETH
                //   token1 = USDC
                //   price0Avg = avg price of WETH in terms of USDC = 2000 USDC / 1 WETH
                //   tokenIn = WETH
                //   amountInt = 2
                //   amountOut = price0Avg * amountIn = 4000 USDC
            } else {
                amountOut = FixedPoint.mul(price1Avg, amountIn).decode144();
            }
        }
    }
}
*/