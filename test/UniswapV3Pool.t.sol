// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "../src/UniswapV3Pool.sol";

contract UniswapV3PoolTest is Test {
    ERC20Mintable public token0;
    ERC20Mintable public token1;
    UniswapV3Pool public pool;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }

    /**
    /* Here we test for the successful minting of the pool tokens
     */
    function testMintSuccess() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
    }

    function setupTestCase(TestCaseParams memory _params)
        internal
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        token0.mint(address(this), _params.wethBalance);
        token1.mint(address(this), _params.usdcBalance);

        pool = new UniswapV3Pool(address(token0), address(token1), _params.currentSqrtP, _params.currentTick);

        if (_params.mintLiquidity) {
            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                _params.lowerTick,
                _params.upperTick,
                _params.liquidity
            );
        }

        shouldTransferInCallback = _params.shouldTransferInCallback;

        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(_params);

        uint256 expectedAmount0 = 0.998976618347425280 ether;
        uint256 expectedAmount1 = 5000 ether;

        assertEq(poolBalance0, expextedAmount0, "incorrect token0 deposited amount");
        assertEq(poolBalance1, expectedAmount1, "incorrect token1 deposited amount");

        assertEq(token0.balanceOf(address(pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(pool)), expectedAmount1);

        bytes32 positionKey = keccak256(abi.encodePacked(address(this), _params.lowerTick, _params.upperTick));

        uint128 posLiquidity = pool.positions(positionKey);
        assertEq(posLiquidity, _params.liquidity);

        (bool tickInitialized, uint128 tickLiquidity) = pool.ticks(_params.lowerTick);

        assertTrue(tickInitialized);
        assertEq(tickLiquidity, _params.liquidity);

        (tickInitialized, tickLiquidity) = pool.ticks(_params.upperTick);
        assertTrue(tickInitialized);
        assertEq(tickLiquidity, _params.liquidity);

        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, 5602277097478614198912276234240, "invalid current sqrtP");

        assertEq(tick, 85176, "invalid current tick");
        assertEq(pool.liquidity(), 1517882343751509868544, "invalid current liquidity");
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1) public {
        if (shouldTransferInCallback) {
            token0.transfer(msg.sender, amount0);
            token1.transfer(msg.sender, amount1);
        }
    }

    function testSwapBuyEth() public {
        TestCaseParams memory _params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(_params);

        token1.mint(address(this), 42 ether);
    }

    function uniswapv3SwapCallback(int256 amount0, int256 amount1) public {
        if (amount0 > 0) {
            token0.transfer(msg.sender, uint256(amount0));
        }
        if (amount1 > 0) {
            token1.transfer(msg.sender, uint256(amount1));
        }

        (int256 amount0Delta, int256 amount1Delta) = pool.swap(address(this));

        // the function .swap returns token amounts used in the swap.
        // We can check them right away
        assertEq(amount0Delta, -0.008396714242162444 ether, "invalid ETH out");
        assertEq(amount1Delta, 42 ether, "invalid USDC in");

        // We need to check the tokens were actually transferred from the caller
        assertEq(
            token0.balanceOf(address(this)),
            uint256(userBalance0Before - amount0Delta),
            "invalid user ETH balance"
        );
        assertEq(token1.balanceOf(address(this)), 0, "invalid user USDC balance");

        // Here we check that the tokens were correctly sent to the pool contract
        assertEq(
            token0.balanceOf(address(pool)),
            uint256(int256(poolBalance0) + amount0Delta),
            "invalid pool ETH balance"
        );
        assertEq(
            token1.balanceOf(address(pool)),
            uint256(int256(poolBalance1) + amount1Delta),
            "invalid pool USDC balance"
        );

        // Here we check that the pool state was updated correctly
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        asserEq(sqrtPriceX96, 5602277097478614198912276234240, "invalid current sqrtP");
        assertEq(tick, 85184, "inavlid current tick");
        assertEq(pool.liquidity(), 1517882343751509868544, "invalid current liquidity");
    }
}
