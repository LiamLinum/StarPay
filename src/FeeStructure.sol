// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeStructure is Ownable {
    uint256 public swapFeePercentage;
    uint256 public sendFeePercentage;
    uint256 public receiveFeePercentage;

    event FeeUpdated(string feeType, uint256 newFeePercentage);

    constructor(uint256 _swapFee, uint256 _sendFee, uint256 _receiveFee) Ownable(msg.sender) {
        swapFeePercentage = _swapFee;
        sendFeePercentage = _sendFee;
        receiveFeePercentage = _receiveFee;
    }

    function setSwapFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 500, "Fee cannot exceed 5%");
        swapFeePercentage = _newFee;
        emit FeeUpdated("Swap", _newFee);
    }

    function setSendFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 500, "Fee cannot exceed 5%");
        sendFeePercentage = _newFee;
        emit FeeUpdated("Send", _newFee);
    }

    function setReceiveFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 500, "Fee cannot exceed 5%");
        receiveFeePercentage = _newFee;
        emit FeeUpdated("Receive", _newFee);
    }

    function calculateFee(uint256 _amount, uint256 _feePercentage) public pure returns (uint256) {
        return (_amount * _feePercentage) / 10000;
    }
}