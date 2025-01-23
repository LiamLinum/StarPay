// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./StarToken.sol";

contract StarDApp is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    StarToken public starToken;
    IUniswapV2Router02 public uniswapRouter;

    struct User {
        bool isRegistered;
        string username;
        address generatedWallet; 
    }

    mapping(address => User) public users;
    mapping(address => address) public walletToUser;
    uint256 public nonce;

    event UserRegistered(address indexed user, string username, address generatedWallet);
    event TokensSent(address indexed from, address indexed to, uint256 amount);
    event TokensSwapped(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _starToken, address _uniswapRouter) Ownable(msg.sender) {
        starToken = StarToken(_starToken);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function registerUser(string memory username) public {
        require(!users[msg.sender].isRegistered, "User already registered");
        
        address generatedWallet = generateWallet(msg.sender);
        users[msg.sender] = User(true, username, generatedWallet);
        walletToUser[generatedWallet] = msg.sender;

        emit UserRegistered(msg.sender, username, generatedWallet);
    }

    function generateWallet(address userAddress) internal returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(
            userAddress,
            nonce,
            block.timestamp % 900
        ));
        nonce++;
        return address(uint160(uint256(hash)));
    }


    function getUserWallet(address user) public view returns (address) {
        require(users[user].isRegistered, "User not registered");
        return users[user].generatedWallet;
    }

    function sendTokens(address to, uint256 amount) public nonReentrant {
        require(users[msg.sender].isRegistered, "User not registered");
        address fromWallet = users[msg.sender].generatedWallet;
        require(starToken.transferFrom(fromWallet, to, amount), "Transfer failed");
        emit TokensSent(fromWallet, to, amount);
    }

    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) public nonReentrant {
        require(users[msg.sender].isRegistered, "User not registered");
        address userWallet = users[msg.sender].generatedWallet;

        require(IERC20(tokenIn).transferFrom(userWallet, address(this), amountIn), "Transfer failed");
        require(IERC20(tokenIn).approve(address(uniswapRouter), amountIn), "Approval failed");

    
        uint256 tokenFee = (amountIn / 100) * 5;
        uint256 amountAfterFee = amountIn - tokenFee;

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountAfterFee,
            amountOutMin,
            path,
            userWallet,
            block.timestamp + 15 minutes
        );

        emit TokensSwapped(msg.sender, tokenIn, tokenOut, amountIn, amounts[1]);
    }


    function depositStarTokens(uint256 amount) public nonReentrant {
        require(users[msg.sender].isRegistered, "User not registered");
        address userWallet = users[msg.sender].generatedWallet;
        require(starToken.transferFrom(msg.sender, userWallet, amount), "Transfer failed");
    }

    function withdrawStarTokens(uint256 amount) public nonReentrant {
        require(users[msg.sender].isRegistered, "User not registered");
        address userWallet = users[msg.sender].generatedWallet;
        require(starToken.transferFrom(userWallet, msg.sender, amount), "Transfer failed");
    }
}