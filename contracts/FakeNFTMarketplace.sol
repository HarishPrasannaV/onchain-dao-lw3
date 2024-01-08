// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

contract FakeNFTMarketplace {
    // TokenID to owner address mapping
    mapping(uint256 => address) public tokens;

    // nft price
    uint256 nftPrice = 0.1 ether;

    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT Costs 0.1 ether");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    // function to check for the availability of a token
    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        } else {
            return false;
        }
    }
}
