/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./LoanAgreement.sol";

/// @title Central manager to deploy loan contracts and keep track of them
/// @author Ethan Wong, Tony Wang

contract LoanFactory {

    // Storage ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    address[] public loans;                                                                     // deployed loan tracker
    mapping(address => bool) public isValidLoan;                                                // map loan to validity
    mapping(address => address[]) public loansByBorrower;                                       // map borrower to their loans
    mapping(address => address[]) public loansByLender;                                         // map lender to their loans
    mapping(address => int256) public trustScores;                                              // map user to their trust score
    event LoanCreated(address indexed borrower, address indexed lender, address loanAddress);   // event emitted whenever loan created

    // Loan Agreement Functions //////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice                 deploys and records a new LoanAgreement contract
    /// @param _borrower        address of borrower
    /// @param _amount          token value of loan
    /// @param _token           address of erc-20 toke
    /// @param _duration        second duration od loan
    /// @param _interestPercent interest percentage
    /// @return loanAddress     address of deployed contract
    function createLoan(        
        address _borrower,
        uint256 _amount,
        address _token,
        uint256 _duration,
        uint256 _interestPercent
    ) external returns (address loanAddress) {

        // create new instance
        LoanAgreement loan = new LoanAgreement(
            msg.sender,
            _borrower,
            _amount,
            _token,
            _duration,
            _interestPercent,
            address(this)
        );

        // validate loan and append to tracking vars
        loanAddress = address(loan);
        loans.push(loanAddress);
        loansByBorrower[_borrower].push(loanAddress);
        loansByLender[msg.sender].push(loanAddress);
        isValidLoan[loanAddress] = true;

        // emit event for frontend to listen for
        emit LoanCreated(_borrower, msg.sender, loanAddress);
    }

    function getLoanCount() external view returns (uint256) {
        return loans.length;
    }

    function getBorrowerLoanCount(address user) external view returns (uint256) {
        return loansByBorrower[user].length;
    }

    function getLenderLoanCount(address user) external view returns (uint256) {
        return loansByLender[user].length;
    }

    function getBorrowerLoans(address user) external view returns (address[] memory) {
        return loansByBorrower[user];
    }

    function getLenderLoans(address user) external view returns (address[] memory) {
        return loansByLender[user];
    }

    // Trust Score Functions /////////////////////////////////////////////////////////////////////

    /// @notice             update a borrower's trust score
    /// @dev                this function can only be called by registered loanAgreement contracts
    /// @param _borrower    address of borrow
    /// @param _val         value to be added to trust score (can be negative)
    function updateTrustScore(address _borrower, int256 _val) external {
        require(isValidLoan[msg.sender], "Only a registered loan can call this function!");
        trustScores[_borrower] += _val;
    }

    /// @notice Get a borrower's trust score
    function getTrustScore(address _user) external view returns (int256) {
        return trustScores[_user];
    }

}