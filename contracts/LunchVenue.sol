// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Contract to agree on the lunch venue
/// @author Dilum Bandara, CSIRO’s Data61

contract LunchVenue {

    struct Friend {
        string name;
        bool voted;
    }

    struct Vote {
        address voterAddress;
        uint restaurant;
    }

    mapping(uint => string) public restaurants; // restaurant number => name
    mapping(address => Friend) public friends;  // address => Friend
    mapping(uint => Vote) public votes;         // vote number => Vote
    mapping(uint => uint) private _results;     // restaurant number => number of votes

    uint public numRestaurants = 0;
    uint public numFriends = 0;
    uint public numVotes = 0;

    address public manager;
    string public votedRestaurant = "";
    bool public voteOpen = true;

    /// @dev Set manager when contract starts
    constructor() {
        manager = msg.sender;
    }

    /// @notice Add a new restaurant
    /// @dev To simplify, duplicate check is not done
    /// @param name Restaurant name
    /// @return Number of restaurants added so far
    function addRestaurant(string memory name) public restricted returns (uint) {
        numRestaurants++;
        restaurants[numRestaurants] = name;
        return numRestaurants;
    }

    /// @notice Add a new friend to voter list
    /// @dev Duplicate check is not done
    /// @param friendAddress Friend’s Ethereum address
    /// @param name Friend’s name
    /// @return Number of friends added so far
    function addFriend(address friendAddress, string memory name) public restricted returns (uint) {
        Friend memory f;
        f.name = name;
        f.voted = false;
        friends[friendAddress] = f;
        numFriends++;
        return numFriends;
    }

    /// @notice Vote for a restaurant
    /// @dev Duplicate vote not checked
    /// @param restaurant Restaurant number
    /// @return validVote Whether vote is valid
    function doVote(uint restaurant) public votingOpen returns (bool validVote) {
        validVote = false;
        if (bytes(friends[msg.sender].name).length != 0) { // Is friend valid?
            if (bytes(restaurants[restaurant]).length != 0) { // Is restaurant valid?
                validVote = true;
                friends[msg.sender].voted = true;
                Vote memory v;
                v.voterAddress = msg.sender;
                v.restaurant = restaurant;
                numVotes++;
                votes[numVotes] = v;
            }
        }

        if (numVotes >= numFriends / 2 + 1) {
            finalResult();
        }

        return validVote;
    }

    /// @notice Determine winner restaurant
    /// @dev If tie, winner depends on vote order
    function finalResult() private {
        uint highestVotes = 0;
        uint highestRestaurant = 0;

        for (uint i = 1; i <= numVotes; i++) {
            uint voteCount = 1;
            if (_results[votes[i].restaurant] > 0) {
                voteCount += _results[votes[i].restaurant];
            }
            _results[votes[i].restaurant] = voteCount;

            if (voteCount > highestVotes) {
                highestVotes = voteCount;
                highestRestaurant = votes[i].restaurant;
            }
        }

        votedRestaurant = restaurants[highestRestaurant];
        voteOpen = false;
    }

    /// @notice Only the manager can call
    modifier restricted() {
        require(msg.sender == manager, "Can only be executed by the manager");
        _;
    }

    /// @notice Only when voting is still open
    modifier votingOpen() {
        require(voteOpen == true, "Can vote only while voting is open.");
        _;
    }
}
