// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TestSetup.sol";

contract MainContractTest is TestSetup {
    function setUp() public {
        setUpTests();
    }

    function test_InitialSetup() public {
        console.log("Testing initial setup...");
        assertEq(address(starToken), address(starDApp.starToken()), "StarToken address mismatch");
        assertEq(address(mockUniswapRouter), address(starDApp.uniswapRouter()), "UniswapRouter address mismatch");
        assertEq(starToken.balanceOf(user1), 1000 * 10**18, "User1 balance incorrect");
        assertEq(starToken.balanceOf(user2), 1000 * 10**18, "User2 balance incorrect");
        assertEq(user1.balance, 100 ether, "User1 ETH balance incorrect");
        assertEq(user2.balance, 100 ether, "User2 ETH balance incorrect");
    }

    function test_RegisterUser() public {
        console.log("Testing user registration...");
        vm.prank(user1);
        starDApp.registerUser("Alice");
        (bool isRegistered, string memory username, address generatedWallet) = starDApp.users(user1);
        assertTrue(isRegistered, "User not registered");
        assertEq(username, "Alice", "Username mismatch");
        assertTrue(generatedWallet != address(0), "Generated wallet should not be zero address");
    }

    function test_RegisterUserTwice() public {
        vm.startPrank(user1);
        starDApp.registerUser("Alice");
        vm.expectRevert("User already registered");
        starDApp.registerUser("Alice2");
        vm.stopPrank();
    }

    function test_GeneratedWalletUniqueness() public {
        vm.prank(user1);
        starDApp.registerUser("Alice");
        (,, address wallet1) = starDApp.users(user1);

        vm.prank(user2);
        starDApp.registerUser("Bob");
        (,, address wallet2) = starDApp.users(user2);

        assertTrue(wallet1 != wallet2, "Generated wallets should be unique");
    }

   function test_SendTokens() public {
        vm.startPrank(user1);
        starDApp.registerUser("Alice");
        (,, address generatedWallet) = starDApp.users(user1);

        uint256 amount = 100 * 10**18;
        
        // Transfer tokens to the generated wallet
        starToken.transfer(generatedWallet, amount);
        
        // Approve StarDApp to spend tokens on behalf of the generated wallet
        vm.stopPrank();
        vm.prank(generatedWallet);
        starToken.approve(address(starDApp), amount);

        // Check initial balances
        uint256 initialSenderBalance = starToken.balanceOf(generatedWallet);
        uint256 initialReceiverBalance = starToken.balanceOf(user2);

        // Send tokens
        vm.prank(user1);
        starDApp.sendTokens(user2, amount);

        // Check final balances
        uint256 finalSenderBalance = starToken.balanceOf(generatedWallet);
        uint256 finalReceiverBalance = starToken.balanceOf(user2);

        assertEq(finalSenderBalance, initialSenderBalance - amount, "Sender balance not reduced correctly");
        assertEq(finalReceiverBalance, initialReceiverBalance + amount, "Receiver balance not increased correctly");
    }

    function test_SendTokensUnregisteredUser() public {
        vm.prank(user1);
        vm.expectRevert("User not registered");
        starDApp.sendTokens(user2, 100 * 10**18);
    }

    

    function test_SwapTokens() public {
        address mockToken = address(0x123);
        uint256 amountIn = 100 * 10**18;
        uint256 amountOutMin = 90 * 10**18;
        mockUniswapRouterCall(amountIn, amountOutMin);

        vm.startPrank(user1);
        starDApp.registerUser("Alice");
        (,, address generatedWallet) = starDApp.users(user1);

        // Transfer tokens to the generated wallet
        starToken.transfer(generatedWallet, amountIn);
        
        // Approve StarDApp to spend tokens on behalf of the generated wallet
        vm.stopPrank();
        vm.prank(generatedWallet);
        starToken.approve(address(starDApp), amountIn);

        // Check initial balance
        uint256 initialBalance = starToken.balanceOf(generatedWallet);

        // Perform the swap
        vm.prank(user1);
        starDApp.swapTokens(address(starToken), mockToken, amountIn, amountOutMin);

        // Check final balance
        uint256 finalBalance = starToken.balanceOf(generatedWallet);

        assertEq(initialBalance - finalBalance, amountIn, "Incorrect amount of tokens swapped");
    }

    function test_SwapTokensUnregisteredUser() public {
        vm.prank(user1);
        vm.expectRevert("User not registered");
        starDApp.swapTokens(address(starToken), address(0x123), 100 * 10**18, 90 * 10**18);
    }
}