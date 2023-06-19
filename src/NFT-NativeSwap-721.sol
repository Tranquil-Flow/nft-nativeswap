// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


    /*
    TO-DO
     - Add deadlines to proposals 
     - Add option to trade any token (ERC20, ERC721 + ERC1155)
     - Reentrancy Guard can be removed?
    */

contract NFTNativeSwap721 is ERC721, Ownable, ReentrancyGuard {
    
    struct TradeOffers {
        address token;
        uint amount;
        address proposer;
        bool offerValid;
    }

    mapping(uint => TradeOffers[]) public offersByID;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
    }

    // For testing purposes
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    // Function for potential buyer to propose a trade on a specified NFT
    function proposeTrade(
        uint tokenID,   // The tokenID of the NFT in the series
        address offeredToken, // The address of the token being offered in the trade
        uint offeredAmount  // The amount of tokens being offered in the trade
    ) public {
        TradeOffers memory newOffer = TradeOffers(offeredToken, offeredAmount, msg.sender, true);
        offersByID[tokenID].push(newOffer);

        // Deposit proposed tokens
        IERC20(offeredToken).transferFrom(msg.sender, address(this), offeredAmount);
    }

    // Function for owner of an NFT to accept a trade proposal
    function acceptTrade(
        uint tokenID,
        uint proposalID
    ) public nonReentrant {
        address nftOwner = ownerOf(tokenID);
        require(msg.sender == nftOwner, "Caller is not the owner of the NFT");
        TradeOffers memory acceptedTrade = offersByID[tokenID][proposalID];
        
        IERC20(acceptedTrade.token).transferFrom(address(this), nftOwner, acceptedTrade.amount);
        safeTransferFrom(nftOwner, acceptedTrade.proposer, tokenID);

        offersByID[tokenID][proposalID] = TradeOffers(
            address(0),
            0,
            address(0),
            false
        );
    }

    // Function to cancel a trade proposal
    function cancelProposedTrade(
        uint tokenID,
        uint proposalID
    ) public {
        TradeOffers memory cancelledTrade = offersByID[tokenID][proposalID];
        require(cancelledTrade.proposer == msg.sender, "Caller is not the proposer of the trade offer");

        address offeringToken = cancelledTrade.token;
        uint offeringAmount = cancelledTrade.amount;

        offersByID[tokenID][proposalID] = TradeOffers(
            address(0),
            0,
            address(0),
            false
        );

        // Retrieve  proposed tokens
        IERC20(offeringToken).transferFrom(address(this), msg.sender, offeringAmount);
    } 

    // Function to view a trade proposal
    function viewTradeOffer(
        uint tokenID,
        uint proposalID
    ) public view returns (address, uint, address, bool) {
        TradeOffers memory viewedOffer = offersByID[tokenID][proposalID];
        return (
            viewedOffer.token,
            viewedOffer.amount,
            viewedOffer.proposer,
            viewedOffer.offerValid
        );
    }

}