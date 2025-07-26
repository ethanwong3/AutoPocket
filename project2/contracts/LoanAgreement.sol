/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Enforces loan terms such as repayment logic, timestamps, status, and trust interactions
/// @author Ethan Wong, Tony Wang

contract LoanAgreement {

    // Storage //////////////////////////////////////////////////////////////

    // loan status
    enum LoanStatus { Active, Repaid, Defaulted }

    // loan vars
    address public lender;
    address public borrower;
    uint256 public principal;
    uint256 public interestPercent;
    uint256 public dueTimestamp;
    address public tokenAddress;
    address public factory;

    // contract state vars
    uint256 public repaidAmount;
    bool public markedDefault;

    // events
    event Repaid(address indexed payer, uint256 amount, uint256 totalRepaid);
    event FullyRepaid(address indexed loan);
    event DefaultMarked(address indexed loan, address indexed lender);

    // Functions ///////////////////////////////////////////////////////////////////////

    /// @notice                 constructor for loan agreement
    /// @param _lender          lender address
    /// @param _borrower        borrower address
    /// @param _amount          principal loan
    /// @param _token           ERC-20 token address
    /// @param _duration        loan second duration
    /// @param _interestPercent interest rate
    /// @param _factory         factory contract address
    constructor(
        address _lender,
        address _borrower,
        uint256 _amount,
        address _token,
        uint256 _duration,
        uint256 _interestPercent,
        address _factory
    ) {
        lender = _lender;
        borrower = _borrower;
        principal = _amount;
        tokenAddress = _token;
        dueTimestamp = block.timestamp + _duration;
        interestPercent = _interestPercent;
        factory = _factory;
    }

    /// @notice         called by borrower to repay loan
    /// @dev            maybe make this check for over payment???
    /// @param amount   amount to be repaid
    function repay(uint256 amount) external {
        // ensure user authorised
        require(msg.sender == borrower, "Only borrower can repay");

        // ensure token transfer success
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, lender, amount), "Token transfer failed");

        // update contract state and emit event
        repaidAmount += amount;
        emit Repaid(msg.sender, amount, repaidAmount);

        // check if loan fully paid
        if (getStatus() == LoanStatus.Repaid) {
            // emit event and update borrower trust score
            emit FullyRepaid(address(this));
            _updateTrustScore(1);
        }
    }

    /// @notice mark a loan as defaulted (by lender) after due date
    function markDefault() external {
        // ensure user is authorised and loan is valid and overdue
        require(msg.sender == lender, "Only lender can mark default");
        require(getStatus() == LoanStatus.Active, "Loan not active or already handled");
        require(block.timestamp > dueTimestamp, "Loan is not overdue yet");

        // update contract state and emit event
        markedDefault = true;
        emit DefaultMarked(address(this), lender);

        // update borrower trust score
        _updateTrustScore(-2);
    }

    /// @notice         get loan status
    /// @return status  current loan status
    function getStatus() public view returns (LoanStatus) {
        // defaulted check
        if (markedDefault) {
            return LoanStatus.Defaulted;
        }

        // repaid check
        uint256 totalOwed = principal + (principal * interestPercent) / 100;
        if (repaidAmount >= totalOwed) {
            return LoanStatus.Repaid;
        }

        // otherwise active
        return LoanStatus.Active;
    }

    /// @dev        internal helper to update trust score via the factory
    /// @param x    score change amount
    function _updateTrustScore(int256 x) internal {
        (bool success, ) = factory.call(
            abi.encodeWithSignature("updateTrustScore(address,int256)", borrower, x)
        );
        require(success, "Trust score update failed");
    }

    function getTotalOwed() public view returns (uint256) {
        return principal + (principal * interestPercent) / 100;
    }

    function getDueTimestamp() public view returns (uint256) {
        return dueTimestamp;
    }

    function getRepaidAmount() public view returns (uint256) {
        return repaidAmount;
    }
}