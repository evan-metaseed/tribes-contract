// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721Common.sol";

contract Tribesters is ERC721Common, ReentrancyGuard, Ownable {
    uint256 public PRICE = 0 ether;
    uint256 public PRESALE_PRICE = 0 ether;
    uint256 public maxPresale = 3;
    uint256 public maxPublic = 3;

    bool public _isActive = false;
    bool public _presaleActive = false;

    mapping(address => uint8) public _preSaleListCounter;
    mapping(address => uint8) public _publicCounter;
    

    // merkle root
    bytes32 public preSaleRoot;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721Common(name, symbol, baseURI) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //set variables
    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function presaleActive(bool isActive) external onlyOwner {
        _presaleActive = isActive;
    }

    function setMaxPresale(uint256 _maxPresale) external onlyOwner {
        maxPresale = _maxPresale;
    }

    function setMaxPublic(uint256 _maxPublic) external onlyOwner {
        maxPublic = _maxPublic;
    }

    function setPreSaleRoot(bytes32 _root) external onlyOwner {
        preSaleRoot = _root;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        PRESALE_PRICE = _price;
    }

    // Internal for marketing, devs, etc
    function internalMint(uint256 quantity, address to)
        external
        onlyOwner
    {
        _safeMint(to, quantity);
    }

    // Presale
    function mintPreSaleTokens(uint8 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(_presaleActive, "Pre mint is not active");
        require(
            _preSaleListCounter[msg.sender] + quantity <= maxPresale,
            "Exceeded max available to purchase"
        );
        require(quantity > 0, "Must mint more than 0 tokens");
        require(PRESALE_PRICE * quantity == msg.value, "Incorrect funds");

        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, preSaleRoot, leaf),
            "Invalid MerkleProof"
        );
        _safeMint(msg.sender, quantity);
        _preSaleListCounter[msg.sender] =
            _preSaleListCounter[msg.sender] +
            quantity;
    }

    // public mint
    function publicSaleMint(uint8 quantity)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(quantity > 0, "Must mint more than 0 tokens");
        require(_isActive, "public sale has not begun yet");
        require(PRICE * quantity == msg.value, "Incorrect funds");
        require(
            _publicCounter[msg.sender] + quantity <= maxPublic,
            "Exceeded max available to purchase"
        );

        _safeMint(msg.sender, quantity);
        _publicCounter[msg.sender] = _publicCounter[msg.sender] + quantity;
    }
}
