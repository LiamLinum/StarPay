// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/interfaces/IUniswapV2Router02.sol";

contract MockUniswapV2Router is IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address,
        uint
    ) external pure override returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = amountOutMin;
        return amounts;
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address,
        uint
    ) external payable override returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = msg.value;
        amounts[path.length - 1] = amountOutMin;
        return amounts;
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address,
        uint
    ) external pure override returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = amountOutMin;
        return amounts;
    }

    // Implement a dummy WETH() function to satisfy the interface
    function WETH() external pure override returns (address) {
        return address(0);
    }
}