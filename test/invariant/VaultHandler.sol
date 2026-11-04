// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TokenVault} from "../../src/TokenVault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

/// @notice Handler: фаззер вызывает только эти функции. Входы ограничены (bound),
/// вызовы выполняются от имени трёх участников, теневые переменные считают потоки токенов.
contract VaultHandler is Test {
    TokenVault public vault;
    MockERC20 public token;
    address[] public actors;

    uint256 public ghost_deposited;
    uint256 public ghost_withdrawn;

    constructor(TokenVault vault_, MockERC20 token_) {
        vault = vault_;
        token = token_;
        actors.push(makeAddr("alice"));
        actors.push(makeAddr("bob"));
        actors.push(makeAddr("carol"));
    }

    function actorsCount() external view returns (uint256) {
        return actors.length;
    }

    function deposit(uint256 actorSeed, uint256 amount) external {
        address actor = _actor(actorSeed);
        amount = bound(amount, 1, 1e24);
        token.mint(actor, amount);
        vm.startPrank(actor);
        token.approve(address(vault), amount);
        vault.deposit(amount);
        vm.stopPrank();
        ghost_deposited += amount;
    }

    function withdraw(uint256 actorSeed, uint256 amount) external {
        address actor = _actor(actorSeed);
        amount = bound(amount, 0, vault.balanceOf(actor));
        vm.prank(actor);
        vault.withdraw(amount);
        ghost_withdrawn += amount;
    }

    function transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) external {
        address from = _actor(fromSeed);
        address to = _actor(toSeed);
        amount = bound(amount, 0, vault.balanceOf(from));
        vm.prank(from);
        vault.transfer(to, amount);
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[bound(seed, 0, actors.length - 1)];
    }
}
