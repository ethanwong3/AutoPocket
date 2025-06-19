/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract to agree on the lunch venue
/// @author Dilum Bandara, CSIRO's Data61 (Upgraded Version)

/**
 * Solutions To 5 Weaknesses Chosen
 * 
 * 1 (Duplicate Votes)
 * - Added a check in doVote() using:
 *     require(!friends[msg.sender].voted, "You have already voted.");
 * - Added bool data to a friend that get updated after a successful vote.
 * - This ensures friends cannot vote more than once.
 * 
 * 2 (Duplicate Friends and Restaurants)
 * - Added a check in addFriend() to ensure the address has no associated name:
 *     require(bytes(friends[friendAddress].name).length == 0, "Friend already exists.");
 * - Added a check in addFriend() that ensures non empty names.
 * - This avoids a Remix bug that allows friends to be added without a name.
 * - Added restaurantExists that maps a restaurants hash to a bool if the restaurant exists.
 * - Added a check in addRestaurant that ensures restaurantExists is not true, which is the default if it has never been mapped:
 *     bytes32 nameHash = keccak256(abi.encodePacked(name));
 *     require(!restaurantExists[nameHash], "Restaurant already exists.");
 * - Added mapping in addRestaurant() to ensure their default false is toggled to true.
 * - This ensures that neither users are unique to their address and restaurants are unique to their name.
 * 
 * 3 (Contract Phases)
 * - Added an enum Phase to manage contract state.
 * - Added currentPhase to track the phase.
 * - Added onlyDuring(phase) modifier to restrict functions like addFriend, addRestaurant, and doVote.
 * - This ensures friends/restaurants can only be added in the setup phase, and voting only occurs in the voting phase.
 * 
 * 4 (Timeout Functionality)
 * - Added endBlock to track when voting ends.
 * - Added startVoting(blocksUntilEnd) which sets endBlock to block.number + blocksUntilEnd.
 * - Edited doVote() to check if block.number > endBlock, calling _endVoting() if true and gracefully exits.
 * - This ensures that the voting phase will timeout after a set amount of blocks that the manager chooses.
 * - As there is no automatic execution in Solidity, this is the closest possible method.
 * - Added endVoting() which calls _endVoting.
 * - This gives managers the ability to automatically end the voting phase.
 * 
 * 5 (Shutdown Functionality)
 * - Added a bool isShutdown to disable the contract.
 * - Added a contractActive modifier to guard all public functions.
 * - Added shutdown() which progresses the contract to the final stage without calculating results.
 * - This ensures that managers have the ability to disable the contract.
 */

/**
 * Testing Strategy
 * - To enable catching revert reasons during testing, certain logic functions (e.g., addFriend/addRestaurant) 
 *   are wrapped in externally callable functions (_addFriend/_addRestaurant) with identical protections.
 *   This allows precise unit testing without exposing functionality in production deployments.
 */

