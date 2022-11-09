// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// function to get colataraliez asset
// function to know what kind of aaset we are getting
// function to define the percentage of collatrazied to dai token
//

contract FDai {
    //auth
    mapping(address => uint256) public wards;

    function rely(address guy) external auth {
        wards[guy] = 1;
    }

    function deny(address guy) external auth {
        wards[guy] = 0;
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "Dai/not-authorized");
        _;
    }

    //ERC20 data

    string public constant name = "Dao stablecoin";
    string public constant symbol = "DAO";
    string public constant version = "1";
    string public constant decimal = "18";
    uint256 public totalSupply;

    // allownce ,signature , and permit things
    mapping(address => uint256) public BalanceOf;
    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public wad;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    // math

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    bytes32 public DOMAIN_SEPREATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 ChainID) public {
        wards[msg.sender] = 1;
        DOMAIN_SEPREATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                ChainID,
                address(this)
            )
        );
    }

    // token
    function transfer(address dst, uint256 wad) external returns (bool) {
        return TransferFrom(msg.sender, dst, wad);
    }

    function TransferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(BalanceOf[src] >= wad, "DAI , Insufficient balance");
        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
            require(
                allowance[src][msg.sender] >= wad,
                "dai insufficient allowance"
            );
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        BalanceOf[src] = sub(BalanceOf[src], wad);
        BalanceOf[dst] = add(BalanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function mint(address usr, uint256 wad) external auth {
        BalanceOf[usr] = add(BalanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }

    function Burn(address usr, uint256 wad) external {
        require(BalanceOf[usr] >= wad, "insufficeide balcne");
        if (
            usr != msg.sender && allowance[usr][msg.sender] != type(uint256).max
        ) {
            require(allowance[usr][msg.sender] > wad, "INF");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        BalanceOf[usr] = sub(BalanceOf[usr], wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    function push(address usr, uint256 wad) external {
        TransferFrom(msg.sender, usr, wad);
    }

    function pull(address usr, uint256 wad) external {
        TransferFrom(usr, msg.sender, wad);
    }

    function move(
        address src,
        address dst,
        uint256 wad
    ) external {
        TransferFrom(src, dst, wad);
    }

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPREATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        holder,
                        spender,
                        nonce,
                        expiry,
                        allowed
                    )
                )
            )
        );
        require(holder != address(0), "invalid address");
        require(expiry == 0 || block.timestamp <= expiry, "time ended bro");
        require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit");
        require(nonce == nonces[holder]++, "dao/invlid bro");

        if (allowed) {
            int256 wad = -1;
        } else {
            wad = 0;
        }
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }

    //  function mintDai(uint256 value) {}

    //function amountToMint(uint256 CollataralizedValue) {}
}
