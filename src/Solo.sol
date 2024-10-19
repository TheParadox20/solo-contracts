// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Solobet
 * @dev P2P betting platform
 */
contract Solobet {
    uint8 commision = 5; // 5% of total funds
    address public admin;

    constructor() {
        admin = msg.sender;
    }
    struct Choice{
        uint amount;
        uint[] stakes;
        address payable [] stakers;
    }
    struct Bet{
        Choice home;
        Choice draw;
        Choice away;
    }
    mapping (string=>Bet) bets;
    mapping(string => mapping(address => bool)) private hasPlacedBet;
    //modifiers

    modifier onlyOwner {
        require(msg.sender == admin, "Only owner can interact with contract");
        _;
    }

    //events
    event BetPlaced(uint amount, address from);

    function placeBet(string memory betID,uint8 choice) public payable{
        /*
         * betID used to identify a bet
         * address to (home|draw|away)
         * amount to stake to 
        */
        require(msg.value>0,"Stake must be greater than 0");
        require(!hasPlacedBet[betID][msg.sender], "Address has already placed a bet on this game");
        Bet storage bet = bets[betID];
        if(choice==1){//home
            bet.home.amount+=msg.value;
            bet.home.stakes.push(msg.value);
            bet.home.stakers.push(payable(msg.sender));
        }
        if(choice==0){//draw
            bet.draw.amount+=msg.value;
            bet.draw.stakes.push(msg.value);
            bet.draw.stakers.push(payable(msg.sender));
        }
        if(choice==2){//away
            bet.away.amount+=msg.value;
            bet.away.stakes.push(msg.value);
            bet.away.stakers.push(payable(msg.sender));
        }
        bets[betID]=bet;
        hasPlacedBet[betID][msg.sender] = true; 
        
    }
    function closeBet(string memory betID, uint8 winner, uint winnings, uint winnersPot) public onlyOwner{
        /*
         * function used to distribute locked funds among winners
         * betID identifies bet
         * the winner address identifies which side (home|draw|away) gets the winnings
        */
        uint[] memory winnersStakes;
        address payable[] memory winnersAddress;
        if(winner==1){
            winnersStakes = bets[betID].home.stakes;
            winnersAddress = bets[betID].home.stakers;
        }
        if(winner==0){
            winnersStakes = bets[betID].draw.stakes;
            winnersAddress = bets[betID].draw.stakers;
        }
        if(winner==2){
            winnersStakes = bets[betID].away.stakes;
            winnersAddress = bets[betID].away.stakers;
        }
        for(uint8 i=0;i<winnersAddress.length;i++){//paying back
            (bool success, ) = winnersAddress[i].call{value : ((winnersStakes[i]/winnersPot)*winnings)+winnersStakes[i]}("");
            require(success, "Transfer failed.");
        }
        //delete the bet struct from list of bets
        delete bets[betID];
    }
    function getBetInfo(string memory betID) public view returns(Bet memory bet){
        bet = bets[betID];
    }

    // admin related funtions
    function fund(address payable to, uint amount) public onlyOwner{
        /**
         * Called automatically when fiat is deposited, converts fiat to crypto
         * @param to address to send funds to
         */
        require(amount>0,"Amount must be greater than 0");
        (bool success, ) = to.call{value : amount}("");
        require(success, "Transfer failed.");
    }
    function changeOwner(address newOwner) onlyOwner public {
        admin = newOwner;
    }
    function seed() payable onlyOwner public{}
    function getBalance() onlyOwner public view returns (uint) {
        return address(this).balance;
    }
    function getCommision() onlyOwner public view returns (uint8) {
        return  commision;
    }
    function setCommision(uint8 newCommision) onlyOwner public {
        commision = newCommision;
    }
    function withdraw(uint amount) onlyOwner public {
        require(amount>0,"Amount must be greater than 0");
        (bool success, ) = payable(msg.sender).call{value : amount}("");
        require(success, "Transfer failed.");
    }
}