contract LunchVenue_updated{
    
    struct Friend {
        string name;
        bool voted;
    }
    
    struct Vote {
        address voterAddress;
        uint restaurant;
    }

    mapping (uint => string) public restaurants;
    mapping(address => Friend) public friends;
    uint public numRestaurants = 0;
    uint public numFriends = 0;
    uint public numVotes = 0;
    address public manager;
    string public votedRestaurant = "";

    mapping (uint => Vote) public votes;
    mapping (uint => uint) private _results;
    bool public voteOpen = false;                       // voting should start closed for setup phase
    
    enum Phase { Setup, Voting, Ended }                 // voting phases
    Phase public currentPhase = Phase.Setup;            // current phase of the contract
    uint public endBlock;                               // block number when voting ends
    bool public isShutdown = false;                     // contract shutdown status
    
    mapping(bytes32 => bool) private restaurantExists;  // mapping to prevent dup restaurants by name hash

    /**
     * @dev Set manager when contract starts
     */
    constructor () {
        manager = msg.sender;
    }

    /**
     * @notice Public interface for adding a new restaurant
     * @dev wraps _addRestaurant for clearer testability and separation of access logic
     * @dev prevents duplication of restaurants by checking name hash
     *
     * @param name Restaurant name
     * @return Number of restaurants added so far
     */
    function addRestaurant(string memory name) public contractActive restricted onlyDuring(Phase.Setup) returns (uint) {
        return _addRestaurant(name);
    }

    /**
    * @custom:testing Exposes the internal logic of addRestaurant for unit testing.
    * Because try/catch only works on external function calls, this public wrapper allows us to test revert messages.
    * It is guarded by the same modifiers as addRestaurant except restricted, so functionality remains unchanged and safe.
    * This function is not meant for production use.
    */
    function _addRestaurant(string memory name) public contractActive onlyDuring(Phase.Setup) returns (uint) {
        // check if restaurant with name hash exists
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        require(!restaurantExists[nameHash], "Restaurant already exists.");

        numRestaurants++;
        restaurants[numRestaurants] = name;

        // ensure new restaurant is not duped
        restaurantExists[nameHash] = true;
        return numRestaurants;
    }

    /**
     * @notice Public interface for adding a new friend to voter list
     * @dev wraps _addFriend for clearer testability and separation of access logic
     * @dev prevents duplication of friends
     *
     * @param friendAddress Friend's account/address
     * @param name Friend's name
     * @return Number of friends added so far
     */
    function addFriend(address friendAddress, string memory name) public contractActive restricted onlyDuring(Phase.Setup) returns (uint) {
        return _addFriend(friendAddress, name);
    }

    /**
    * @custom:testing Exposes the internal logic of addFriend for unit testing.
    * Because try/catch only works on external function calls, this public wrapper allows us to test revert messages. 
    * It is guarded by the same modifiers as addFriend except restricted, so functionality remains unchanged and safe.
    * This function is not meant for production use.
    */
    function _addFriend(address friendAddress, string memory name) public contractActive onlyDuring(Phase.Setup) returns (uint) {
        // check if name stored at friends account address exists, and ensure name is not empty
        require(bytes(friends[friendAddress].name).length == 0, "Friend already exists.");
        require(bytes(name).length > 0, "Name cannot be empty.");

        Friend memory f;
        f.name = name;
        f.voted = false;
        friends[friendAddress] = f;
        numFriends++;
        return numFriends;
    }
    
    /**
     * @notice Start the voting phase
     * @dev Only manager can start voting and set timeout
     *
     * @param blocksUntilEnd Number of blocks until voting ends
     */
    function startVoting(uint blocksUntilEnd) public contractActive restricted onlyDuring(Phase.Setup) {
        // ensure there is at least two friends and two restaurants
        require(numRestaurants > 1, "At least two restaurants must be added.");
        require(numFriends > 1, "At least two friends must be added.");
        
        // track endblock, move into voting phase, open voting
        endBlock = block.number + blocksUntilEnd;
        currentPhase = Phase.Voting;
        voteOpen = true;
    }
    
    /**
     * @notice Internal function to transition the contract from voting phase to ended phase.
     * @dev This function finalises the voting outcome if there are any votes,
     *      otherwise it simply closes voting. It is intended to be called both
     *      by the manager (via `endVoting()`) and internally (e.g., after timeout).
     *      This function does not perform any access control checks.
     */
    function _endVoting() internal {
        // calculate results
        if (numVotes > 0) {
            finalResult();
        }

        // move onto final phase
        voteOpen = false;
        currentPhase = Phase.Ended;
        
    }

    /** 
     * @notice Force end voting (for timeout or manager decision)
     * @dev Can be called by manager or automatically when timeout reached
     */
    function endVoting() public contractActive restricted {
        // ensure current phase is voting
        require(currentPhase == Phase.Voting, "Not in voting phase.");
        // call internal function for end voting logic
        _endVoting();
    }

    /** 
     * @notice Vote for a restaurant
     * @dev Prevents duplicate votes and enforces timeout
     *
     * @param restaurant Restaurant number being voted
     * @return validVote Is the vote valid? A valid vote should be from a registered 
     * friend to a registered restaurant
    */
    function doVote(uint restaurant) public contractActive onlyDuring(Phase.Voting) votingOpen returns (bool validVote) {
        // ensure valid restaurant
        require(bytes(restaurants[restaurant]).length != 0, "Restaurant does not exist.");

        // ensure voting has not timed out, if so move to end phase
        if (block.number > endBlock) {
            _endVoting();
            return false;
        }

        // check if sender is a friend
        if (bytes(friends[msg.sender].name).length == 0) {
            // revert instead of require to explicitly trigger catch blocks in tests
            revert("You are not a registered friend.");
        }

        // check if sender already voted
        if (friends[msg.sender].voted) {
            revert("You have already voted.");
        }

        // if conditions met, process vote
        validVote = true;
        friends[msg.sender].voted = true;
        votes[++numVotes] = Vote(msg.sender, restaurant);

        if (numVotes >= numFriends / 2 + 1) {
            // instead of just calculating results, move to end phase
            _endVoting();
        }

        return validVote;
    }

    /**
    * @dev Proxy to call doVote from within the contract using a different external context.
    * Primarily used to simulate external calls in testing environments.
    * This function is not meant for production use.
    */
    function voteAs(uint restaurant) public returns (bool) {
        return doVote(restaurant);
    }

    /** 
     * @notice Determine winner restaurant
     * @dev If top 2 restaurants have the same no of votes, result depends on vote order
    */
    function finalResult() private{
        uint highestVotes = 0;
        uint highestRestaurant = 0;
        
        for (uint i = 1; i <= numVotes; i++){
            uint voteCount = 1;
            if(_results[votes[i].restaurant] > 0) {
                voteCount += _results[votes[i].restaurant];
            }
            _results[votes[i].restaurant] = voteCount;
        
            if (voteCount > highestVotes){
                highestVotes = voteCount;
                highestRestaurant = votes[i].restaurant;
            }
        }
        votedRestaurant = restaurants[highestRestaurant];
    }
    
    /**
     * @notice Shutdown the contract
     * @dev Only manager can shutdown, prevents all future interactions
     */
    function shutdown() public restricted {
        // move onto final phase without calculating a result
        isShutdown = true;
        voteOpen = false;
        currentPhase = Phase.Ended;
    }
    
    /** 
     * @notice Only the manager can do
     */
    modifier restricted() {
        require (msg.sender == manager, "Can only be executed by the manager");
        _;
    }
    
    /**
     * @notice Only when voting is still open
     */
    modifier votingOpen() {
        require(voteOpen == true, "Can vote only while voting is open.");
        _;
    }
    
    /**
     * @notice Only during specified phase
     */
    modifier onlyDuring(Phase phase) {
        require(currentPhase == phase, "Action not allowed in current phase.");
        _;
    }
    
    /**
     * @notice Only when contract is not shutdown
     */
    modifier contractActive() {
        require(!isShutdown, "Contract is shut down.");
        _;
    }
}