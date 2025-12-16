// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./TickMath.sol";
import './LiquidityMath.sol';

// 价格轴上的一个边界点为 Tick
library Tick {

    struct Info {
        // 所有以这个点作为边界（上/下界）的头寸流动性总和
        uint128 liquidityGross;
        // 向上穿过这个 Tick 时全局流动性该如何变化
        int128 liquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        bool initialized;
    }

    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        Info memory info = self[tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, liquidityDelta);
        
        require(liquidityGrossAfter <= maxLiquidity, 'Liquidity > max');

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);
        if (liquidityGrossBefore == 0) {
            info.initialized = true;
        }

        info.liquidityGross = liquidityGrossAfter;

        info.liquidityNet = upper
            ? int256(info.liquidityNet).sub(liquidityDelta).toInt128()
            : int256(info.liquidityNet).add(liquidityDelta).toInt128();
    }

    function clear(mapping(int24 => Tick.Info) storage self, int24 tick) internal {
        delete self[tick];
    }

    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128) {
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }
}