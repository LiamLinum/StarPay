// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TestSetup.sol";
import "../utils/CustomErrors.sol";

contract StarTokenTest is TestSetup {
    function setUp() public {
        setUpTests();
    }


    function testInitialize() public {
        uint256 expectedSupply = starToken.initialSupply() + 2000 ether; // Initial supply + 1000 each for user1 and user2
        assertEq(starToken.totalSupply(), expectedSupply, "Total supply mismatch");
        assertEq(starToken.MAX_SUPPLY(), 100_000_000 ether, "Max supply mismatch");
        assertEq(starToken.initialSupply(), 15_000_000 ether, "Initial supply mismatch");
    }

    function testMintForInitialSupply() public {
        uint256 initialBalance = starToken.balanceOf(Address1);
        uint256 initialTotalSupply = starToken.totalSupply();
        vm.prank(owner);
        starToken.mintForInitialSupply();
        assertEq(starToken.balanceOf(Address1), initialBalance + starToken.initialSupply(), "Address1 balance mismatch");
        assertEq(starToken.totalSupply(), initialTotalSupply + starToken.initialSupply(), "Total supply mismatch after minting");
    }


    function testMint() public {
        uint256 initialBalance = starToken.balanceOf(user1);
        uint256 amountToMint = 1000 ether;
        vm.prank(owner);
        starToken.mint(user1, amountToMint);
        assertEq(starToken.balanceOf(user1), initialBalance + amountToMint);
    }

    function testMintExceedsMaxSupply() public {
        uint256 currentSupply = starToken.totalSupply();
        uint256 remainingSupply = starToken.MAX_SUPPLY() - currentSupply;
        
        vm.prank(owner);
        starToken.mint(owner, remainingSupply - 1 ether);  // Mint up to 1 ether less than max

        vm.expectRevert(ExceedsMaxSupply.selector);
        vm.prank(owner);
        starToken.mint(owner, 2 ether);  // Try to mint 2 ether, which should exceed max supply
    }

    function testBurn() public {
        uint256 initialBalance = starToken.balanceOf(user1);
        uint256 burnAmount = 500 ether;

        vm.prank(user1);
        starToken.burn(burnAmount);
        
        assertEq(starToken.balanceOf(user1), initialBalance - burnAmount);
    }

    function testBurnMoreThanBalance() public {
        uint256 balance = starToken.balanceOf(user1);

        vm.prank(user1);
        vm.expectRevert(ExceedsBalance.selector);
        starToken.burn(balance + 1);
    }

    function testOnlyOwnerCanMint() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user1));
        starToken.mint(user1, 1000 ether);
    }

    function testMintToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(AddressEqualsZero.selector);
        starToken.mint(address(0), 1000 ether);
    }

    function testBurnZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(InvalidAmount.selector);
        starToken.burn(0);
    }

    function testSetPermittedAddress() public {
        address newAddress1 = address(0x123);
        address newAddress2 = address(0x456);

        vm.prank(owner);
        starToken.setPermittedAddress(newAddress1, newAddress2);

        assertEq(starToken.Address1(), newAddress1);
        assertEq(starToken.Address2(), newAddress2);
    }

    function testSetPermittedAddressZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(AddressEqualsZero.selector);
        starToken.setPermittedAddress(address(0), address(0x456));
    }

    function testOnlyOwnerCanMintInitialSupply() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user1));
        starToken.mintForInitialSupply();
    }
}