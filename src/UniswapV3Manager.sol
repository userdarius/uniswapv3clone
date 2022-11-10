//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../src/UniswapV3PoolSwap1.sol";
import "../src/interfaces/IERC20.sol";

contract UniswapV3Manager {
    function mint(
        address poolAddress,
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity,
        bytes calldata data
    ) public {
        UniswapV3PoolSwap1(poolAddress).mint(msg.sender, lowerTick, upperTick, liquidity, data);
    }

    function swap(address poolAddress, bytes calldata data) public {
        UniswapV3PoolSwap1(poolAddress).swap(msg.sender, data);
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        UniswapV3PoolSwap1.CallbackData memory extra = abi.decode(data, (UniswapV3PoolSwap1.CallbackData));

        IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
    }

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) public {
        UniswapV3PoolSwap1.CallbackData memory extra = abi.decode(data, (UniswapV3PoolSwap1.CallbackData));

        if (amount0 > 0) {
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, uint256(amount0));
        }

        if (amount1 > 0) {
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, uint256(amount1));
        }
    }
}
