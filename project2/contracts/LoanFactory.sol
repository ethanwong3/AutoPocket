/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Central manager to deploy loan contracts and keep track of them
/// @author Ethan Wong, Tony Wang

contract LoanFactory {

    // Variables

    // stores every loan created
    // map loans to creator and receiver

    // maps user to their trust score
    mapping(address => int256) public trustScores;


    // Functions

    // createLoan() deploys and records a LoanAgreement instance
    // getLoansByBorrower() gets user loan history
    // totalLoans() gets user loan total

}