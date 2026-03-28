// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Staking.sol";
import "./VotingNFT.sol";

contract Voting {
    Staking public staking;

    VotingNFT public nft;

    address public owner;

    struct VotingStruct {
        bytes32 id;
        uint256 deadline;
        uint256 threshold;
        string description;

        uint256 yesVotes;
        uint256 noVotes;

        bool finalized;
    }

    mapping(bytes32 => VotingStruct) public votings;

    mapping(bytes32 => mapping(address => bool)) public voted;


    event VotingCreated(bytes32 indexed id, uint256 deadline, uint256 threshold);
    event Voted(bytes32 indexed id, address indexed user, bool support, uint256 power);
    event Finalized(bytes32 indexed id, bool passed);


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _staking, address _nft) {
        staking = Staking(_staking);
        nft = VotingNFT(_nft);
        owner = msg.sender;
    }



    function createVoting(
        bytes32 id,
        uint256 duration,
        uint256 threshold,
        string memory description
    ) external onlyOwner {

        require(votings[id].id == 0, "Already exists");
        require(duration > 0, "Zero duration");

        votings[id] = VotingStruct({
            id: id,
            deadline: block.timestamp + duration,
            threshold: threshold,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            finalized: false
        });

        emit VotingCreated(id, block.timestamp + duration, threshold);
    }


    function vote(bytes32 id, bool support) external {

        VotingStruct storage v = votings[id];

        require(v.id != 0, "Voting not found");
        require(block.timestamp < v.deadline, "Voting ended");
        require(!v.finalized, "Already finalized");
        require(!voted[id][msg.sender], "Already voted");

        uint256 power = staking.votingPower(msg.sender);
        require(power > 0, "No voting power");

        voted[id][msg.sender] = true;

        if (support) {
            v.yesVotes += power;
        } else {
            v.noVotes += power;
        }

        emit Voted(id, msg.sender, support, power);
    }


    function finalize(bytes32 id) external {

        VotingStruct storage v = votings[id];

        require(v.id != 0, "Voting not found");
        require(!v.finalized, "Already finalized");


        require(
            block.timestamp >= v.deadline ||
            v.yesVotes >= v.threshold,
            "Not finished"
        );

        v.finalized = true;

        bool passed = v.yesVotes >= v.threshold;

        nft.mint(msg.sender, id, passed, v.yesVotes, v.noVotes, v.description);

        emit Finalized(id, passed);
    }



    function getVotes(bytes32 id) external view returns (uint256 yes, uint256 no) {
        VotingStruct memory v = votings[id];
        return (v.yesVotes, v.noVotes);
    }

    function hasVoted(bytes32 id, address user) external view returns (bool) {
        return voted[id][user];
    }

    function isActive(bytes32 id) external view returns (bool) {
        VotingStruct memory v = votings[id];
        return block.timestamp < v.deadline && !v.finalized;
    }
}