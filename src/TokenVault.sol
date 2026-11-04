// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Хранилище токенов с внутренними долями (учебный контракт BPD 2024, ПЗ1)
/// @notice Требования к контракту - в README.md. Контракт содержит намеренные ошибки.
contract TokenVault {
    IERC20 public immutable asset;
    address public owner;
    bool public paused;

    /// @notice Сумма долей всех участников.
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Paused(bool paused);

    constructor(IERC20 asset_) {
        asset = asset_;
        owner = msg.sender;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function setPaused(bool paused_) external {
        require(msg.sender == owner, "not owner");
        paused = paused_;
        emit Paused(paused_);
    }

    /// @notice Внести `amount` токенов и получить столько же долей.
    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "zero amount");
        asset.transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Deposit(msg.sender, amount);
    }

    /// @notice Погасить `amount` долей и получить столько же токенов.
    function withdraw(uint256 amount) external whenNotPaused {
        require(balanceOf[msg.sender] >= amount, "insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        asset.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice Передать `amount` долей адресу `to` (оптимизировано: меньше чтений хранилища).
    function transfer(address to, uint256 amount) external whenNotPaused {
        uint256 fromBalance = balanceOf[msg.sender];
        uint256 toBalance = balanceOf[to];
        require(fromBalance >= amount, "insufficient balance");
        balanceOf[msg.sender] = fromBalance - amount;
        balanceOf[to] = toBalance + amount;
        emit Transfer(msg.sender, to, amount);
    }
}
