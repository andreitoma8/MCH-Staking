// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonChessToken is
    ERC20,
    ERC20Burnable,
    ERC20Votes,
    Ownable,
    KeeperCompatibleInterface
{
    // The interval for minting new tokens for Game & Staking Rewards
    uint256 public immutable interval;

    // The timestamp of the latest execution of ChainLink Keepers
    uint256 public lastTimeStamp;

    // The time of start for minting staking and game rewards
    uint256 public firstTimeStamp;

    // This will be turned on when staking is enabled. It cannot be turned off later, even by the owner.
    bool public stakingStarted;

    // Address of the Staking Pool
    address public stakingPool;

    // Address of the Game to send rewards tokens to
    address public gameAddress;

    // Mint 100.000.000.000 Tokens on contract deployment
    constructor() ERC20("MoonChess", "MCH") ERC20Permit("MoonChess") {
        _mint(msg.sender, 1000000000000 * 10**18);
        interval = 21600;
    }

    // Keepers function that checks if Upkeep action is needed
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded =
            (block.timestamp - lastTimeStamp) > interval &&
            stakingStarted;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    // Function called by ChainLink Upkeeper
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        require((block.timestamp - lastTimeStamp) > interval && stakingStarted);
        lastTimeStamp = block.timestamp;
        _mint(stakingPool, mchToMint(1600000));
        _mint(gameAddress, mchToMint(2400000));
    }

    // Enables minting rewards for the staking pool and game rewards
    function startStaking() external onlyOwner {
        stakingStarted = true;
        firstTimeStamp = block.timestamp;
    }

    // Set the address of the staking pool
    function setStakingPool(address _stakingPool) external onlyOwner {
        stakingPool = _stakingPool;
    }

    // Set the address of the game
    function setGameAddress(address _game) external onlyOwner {
        gameAddress = _game;
    }

    // Internal function

    // Calculates the amount to mint per 6h for the Game and Staking rewards, based on the mining schedule
    function mchToMint(uint256 _amount) internal view returns (uint256) {
        return ((_amount * 10**18) /
            (2**((block.timestamp - firstTimeStamp) / 31556926)) +
            1);
    }

    // Overrides

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    //1600000 tokens per 6h
}
