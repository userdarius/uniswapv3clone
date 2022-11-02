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
        token0 = new ERC20Mintable(" Ether ", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }

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

        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            _params.currentSqrtP,
            _params.currentTick
        );

        if (_params.mintLiquidity) {
            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                _params.lowerTick,
                _params.upperTick,
                _params.liquidity
            );
        }

        shouldTransferInCallback = _params.shouldTransferInCallback;
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1) public {
        if (shouldTransferInCallback) {
            token0.transfer(msg.sender, amount0);
            token1.transfer(msg.sender, amount1);
        }
    }
}
