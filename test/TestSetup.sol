// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MainContract.sol";
import "../src/StarToken.sol";
import "./mocks/MockUniswapV2Router.sol";

contract TestSetup is Test {
    StarDApp public starDApp;
    StarToken public starToken;
    MockUniswapV2Router public mockUniswapRouter;

    address public owner;
    address public user1;
    address public user2;
    address public Address1;
    address public Address2;

    function setUpTests() public {
        console.log("Starting setup on Sepolia...");

        // Fork Sepolia
        vm.selectFork(vm.createFork(vm.envString("SEPOLIA_RPC_URL")));

        owner = address(this);
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        Address1 = vm.addr(3);
        Address2 = vm.addr(4);

        // Fund test accounts
        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        vm.startPrank(owner);

        console.log("Deploying StarToken...");
        starToken = new StarToken();
        require(address(starToken) != address(0), "StarToken deployment failed");

        console.log("Setting permitted addresses for StarToken...");
        starToken.setPermittedAddress(Address1, Address2);

        console.log("Minting initial supply...");
        starToken.mintForInitialSupply();

        console.log("Deploying mock Uniswap router...");
        mockUniswapRouter = new MockUniswapV2Router();

        console.log("Deploying StarDApp...");
        starDApp = new StarDApp(address(starToken), address(mockUniswapRouter));

        // Mint some tokens for testing
        starToken.mint(user1, 1000 ether);
        starToken.mint(user2, 1000 ether);

        vm.stopPrank();

        console.log("Setup completed successfully");
    }

    function mockUniswapRouterCall(uint256 amountIn, uint256 amountOut) internal {
        address[] memory path = new address[](2);
        path[0] = address(starToken);
        path[1] = address(0); // Use a dummy address instead of WETH

        uint[] memory amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        vm.mockCall(
            address(mockUniswapRouter),
            abi.encodeWithSelector(MockUniswapV2Router.swapExactTokensForTokens.selector),
            abi.encode(amounts)
        );
        vm.mockCall(
            address(mockUniswapRouter),
            abi.encodeWithSelector(MockUniswapV2Router.swapExactETHForTokens.selector),
            abi.encode(amounts)
        );
        vm.mockCall(
            address(mockUniswapRouter),
            abi.encodeWithSelector(MockUniswapV2Router.swapExactTokensForETH.selector),
            abi.encode(amounts)
        );
    }
}