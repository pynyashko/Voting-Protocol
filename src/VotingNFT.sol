// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract VotingNFT is ERC721 {
    uint256 public tokenIdCounter;

    address public votingContract;

    struct VotingResult {
        bytes32 voteId;
        bool passed;
        uint256 yesVotes;
        uint256 noVotes;
        string description;
    }

    mapping(uint256 => VotingResult) public results;

    modifier onlyVoting() {
        require(msg.sender == votingContract, "Not voting contract");
        _;
    }

    constructor() ERC721("Voting Result NFT", "VRNFT") {
        votingContract = msg.sender;
    }

    function setVotingContract(address _voting) external {
        require(votingContract == msg.sender, "Already set");
        votingContract = _voting;
    }

    function mint(address to, bytes32 voteId, bool passed, uint256 yesVotes, uint256 noVotes, string memory description)
        external
        onlyVoting
        returns (uint256)
    {
        tokenIdCounter++;

        uint256 newTokenId = tokenIdCounter;

        _mint(to, newTokenId);

        results[newTokenId] = VotingResult({
            voteId: voteId, passed: passed, yesVotes: yesVotes, noVotes: noVotes, description: description
        });

        return newTokenId;
    }

    function getResult(uint256 tokenId) external view returns (VotingResult memory) {
        return results[tokenId];
    }
}
