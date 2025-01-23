// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";
import "../utils/CustomErrors.sol";

contract StarToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 100_000_000 ether;
    uint256 public immutable initialSupply = 15_000_000 ether;

    mapping(string => uint256) public rewards;
    mapping(string => mapping(uint256 => uint256)) private rewardDetails;

    address public Address1;
    address public Address2;

    event PermittedAddressesUpdated(address Address1, address Address2);

    event InitMinted(address Address1, uint256 initialSupply);

    event StarTokenMinted(address to, uint256 amount);

    constructor() ERC20("StarToken", "START") Ownable(msg.sender) {}

    /*-------- Modifiers --------*/

    modifier validCategory(string memory category) {
        if (rewards[category] == 0) {
            revert CategoryDoesNotExist();
        }
        _;
    }

    modifier checkAddressZero(address to) {
        if (to == address(0)) {
            revert AddressEqualsZero();
        }
        _;
    }

    modifier validAmount(uint256 amount) {
        if (amount == 0) {
            revert InvalidAmount();
        }
        _;
    }

    modifier onlyPermittedAddress() {
        if (msg.sender != Address1 && msg.sender != Address2) {
            revert OnlyPermittedAddress();
        }
        _;
    }

    /*-------- External Functions --------*/

    function setPermittedAddress(
        address _Address1,
        address _Address2
    ) public onlyOwner checkAddressZero(_Address1) checkAddressZero(_Address2) {
        Address1 = _Address1;
        Address2 = _Address2;

        emit PermittedAddressesUpdated(Address1, Address2);
    }

    function setReward(string calldata category, uint256 amount) external onlyOwner {
        rewards[category] = amount;
        rewardDetails[category][1] = amount;
    }

    // Mints 15mil tokens to the pre sale contract when the presale constructor is called
    function mintForInitialSupply() public onlyOwner {
        _mint(Address1, initialSupply);

        emit InitMinted(Address1, initialSupply);
    }

    function mint(
        address to,
        uint256 amount
    ) public onlyOwner validAmount(amount) checkAddressZero(to) {

        emit StarTokenMinted(to, amount);
        _exceedsMaxSupply(amount);
        _mint(to, amount);

        
    }

    function burn(uint256 amount) public validAmount(amount) {
        if (amount > balanceOf(msg.sender)) {
            revert ExceedsBalance();
        }
        _burn(msg.sender, amount);
    }

    /*-------- Internal Functions --------*/

    function _exceedsMaxSupply(uint256 amount) internal view {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }
    }
}
