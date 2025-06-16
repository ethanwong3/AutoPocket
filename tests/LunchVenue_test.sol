// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.8.00 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/LunchVenue.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
/// Inherit 'LunchVenue' contract
contract LunchVenueTest is LunchVenue {
    
    // Variables used to emulate different accounts  
    address acc0;   
    address acc1;
    address acc2;
    address acc3;
    address acc4;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // Initiate account variables
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    /// Check manager
    /// account-0 is the default account that deploy contract, so it should be the manager (i.e., acc0)
    function managerTest() public {
        Assert.equal(manager, acc0, 'Manager should be acc0');
    }
    
    /// Check initial phase is Setup
    function initialPhaseTest() public {
        Assert.equal(uint(currentPhase), uint(LunchVenue.Phase.Setup), 'Initial phase should be Setup');
    }
    
    /// Add restaurant as manager
    /// When msg.sender isn't specified, default account (i.e., account-0) is the sender
    function setRestaurant() public {
        Assert.equal(addRestaurant('Courtyard Cafe'), 1, 'Should be equal to 1');
        Assert.equal(addRestaurant('Uni Cafe'), 2, 'Should be equal to 2');
    }
    
    /// Try to add duplicate restaurant. This should fail
    function setDuplicateRestaurantFailure() public {
        try this.addRestaurant('Courtyard Cafe') returns (uint v){
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Restaurant already exists.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Try to add a restaurant as a user other than manager. This should fail
    /// #sender: account-1
    function setRestaurantFailure() public {
        try this.addRestaurant('Atomic Cafe') returns (uint v){
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Set friends as account-0
    function setFriend() public {
       Assert.equal(addFriend(acc0, 'Alice'), 1, 'Should be equal to 1');
       Assert.equal(addFriend(acc1, 'Bob'), 2, 'Should be equal to 2');
       Assert.equal(addFriend(acc2, 'Charlie'), 3, 'Should be equal to 3');
       Assert.equal(addFriend(acc3, 'Eve'), 4, 'Should be equal to 4');
    }
    
    /// Try to add duplicate friend. This should fail
    function setDuplicateFriendFailure() public {
        try this.addFriend(acc0, 'Alice2') returns (uint f) {
            Assert.notEqual(f, 5, 'Method execution did not fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Friend already exists.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Try adding friend as a user other than manager. This should fail
    function setFriendFailure() public {
        try this.addFriend(acc4, 'Daniels') returns (uint f) {
            Assert.notEqual(f, 5, 'Method execution did not fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Can only be executed by the manager', 'Failed with unexpected reason');
        } catch Panic( uint /* errorCode */) {
            Assert.ok(false , 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Try voting before voting phase starts. This should fail
    /// #sender: account-1
    function voteBeforeVotingPhaseFailure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.equal(validVote, false, 'Vote should not be valid');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Action not allowed in current phase.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Start voting phase
    function startVotingPhase() public {
        startVoting(1000); // Set voting to end in 1000 blocks
        Assert.equal(uint(currentPhase), uint(LunchVenue.Phase.Voting), 'Phase should be Voting');
        Assert.equal(voteOpen, true, 'Voting should be open');
    }
    
    /// Try to add restaurant during voting phase. This should fail
    function addRestaurantDuringVotingFailure() public {
        try this.addRestaurant('New Cafe') returns (uint v) {
            Assert.notEqual(v, 3, 'Method execution did not fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Action not allowed in current phase.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
    
    /// Vote as Bob (acc1)
    /// #sender: account-1
    function vote() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    /// Try voting twice from same account. This should fail
    /// We need to test this from account-0 (Alice) who is a registered friend
    function voteTwiceFailure() public {
        // First vote as Alice (account-0/manager)
        Assert.ok(doVote(1), "First vote should succeed");
        
        // Try to vote again as Alice - this should fail
        try this.doVote(2) returns (bool validVote) {
            Assert.equal(validVote, false, 'Second vote should not be valid');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'You have already voted.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }

    /// Vote as Charlie
    /// #sender: account-2
    function vote2() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    /// Vote as Eve to reach quorum (3 out of 4 votes)
    /// #sender: account-3
    function vote3() public {
        Assert.ok(doVote(2), "Voting result should be true");
    }

    /// Verify lunch venue is set correctly
    function lunchVenueTest() public {
        Assert.equal(votedRestaurant, 'Uni Cafe', 'Selected restaurant should be Uni Cafe');
    }
    
    /// Try voting as a user not in the friends list. This should fail
    /// #sender: account-4
    function voteFailure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.equal(validVote, false, 'Vote should not be valid');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'You are not a registered friend.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }

    /// Verify voting is now closed
    function voteOpenTest() public {
        Assert.equal(voteOpen, false, 'Voting should be closed');
    }
    
    /// Verify phase is now Ended
    function phaseEndedTest() public {
        Assert.equal(uint(currentPhase), uint(LunchVenue.Phase.Ended), 'Phase should be Ended');
    }
    
    /// Verify voting after vote closed. This should fail
    function voteAfterClosedFailure() public {
        try this.doVote(1) returns (bool validVote) {
            Assert.equal(validVote, true, 'Method execution did not fail');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Action not allowed in current phase.', 'Failed with unexpected reason');
        } catch Panic( uint /* errorCode */) {
            Assert.ok(false , 'Failed unexpected with error code');        
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpectedly');
        }
    }

    /// Test voting with invalid restaurant number
    /// #sender: account-1
    function voteInvalidRestaurantFailure() public {
        // First start voting phase
        startVoting(1000);
        
        // Try voting for non-existent restaurant (ID 999)
        try this.doVote(999) returns (bool validVote) {
            Assert.equal(validVote, false, 'Vote should not be valid for non-existent restaurant');
        } catch Error(string memory reason) {
            Assert.equal(reason, 'Restaurant does not exist.', 'Failed with unexpected reason');
        } catch Panic(uint /* errorCode */) {
            Assert.ok(false, 'Failed unexpected with error code');
        } catch (bytes memory /*lowLevelData*/) {
            Assert.ok(false, 'Failed unexpected');
        }
    }
}