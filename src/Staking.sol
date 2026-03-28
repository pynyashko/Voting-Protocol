// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
    IERC20 public immutable token;

    address public owner;

    struct Stake {
        uint256 amount;
        uint256 start;
        uint256 expiry;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Unstaked(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    // Staking logic
    function stake(uint256 amount, uint256 duration) external {
        require(amount > 0, "Zero amount");
        require(duration > 0, "Zero duration");

        Stake storage s = stakes[msg.sender];

        // запрещаем второй стейк
        require(s.amount == 0, "Already staked");

        // переводим токены в контракт
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        // записываем стейк
        stakes[msg.sender] = Stake({amount: amount, start: block.timestamp, expiry: block.timestamp + duration});

        emit Staked(msg.sender, amount, duration);
    }

    function unstake() external nonReentrant {
        Stake memory s = stakes[msg.sender];

        require(s.amount > 0, "No stake");
        require(block.timestamp >= s.expiry, "Not expired");

        delete stakes[msg.sender];

        bool success = token.transfer(msg.sender, s.amount);
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, s.amount);
    }

    function votingPower(address user) public view returns (uint256) {
        Stake memory s = stakes[user];

        if (s.amount == 0) return 0;

        if (block.timestamp >= s.expiry) {
            return 0;
        }

        uint256 remaining = s.expiry - block.timestamp;
        uint256 duration = s.expiry - s.start;

        if (duration == 0) return 0;

        return (s.amount * remaining) / duration;
    }

    function getStake(address user) external view returns (Stake memory) {
        return stakes[user];
    }

    // На случай бага
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner {
        bool success = token.transfer(to, amount);
        require(success, "Transfer failed");
    }
}
