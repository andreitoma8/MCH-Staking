// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IMoonChessToken.sol";

contract MoonChessStakin is ReentrancyGuard {
    IMoonChessToken public moonchessToken;

    // Define the MCH token contract
    constructor(IMoonChessToken _moonchessToken) {
        moonchessToken = _moonchessToken;
    }

    // Number of shares of the staking pool owned by each staker
    mapping(address => uint256) public shares;

    // The timeout period the user has after withdraw
    mapping(address => uint256) public timeout;

    // The total number of shares of the staking pool
    uint256 public totalShares;

    // The period a user is timed out for after he withdraws
    uint256 public timeoutPeriod = 90000;

    // Locks MCH
    function enter(uint256 _amount) public nonReentrant {
        // Check if user is timed out
        if (timeout[msg.sender] != 0) {
            require(
                block.timestamp >= timeout[msg.sender],
                "You have just withdrawn and are still timed out"
            );
        }
        // Gets the amount of SHACK locked in the contract
        uint256 totalMCH = moonchessToken.balanceOf(address(this));
        // If this is the first/only staker, give shares equal to the amount of MCH Deposited
        if (totalShares == 0 || totalMCH == 0) {
            shares[msg.sender] = _amount;
            totalShares += _amount;
        }
        // Calculate and give the amount of shares the MCH is worth. The ratio will change overtime, as shares are added/deleted and MCH deposited + gained.
        else {
            uint256 what = (_amount * totalShares) / totalMCH;
            shares[msg.sender] = what;
            totalShares += what;
        }
        // Lock the MCH in the contract
        moonchessToken.transferFrom(msg.sender, address(this), _amount);
    }

    // Unlocks the staked + gained MCH and burns shares
    function leave(uint256 _share) public nonReentrant {
        require(
            shares[msg.sender] >= _share,
            "You have tried to withdraw more shares than you have!"
        );
        // Calculates the amount of MCH the shares are worth
        uint256 what = (_share * moonchessToken.balanceOf(address(this))) /
            totalShares;
        shares[msg.sender] -= _share;
        totalShares -= _share;
        timeout[msg.sender] = block.timestamp + timeoutPeriod;
        moonchessToken.transfer(msg.sender, what);
    }

    function userDetails(address _user)
        external
        view
        returns (
            uint256 _sharesOwned,
            uint256 _totalValueLocked,
            uint256 _timeout
        )
    {
        return (
            shares[_user],
            (shares[_user] * moonchessToken.balanceOf(address(this))) /
                totalShares,
            timeout[msg.sender]
        );
    }
}
