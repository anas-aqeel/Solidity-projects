// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract PToken is ERC20, Ownable {
    event CheckOwner(address);
    uint256 maxSupply;
    constructor() ERC20("PToken", "PTK") {
        maxSupply = 100000;
    }
   
    function mint(uint256 amount) public {
        require(totalSupply()+amount <= maxSupply, "Minting Limit Exceeded!");
        _mint(msg.sender, amount);
    }
}



struct PhasePrice  {
    uint priceInEth;
    uint priceInToken;
}

contract MyToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    PToken tokenContract;
    uint256 private _WhitelistPhase;
    uint256 private _PresalePhase;
    uint256 private _SalePhase;

    mapping(string => mapping(address=>uint256)) _phaseMintngs;

    constructor(PToken _tokenContract) ERC721("NFT", "NFT") {
        tokenContract=_tokenContract;
        _WhitelistPhase = block.timestamp + 7 days;
        _PresalePhase = _WhitelistPhase + 7 days;
        _SalePhase = _PresalePhase + 7 days ;
    }

    function _getPrice() internal view returns(PhasePrice memory price){
        if(block.timestamp < _WhitelistPhase ){
            price = PhasePrice(0.1 ether, 100);
        }else if(block.timestamp < _PresalePhase){
            price = PhasePrice(0.2 ether, 200);
        }else if(block.timestamp < _SalePhase)
        {
            price = PhasePrice(0.25 ether, 250);
        }
        else {
            revert("Sale Ended");
        }
    }

    function _getCurrentPhase() internal view returns(string memory){
        if(_getPrice().priceInEth==0.1 ether) return  "WHITELIST";
        else if(_getPrice().priceInEth==0.2 ether) return  "PRESALE";
        else if(_getPrice().priceInEth==0.25 ether) return  "SALE";
    }

    modifier mintChecker(){
        if(msg.value < _getPrice().priceInEth){
            require(tokenContract.allowance(msg.sender, address(this)) >= _getPrice().priceInToken, "Insufficient Ethers / Token Allowance!");
            tokenContract.transferFrom(msg.sender, address(this), _getPrice().priceInToken);
        }
        _;
    }
    modifier reentrancy(){
        require(_phaseMintngs[_getCurrentPhase()][msg.sender] == 0, "Already Minted!");
        _phaseMintngs[_getCurrentPhase()][msg.sender] =1;
        _;
    }
    function buy() public mintChecker reentrancy  payable {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function withdraw() payable public onlyOwner{
        payable(owner()).transfer(address(this).balance);
        tokenContract.transfer(owner(), tokenContract.balanceOf(address(this)));
    }
    
}
