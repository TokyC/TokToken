// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Administrable {
	mapping (address => bool) private _admin;
    mapping (address => bool) private _vip;
    mapping (address => bool) private _whitelist;
    mapping (address => bool) private _banned;

    event AdminshipTransferred(address indexed currentAdmin, address indexed newAdmin);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event VIPAdded(address indexed account);
    event VIPRemoved(address indexed account);
    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);
    event Ban(address indexed account);
    event Unban(address indexed account);

	constructor() internal {
		_admin[msg.sender] = true;
        _vip[msg.sender] = true;
        emit AdminshipTransferred(address(0), _admin);
	}

    function admin() public view returns (address) {
        return _admin;
    }

	modifier onlyAdmin() {
        require(_admin[msg.sender] == true, "Only Admin can perform this action.");
        _;
    }

    modifier onlyVIP() {
        require(_vip[msg.sender], "Only VIP can perform this action.");
        _;
    }

    modifier onlyWhitelist() {
        require(_whitelist[msg.sender], "Only Whitelisted people can perform this action.");
        _;
    }

    modifier onlyNotBanned() {
        require(!_banned[msg.sender], "You are banned from performing this action.");
        _;
    } 

    function getKeyByValue(mapping (address => bool) storage map, bool value) internal view returns (address) {
        for (uint i = 0; i < 2**160; i++) {
            address key = address(i);
            if (map[key] == value) {
                return key;
            }
        }
        return address(0);
    }

	function transferAdminship(address newAdmin) public onlyAdmin {
        emit AdminshipTransferred(_admin, newAdmin);
        _admin = newAdmin;
	}

    function addAdmin(address account) public onlyAdmin {
        require(account != address(0), "Account address cannot be zero.");
        require(!_admin[account], "Account is already an admin.");
        _admin[account] = true;
        emit AdminAdded(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        require(account != address(0), "Account address cannot be zero.");
        require(_admin[account], "Account is not an admin.");
        _admin[account] = false;
        emit AdminRemoved(account);
    }


    function addVIP(address account) public onlyAdmin {
        require(account != address(0), "Account address cannot be zero.");
        _vip[account] = true;
        emit VIPAdded(account);
    }

    function removeVIP(address account) public onlyAdmin {
        require(account != address(0), "Account address cannot be zero.");
        _vip[account] = false;
        emit VIPRemoved(account);
    }

    function addWhitelist(address account) public onlyAdmin {
        require(account != address(0), "Account address cannot be zero.");
        _whitelist[account] = true;
        emit WhitelistAdded(account);
    }

    function removeWhitelist(address account) public onlyAdmin {
        require(account != address(0), "Account address cannot be zero.");
        _whitelist[account] = false;
        emit WhitelistRemoved(account);
    }

    function ban(address account) public onlyAdmin onlyNotBanned {
        require(account != address(0), "Account address cannot be zero.");
        _banned[account] = true;
        emit Ban(account);
    }

    function unban(address account) public onlyAdmin onlyNotBanned {
        require(account != address(0), "Account address cannot be zero.");
        _banned[account] = false;
        emit Unban(account);
    }
}

contract TokToken is ERC721, Ownable, Administrable {
    uint256 public constant MAX_SUPPLY = 5;
    uint256 private _tokenIdCounter;
    string private _name;
    string private _symbols;
    mapping (uint256 => string) private _tokenName;
    mapping (uint256 => uint256) private _tokenPrice;
    mapping (uint256 => bool) private _tokenForSale;

    uint256 public constant VIP_DISCOUNT = 20;


    constructor(string memory NFTName, string memory NFTSymbol) public {
        _name = NFTName;
        _symbols = NFTSymbol;
    }

    function mint(address to) public returns (uint256) {
        require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");
        _tokenIdCounter++;
        _safeMint(to, _tokenIdCounter);
        return _tokenIdCounter;
    }

    function _setTokenName(uint256 tokenId) internal {
        require(_exists(tokenId), "Token does not exist");
        string memory newName = string(abi.encodePacked("TokToken", tokenId.toString()));
        _tokenName[tokenId] = newName;
    }

    function tokenName(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenName[tokenId];
    }

    function setTokenForSale(uint256 tokenId, uint256 price) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of the token");
        require(price > 0, "Price must be greater than 0");
        _tokenPrice[tokenId] = price;
        _tokenForSale[tokenId] = true;
    }

    function cancelTokenSale(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of the token");
        _tokenForSale[tokenId] = false;
    }

    function buyToken(uint256 tokenId) public payable {
        require(_exists(tokenId), "Token does not exist");
        require(_tokenForSale[tokenId], "Token is not for sale");
        address payable ownerAddress = payable(ownerOf(tokenId));
        uint256 tokenPrice = _tokenPrice[tokenId];
        
        if (admin[msg.sender]) {
            tokenPrice = 0;
        }
        if (_vip[msg.sender]) {
            tokenPrice = tokenPrice.mul(100 - VIP_DISCOUNT).div(100);
        }
        require(msg.value == tokenPrice, "Incorrect amount sent");

        _transfer(ownerAddress, msg.sender, tokenId);
        _tokenForSale[tokenId] = false;
        payable(ownerAddress).transfer(msg.value);
    }
}