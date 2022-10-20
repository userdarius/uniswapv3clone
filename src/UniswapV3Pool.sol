pragma solidity ^0.8.14;

library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }
}

library Position {
    struct Info {
        uint128 liquidity;
    }
}

error InvalidTickRange();
error ZeroLiquidity();

contract UniswapV3Pool {
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    address public immutable token0;
    address public immutable token1;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
    }
    Slot0 public slot0;

    uint128 public liquidity;

    mapping(int24 => Tick.Info) public ticks;
    mapping(bytes32 => Position.Info) public positions;

    constructor(
        address token0_,
        address token1_,
        uint160 sqrtPriceX96,
        int24 tick
    ) {
        token0 = token0_;
        token1 = token1_;

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick})
    }

    // function to provide liquidity to a pool
    function mint{
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amount
    } external returns(uint256 amount0, uint256 amount1) {
        if (
            lowerTick >= upperTick ||
            lowerTick < MIN_TICK || 
            upperTick > MAX_TICK
        ) revert InvalidTickRange();

        if(amount == 0) revert ZeroLiquidity();

        ticks.update(lowerTick, amount);
        ticks.update(upperTick, amount);

        Position.Info storage position = positions.get(
            owner,
            lowerTick,
            upperTick
        );
        position.update(amount);
    }

    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint128 liquidityDelta
    ) internal {
        Tick.Info storage tickInfo = self[tick];
        uint128 liquidityBefore = tickInfo.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;

        if( liquidityBefore == 0){
            tickInfo.initialized = true;
        }
        
        tickInfo.liquidity = liquidityAfter;
    }
}
