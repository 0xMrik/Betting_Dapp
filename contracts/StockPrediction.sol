// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StockPrediction {

    address public owner; 

    uint256 public predictionStartTime;  // The start time of the prediction in Unix epoch seconds
    uint256 public predictionEndTime;  // The end time of the prediction in Unix epoch seconds
    uint public lastCheckedTime; // last time the contract checked the stock price

    int public currentPrice;  // The current price of the stock, allows for negative numbers

    bool public isBettingActive;  
    address[] public bettors; // store all bettors' addresses
    mapping(address => int) public bets; // keep track of each address's bet 
    mapping(address => uint256) public betAmounts; // keep track of the amount of Ether each address has bet
    address public lastWinner;

    struct Bet {
        address bettor;
        int amount;
    }

    struct BetInfo {
        address bettor;
        int amount;
        uint256 betAmount;
    } 

    constructor() {
        owner = msg.sender;
        predictionEndTime = block.timestamp + 5 minutes;
        isBettingActive = false;
    } 
    
    function getAllBets() public view returns (BetInfo[] memory) {
        BetInfo[] memory allBets = new BetInfo[](bettors.length); // Create new array in memory to store bets
        for(uint256 i = 0; i < bettors.length; i++) {  // Loop through each bettor
            allBets[i].bettor = bettors[i];  // Store bettor's address
            allBets[i].amount = bets[bettors[i]]; // Store bettor's predicted price
            allBets[i].betAmount = betAmounts[bettors[i]]; // Store how much Ether bettor wagered
        }
        return allBets; // After all bettors have been processed, return the array of BetInfo objects
    }

    function startPrediction(int _currentPrice) public {
        require(msg.sender == owner, 'Only the owner can start prediction'); // Check if the sender is the owner
        currentPrice = _currentPrice; // Set the current price to the input value
        predictionStartTime = block.timestamp; // Record the start time of the prediction
        predictionEndTime = block.timestamp + 5 minutes; // Set the prediction end time to be 5 minutes from now
        isBettingActive = true; // Activate betting
    }

    function enterBet(int _prediction) public payable {
        require(block.timestamp < predictionEndTime, 'Prediction has ended'); // Check if the prediction period is still ongoing
        require(msg.value >= 0.0001 ether, 'Minimum bet amount is 0.0001 ETH'); // Check if the bet is at least 0.0001 ETH
        bets[msg.sender] = _prediction; // Store the sender's prediction
        bettors.push(msg.sender); // Add the sender to the list of bettors
        betAmounts[msg.sender] = msg.value; // Record the amount of the sender's bet
    }
}