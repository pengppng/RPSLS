// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPS is CommitReveal, TimeUnit {
    uint public numPlayer = 0;
    uint public reward = 0;
    
    mapping (address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - Lizard , 4 - Spock
    mapping(address => bool) public player_not_played;
    mapping(address => bytes32) public player_commit;

    address[] public players;
    uint public numInput = 0;
    uint public constant TIMEOUT = 5 minutes; // end session

    address[4] private allowedPlayers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    modifier onlyAllowedPlayers() {
        bool allowed = false;
        for (uint i = 0; i < allowedPlayers.length; i++) {
            if (msg.sender == allowedPlayers[i]) {
                allowed = true;
                break;
            }
        }
        require(allowed, "Not an allowed player");
        _;
    }

    function addPlayer(bytes32 commitHash) public payable onlyAllowedPlayers {
        require(numPlayer < 2);
        if (numPlayer > 0) {
            require(msg.sender != players[0], "cannot join twice");
        }
        require(msg.value == 1 ether, "Must send 1 coin for play");
        
        reward += msg.value;
        player_not_played[msg.sender] = true;
        player_commit[msg.sender] = commitHash;
        players.push(msg.sender);
        numPlayer++;

        if (numPlayer == 2) {
            startTime = block.timestamp; // start time
        }
    }

    function revealChoice(uint choice, bytes32 randomString) public {
        require(numPlayer == 2, "Not enough players");
        require(block.timestamp <= startTime + TIMEOUT, "Reveal period expired");
        require(choice <= 4, "Invalid choice");
        require(getHash(keccak256(abi.encodePacked(choice, randomString))) == player_commit[msg.sender], "Invalid reveal");
        
        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function input(uint choice, bytes32 randomString) public  {
        require(numPlayer == 2);
        require(player_not_played[msg.sender]);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4);
        require(getHash(keccak256(abi.encodePacked(choice, randomString))) == player_commit[msg.sender], "Invalid reveal");

        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        // more rule
        bool p0Wins = (
            (p0Choice == 0 && (p1Choice == 2 || p1Choice == 3)) || // Rock crushes Scissors & Lizard
            (p0Choice == 1 && (p1Choice == 0 || p1Choice == 4)) || // Paper covers Rock & disproves Spock
            (p0Choice == 2 && (p1Choice == 1 || p1Choice == 3)) || // Scissors cuts Paper & decapitates Lizard
            (p0Choice == 3 && (p1Choice == 1 || p1Choice == 4)) || // Lizard eats Paper & poisons Spock
            (p0Choice == 4 && (p1Choice == 0 || p1Choice == 2))    // Spock vaporizes Rock & smashes Scissors
        );

        bool p1Wins = (
            (p1Choice == 0 && (p0Choice == 2 || p0Choice == 3)) ||
            (p1Choice == 1 && (p0Choice == 0 || p0Choice == 4)) ||
            (p1Choice == 2 && (p0Choice == 1 || p0Choice == 3)) ||
            (p1Choice == 3 && (p0Choice == 1 || p0Choice == 4)) ||
            (p1Choice == 4 && (p0Choice == 0 || p0Choice == 2))
        );

        if (p0Wins) {
            account0.transfer(reward);
        } else if (p1Wins) {
            account1.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }

    function forceEndGame() public {
        require(block.timestamp > startTime + TIMEOUT, "Timeout not reached yet");
        require(numInput < 2, "Game already resolved");
        
        // คืนเงินให้ผู้เล่นที่เปิดเผยตัวเลือกแล้ว
        for (uint i = 0; i < players.length; i++) {
            if (!player_not_played[players[i]]) {
                payable(players[i]).transfer(reward / numPlayer);
            }
        }
    }
}
