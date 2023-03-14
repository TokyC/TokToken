pragma solidity ^0.5.10;

contract Administrable {
	address private _admin;
    mapping (address => bool) private _vip;
    mapping (address => bool) private _whitelist;

    event AdminshipTransferred(address indexed currentAdmin, address indexed newAdmin);
    event AddVIP(address indexed account);
    event RemoveVIP(address indexed account);
    event AddWhitelist(address indexed account);
    event RemoveWhitelist(address indexed account);

	constructor() internal {
		_admin = msg.sender;
        emit AdminshipTransferred(address(0), _admin);
	}

    function admin() public view returns (address) {
        return _admin;
    }

	modifier onlyAdmin() {
		require(msg.sender == _admin, "Only Admin can perform this action.");
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

	function transferAdminship(address newAdmin) public onlyAdmin {
        emit AdminshipTransferred(_admin, newAdmin);
        _admin = newAdmin;
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
}

contract TokToken {
    

}