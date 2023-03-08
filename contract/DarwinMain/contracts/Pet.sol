// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

import {ERC721, Proxy, ProxyContractBase, ReentrancyGuarded, Ownable, SafeMath} from "./Darwin721.sol";
import {ArrayUtils} from "./ArrayUtils.sol";

abstract contract  PetStore is ReentrancyGuarded, ERC721, ProxyContractBase {
    mapping(uint256=>bool) public _gen0Pet;
    mapping(uint256=>uint256) public _lastMating;
    uint64 public _gen0Count;
    mapping(uint256 => bool) public _orderIdMap;
    mapping (address => bool) internal _whiteMap;
    
    /* An ECDSA signature. */ 
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /* An order on the exchange. */
    struct Order {
        uint256 orderId;

        uint256 tokenId;

        uint256 tokenTag;

        uint[]  consumeId;

        uint[]  consumeAmount;        
    }
}


contract PetProxy is  Proxy, PetStore{
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        
    }
    
    function upgradeTo(address impl) public onlyOwner {
        require(_implementation != impl);
        _implementation = impl;
    }
    
    /**
    * @return The Address of the implementation.
    */
    function implementation() public override virtual view returns (address){
        return _implementation;
    }
    
    
    /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }

  /**
   * @dev Receive function.
   * Implemented entirely in `_fallback`.
   */
  receive () payable external {
    _fallback();
  }
}



