/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/


// SPDX-License-Identifier: MIT


pragma solidity ^0.7.1;

import {ERC721, Ownable, ReentrancyGuarded} from "./Darwin721.sol";



contract Land is ERC721, ReentrancyGuarded, Ownable{

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        
    }
    
    function version() public pure returns (uint){
        return 1;
    }


    function mint(uint256 tokenId) public reentrancyGuard{
        require(tokenId >= 1000000 && tokenId <= 1999999, "out of token range");

        require(!_exists(tokenId), "ERC721: token already minted");

//        require(balanceOf(msg.sender) == 0, "owner already minted a land");

        _safeMint(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
        require(from == address(0), "Err: token transfer is BLOCKED");   
        super._beforeTokenTransfer(from, to, tokenId);  
    }

}
