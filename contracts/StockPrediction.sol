// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StockPrediction {
    address public owner;

    uint256 public predictionStartTime; // The start time of the prediction
    uint256 public predictionEndTime; // The end time of the prediction
    uint public lastCheckedTime; // last time the contract checked the stock price

    int public currentPrice; // allows for negative numbers

    bool public isBettingActive;
    address[] public bettors; // store all bettors' addresses
    mapping(address => int) public bets; // keep track of each address's bet
    mapping(address => uint256) public betAmounts; // keep track of the amount of Ether each address has bet
    address public lastWinner;

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
        for (uint256 i = 0; i < bettors.length; i++) {
            // Loop through each bettor
            allBets[i].bettor = bettors[i]; // Store bettor's address
            allBets[i].amount = bets[bettors[i]]; // Store bettor's predicted price
            allBets[i].betAmount = betAmounts[bettors[i]]; // Store how much Ether bettor wagered
        }
        return allBets; // After all bettors have been processed, return the array of BetInfo objects
    }

    function startPrediction(int _currentPrice) public {
        require(msg.sender == owner, "Only the owner can start prediction"); // Check if the sender is the owner
        currentPrice = _currentPrice; // Set the current price to the input value
        predictionStartTime = block.timestamp; // Record the start time of the prediction
        predictionEndTime = block.timestamp + 5 minutes; // Set the prediction end time to be 5 minutes from now
        isBettingActive = true; // Activate betting
    }

    function enterBet(int _prediction) public payable {
        require(block.timestamp < predictionEndTime, "Prediction has ended"); // Check if the prediction period is still ongoing
        require(msg.value >= 0.0001 ether, "Minimum bet amount is 0.0001 ETH"); // Check if the bet is at least 0.0001 ETH
        bets[msg.sender] = _prediction; // Store the sender's prediction
        bettors.push(msg.sender); // Add the sender to the list of bettors
        betAmounts[msg.sender] = msg.value; // Record the amount of the sender's bet
    }

    function finalizePrediction(int _currentPrice) public {
        require(
            block.timestamp >= predictionEndTime,
            "Prediction has not ended"
        );
        require(isBettingActive, "Prediction is not active");
        currentPrice = _currentPrice;

        int closestPrediction = bets[bettors[0]];
        uint closestDistance = abs(currentPrice, closestPrediction);
        address payable winner = payable(bettors[0]);

        for (uint i = 1; i < bettors.length; i++) {
            int prediction = bets[bettors[i]];
            uint distance = abs(currentPrice, prediction);

            if (distance < closestDistance) {
                closestPrediction = prediction;
                closestDistance = distance;
                winner = payable(bettors[i]);
            }
        }

        uint pool = address(this).balance;
        require(pool > 0, "Pool is empty");
        require(winner != address(0), "No winner found");
        winner.transfer(pool);
        lastWinner = winner;

        predictionStartTime = 0;
        predictionEndTime = 0;
        isBettingActive = false;

        for (uint i = 0; i < bettors.length; i++) {
            bets[bettors[i]] = 0;
        }
        bettors = new address[](0);
    }

    function resetLastWinner() public {
        require(msg.sender == owner, "Only owner can reset last winner");
        lastWinner = address(0);
    }

    function isPredictionOver() public view returns (bool) {
        if (block.timestamp >= predictionEndTime) {
            return true;
        }
        return false;
    }

    function getPoolAmount() public view returns (uint) {
        return address(this).balance;
    }

    function abs(int x, int y) internal pure returns (uint) {
        return x >= y ? uint(x - y) : uint(y - x);
    }
}


