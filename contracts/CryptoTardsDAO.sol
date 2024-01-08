// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);

    function purchase(uint256 _tokenId) external payable;
}

interface ICryptoTardsNFT {
    // Return the number of NFTs owned by the given address
    function balanceOf(address owner) external view returns (uint256);

    // Return token Id
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}

contract CryptoTardsDAO is Ownable {
    struct Proposal {
        // TokenID of the NFT to buy
        uint256 nftTokenId;
        // UNIX timestamp of deadline
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        // mapping of nft to votes(1 vote per NFT)
        mapping(uint256 => bool) voters;
    }

    // ProposalID to Proposal mapping
    mapping(uint256 => Proposal) public proposals;

    // Number of proposals that have been created
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoTardsNFT cryptoTardsNFT;

    // Inatializing the contracts and depositing eth to the treasury

    constructor(
        address _nftMarketplace,
        address _cryptoTardsNFT
    ) payable Ownable(owner()) {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoTardsNFT = ICryptoTardsNFT(_cryptoTardsNFT);
    }

    modifier nftHolderOnly() {
        require(
            cryptoTardsNFT.balanceOf(msg.sender) > 0,
            "You're not a member of the DAO"
        );
        _;
    }

    // return the proposal Id of the newly created proposal
    function createProposal(
        uint256 _nftTokenId
    ) external nftHolderOnly returns (uint256) {
        require(
            nftMarketplace.available(_nftTokenId),
            "The NFT is not for sale"
        );
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes; // deadline is 5mins after the current time

        numProposals++;

        return numProposals - 1;
    }

    // Modifier to call function if the function's deadline is not exceeded

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "Deadline Exceeded"
        );
        _;
    }

    enum Vote {
        YAY, // YAY returns uint 0
        NAY // NAY returns uint 1
    }

    function voteOnProposal(
        uint256 proposalIndex,
        Vote vote
    ) external nftHolderOnly activeProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];
        uint256 voterNFTBalance = cryptoTardsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // calculating the number of NFTs that haven't been used by the owner to vote on this proposal
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoTardsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        require(numVotes > 0, "Already Voted");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "Deadline Not exceeded"
        );
        require(
            proposals[proposalIndex].executed == false,
            "Proposal already executed"
        );
        _;
    }

    function executeProposal(
        uint256 proposalIndex
    ) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "Not Enough Funds");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "There is nothing to withdraw, contract is empty");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "Failed to withdraw Ether");
    }

    // Allowing a contract to dircetly accept ETH without calling a function

    receive() external payable {}

    fallback() external payable {}
}