contract Pet is PetStore{
    using SafeMath for uint256;

    event Gen0Born(address indexed player, uint256 indexed tokenId);
    event Gen1Born(address indexed player, uint256 indexed father, uint256 indexed mother, uint256 tokenId);
    event Gen1Evo(address indexed player,uint256 indexed pet1, uint256 indexed pet2, uint256 tokenId);
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        
    }

    //add white
    function addWhite(address addr) public onlyOwner {
       require(addr != address(0), "addr must not zero");
       _whiteMap[addr] = true;
    }

    //remove white
    function removeWhite(address addr) public onlyOwner {
       require(addr != address(0), "addr must not zero");
       delete _whiteMap[addr];
    }

    function isWhite(address addr) public view returns (bool){
        require(addr != address(0), "addr must not zero");
        return _whiteMap[addr];
    }

     //set base uri
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function version() public pure returns (uint){
        return 1;
    }

    function periodOfMating() public pure returns (uint) {
        return 604800;  //1 week
    }

    function isGen0(uint256 tokenId) public view returns (bool){
        return _gen0Pet[tokenId];
    }

    function canMating(uint256 fatherId, uint256 motherId) public view returns (bool){
        return (isGen0(fatherId) && isGen0(motherId)) &&
            ( block.timestamp >= (_lastMating[fatherId] + periodOfMating()) && 
              block.timestamp >= (_lastMating[motherId] + periodOfMating()));
    }


    function gen0Supply() public view returns (uint256){
        return _gen0Count;
    }

    function gen0MaxSupply() public pure returns (uint64){
        return 4999;
    }

    function gen0Price(address addr) public  view returns (uint256){
        //0.01 Matic
        uint256 price = 10000000000000000;
        if(isWhite(addr)){  //0.8
            price = price.mul(8000).div(10000);
        }
        return price;
    }

    function gen0mint() public reentrancyGuard payable{
        require(contractIsOpen, "contract is close");

        require(gen0Supply() < gen0MaxSupply(), "gen 0 pet is sold out");

        require(msg.value == gen0Price(msg.sender), "gen 0 price unmatch");

        if(isWhite(msg.sender)){    //white name used
            removeWhite(msg.sender);
        }

        uint256 tokenId = totalSupply() + 1;

        require(!_exists(tokenId), "ERC721: token already minted");

        _gen0Count += 1;

        _gen0Pet[tokenId] = true;
        
        _safeMint(msg.sender, tokenId);

        emit Gen0Born(msg.sender, tokenId);
    }

    function mating(uint256 orderId, uint256 fatherId, uint256 motherId, uint[] memory consumeIds, uint[] memory consumeAmounts, uint8 v, bytes32 r, bytes32 s) public reentrancyGuard{
        require(contractIsOpen, "contract is close");

        require(isGen0(fatherId) && isGen0(motherId), "mating only available on gen0 pet");

        require(ownerOf(fatherId) == msg.sender || ownerOf(motherId) == msg.sender, "mating only available on gen0 pet");

        require(verifyOrder(orderId, fatherId, motherId, consumeIds, consumeAmounts, v, r, s), "verify Order error");

        require(canMating(fatherId, motherId), "one pet in mating period");

        _lastMating[fatherId] = block.timestamp;
        _lastMating[motherId] = block.timestamp;

        uint256 tokenId = totalSupply() + 1;
        _safeMint(ownerOf(fatherId), tokenId);

        emit Gen1Born(msg.sender, fatherId, motherId, tokenId);

        tokenId = totalSupply() + 1;
        _safeMint(ownerOf(motherId), tokenId);
        
        emit Gen1Born(msg.sender, fatherId, motherId, tokenId);        
    }

    function evolution(uint256 pet1, uint256 pet2)public reentrancyGuard{
        require(contractIsOpen, "contract is close");

        require(!isGen0(pet1) && !isGen0(pet2), "evolution only available on gen1 pet");

        require(ownerOf(pet1) == msg.sender && ownerOf(pet1) == msg.sender, "mating only available on gen0 pet");

        _burn(pet1);

        _burn(pet2);

        uint256 tokenId = totalSupply() + 1;
        _safeMint(ownerOf(pet1), tokenId);
        
        emit Gen1Evo(msg.sender, pet1, pet2, tokenId);        
    }

    function sizeOf()
        internal
        pure
        returns (uint)
    {   
        //address   = 0x14
        //uint      = 0x20
        //uint8     = 1
        //uint256   = 0x100
        //return (0x100 * 3 + 0x20 * 8 + 0x14 * 1);
        return (0x100 * 3 + 0x20 * 8);
    }
     // 签名账户
    function signAddress() private pure returns(address){
        return address(0x34C533Bdd04d02a71d836463Aae0503854734eF1);
    }

    function hashOrder(Order memory order) internal pure returns(bytes32 hash) {
        uint size = sizeOf();
        bytes memory array = new bytes(size);
        uint index;
        assembly {
            index := add(array, 0x20)
        }

        index = ArrayUtils.unsafeWriteUint(index, order.orderId);

        index = ArrayUtils.unsafeWriteUint(index, order.tokenId);

        index = ArrayUtils.unsafeWriteUint(index, order.tokenTag);
        
        for(uint i = 0; i< 4; i++){
            index = ArrayUtils.unsafeWriteUint(index, order.consumeId[i]);
        }

        for(uint i = 0; i< 4; i++){
            index = ArrayUtils.unsafeWriteUint(index, order.consumeAmount[i]);
        }
        
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    function hashOrder_(uint256 orderId, uint256 tokenId, uint256 tokenTag, uint[] memory consumeIds, uint[] memory consumeAmounts) public pure returns (bytes32){
        return hashOrder(
            Order(orderId, tokenId, tokenTag, consumeIds, consumeAmounts)
        );
    }

     function hashToSign_(uint256 orderId, uint256 tokenId, uint256 tokenTag, uint[] memory consumeIds, uint[] memory consumeAmounts) public pure returns (bytes32){
        return hashToSign(
            Order(orderId, tokenId, tokenTag, consumeIds, consumeAmounts)
        );
    }
  
     function hashToSign(Order memory order)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOrder(order)));
    }

    function orderIdExist(uint256 orderId) public view  returns (bool) {
        return _orderIdMap[orderId];
    }
    
    function cancelOrder(uint256 orderId) public reentrancyGuard {
        require(!orderIdExist(orderId), "Order id check error");

        _orderIdMap[orderId] = true;
    }

    function verifyOrder(uint256 orderId, uint256 tokenId, uint256 tokenTag, uint[] memory consumeIds, uint[] memory consumeAmounts, uint8 v, bytes32 r, bytes32 s) internal returns(bool)  {            

        require(validateOrder_(orderId, tokenId, tokenTag, consumeIds, consumeAmounts, v, r, s), "Order validate error");

        _orderIdMap[orderId] = true;

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function validateOrder(bytes32 hash, Order memory order, Sig memory sig) 
        internal
        view
        returns (bool)
    {
        /* Order must have not been canceled or already filled. */
        if (orderIdExist(order.orderId)) {
            return false;
        }
        
        /* or (b) ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == signAddress()) {
            return true;
        }

        return false;
    }

    
    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_ (
        uint256 orderId, uint256 tokenId, uint256 tokenTag, uint[] memory consumeIds, uint[] memory consumeAmounts, uint8 v, bytes32 r, bytes32 s) 
        view public returns (bool)
    {
        Order memory order = Order(orderId, tokenId, tokenTag, consumeIds, consumeAmounts);
        return validateOrder(
          hashToSign(order),
          order,
          Sig(v, r, s)
        );
    }
}


    