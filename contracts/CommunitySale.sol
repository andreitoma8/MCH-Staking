// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMoonChessToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommunitySale is Ownable, ReentrancyGuard {
    IMoonChessToken public mchToken;
    IERC20 public usdc;

    // Amount of packs bought by address
    mapping(address => uint256) public packsOwned;

    // Amount of MCH already claimed by each buyer
    mapping(address => uint256) public amountClaimed;

    // Total packs sold
    uint256 public totalPacksSold;

    // Price of one pack in USDC(100$)
    uint256 public priceOfPack = 100 ether;

    // The amount of MCH given per 1 Pack
    uint256 public mchPerPack = 22500000 ether;

    // The maximum amount of packs users can buy per transaction
    uint256 public maxPacksPerTx = 10;

    // The time the sale ended and unlocking schedule begins
    uint256 public saleEnd;

    // State of the sale
    bool public paused;

    constructor(IMoonChessToken _mchToken, IERC20 _usdc) {
        mchToken = _mchToken;
        usdc = _usdc;
    }

    // Function users call to buy packs
    // _amount = the amount of packs user wants to buy
    function buy(uint256 _amount) external nonReentrant {
        require(!paused, "Sale is not live!");
        require(_amount + totalPacksSold < 4000, "Sale supply exceeded!");
        require(
            _amount <= maxPacksPerTx,
            "Can't buy more than 10 packs per transaction!"
        );
        usdc.transferFrom(msg.sender, address(this), _amount * priceOfPack);
        packsOwned[msg.sender] += _amount;
        if (totalPacksSold == 4000) {
            saleEnd = block.timestamp;
        }
    }

    // Administrative function for owner
    function setState(bool _bool) external onlyOwner {
        paused = _bool;
    }

    // Claim your available MCH
    function claim() external nonReentrant {
        require(packsOwned[msg.sender] > 0, "You didn't buy any packs!");
        require(saleEnd != 0, "Sale is not over yet!");
        uint256 _amountToSend;
        if (block.timestamp - saleEnd >= 15778463) {
            _amountToSend =
                (packsOwned[msg.sender] * mchPerPack) -
                amountClaimed[msg.sender];
        } else {
            _amountToSend = claimableAmount(msg.sender);
        }
        amountClaimed[msg.sender] += _amountToSend;
        mchToken.transfer(msg.sender, _amountToSend);
    }

    // View claimable amount for _user
    function claimableAmount(address _user) public view returns (uint256) {
        if (packsOwned[_user] == 0) {
            return 0;
        } else if (block.timestamp - saleEnd >= 15778463) {
            return ((packsOwned[_user] * mchPerPack) - amountClaimed[_user]);
        } else {
            return
                ((15778463 - (block.timestamp - saleEnd)) *
                    ((mchPerPack * packsOwned[_user]) / 15778463)) -
                amountClaimed[_user];
        }
    }

    // Get the amount of packs bought and the already claimed MCH for user
    function userInfo(address _user)
        external
        view
        returns (uint256 _packsBought, uint256 _mchClaimed)
    {
        return (packsOwned[_user], amountClaimed[_user]);
    }
}
