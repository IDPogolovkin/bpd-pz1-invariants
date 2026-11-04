// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

/// @notice Тесты на примерах: все проходят, хотя контракт содержит ошибку.
contract TokenVaultTest is Test {
    MockERC20 token;
    TokenVault vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        token = new MockERC20();
        vault = new TokenVault(token);
        _deposit(alice, 100e18);
    }

    function _deposit(address who, uint256 amount) internal {
        token.mint(who, amount);
        vm.startPrank(who);
        token.approve(address(vault), amount);
        vault.deposit(amount);
        vm.stopPrank();
    }

    function test_Deposit() public view {
        assertEq(vault.balanceOf(alice), 100e18);
        assertEq(vault.totalSupply(), 100e18);
        assertEq(token.balanceOf(address(vault)), 100e18);
    }

    function test_Withdraw() public {
        vm.prank(alice);
        vault.withdraw(40e18);
        assertEq(vault.balanceOf(alice), 60e18);
        assertEq(token.balanceOf(alice), 40e18);
    }

    function test_Transfer() public {
        vm.prank(alice);
        vault.transfer(bob, 30e18);
        assertEq(vault.balanceOf(alice), 70e18);
        assertEq(vault.balanceOf(bob), 30e18);
    }

    function test_RevertWhen_WithdrawMoreThanBalance() public {
        vm.prank(alice);
        vm.expectRevert(bytes("insufficient balance"));
        vault.withdraw(101e18);
    }

    // А4: здесь добавляется fuzz-тест testFuzz_DepositWithdrawRoundTrip по требованию R3.
}
