/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Enforces loan terms such as repayment logic, timestamps, status, and trust interactions
/// @author Ethan Wong, Tony Wang

contract LoanAgreement {


    constructor (address l, address b, uint256 a, address t, uint256 d, uint256 i, address f) {
    }

    // Variables

    // lender and borrower (parties involved in loan)
    // principal, interestRate, repaymentAmount (financial terms of loan)
    // startDate, dueDate (control time window)
    // isRepaid, isDefaulted (track loan status)
    // tokenAddress (erc-20 interactions)

    // things need to add with status filter
    // .getStatus()
    // .LoanStatus

    // Functions

    // constructor() sets vars at creation
    // repay() transfers tokens back to the lender if repayment conditions are met
    // checkDefault() anyone can mark the loan as defaulted after the deadline
    // getLoanStatus() get loan status, either active, repaid, or defaulted
    // updateTrustScore(success) ??? might have to move trust score mapping to factory ??? add factory reference in agreement, use this function to update score in facotry 

}