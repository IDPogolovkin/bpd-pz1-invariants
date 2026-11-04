// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TokenVault} from "../../src/TokenVault.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {VaultHandler} from "./VaultHandler.sol";

/// @notice Инвариантные тесты. После каждого случайного вызова handler Foundry
/// проверяет все функции с префиксом invariant_.
contract VaultInvariants is Test {
    MockERC20 token;
    TokenVault vault;
    VaultHandler handler;

    function setUp() public {
        token = new MockERC20();
        vault = new TokenVault(token);
        handler = new VaultHandler(vault, token);
        targetContract(address(handler));
    }

    // TODO (А3), инвариант 1 - требование R1 из README:
    // сумма долей всех участников равна vault.totalSupply().
    // Участники: handler.actors(i), i от 0 до handler.actorsCount() - 1.
    //
    // function invariant_SumOfBalancesEqualsTotalSupply() public view {
    // }

    // TODO (А3), инвариант 2 - требование R2 из README (платёжеспособность):
    // токенов на балансе хранилища не меньше, чем сумма долей всех участников.
    //
    // function invariant_Solvency() public view {
    // }
}
