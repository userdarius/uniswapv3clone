//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract UniswapV3PoolSwap2 {
    using TickBitmap for mapping(int16 => uint256);
    mapping(int16 => uint256) public tickBitmap;

    function mint(
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity,
        bytes calldata data
    ) public {
        // ...
    }

    function swap(address recipient, bytes calldata data) public {
        // ...
    }
}
