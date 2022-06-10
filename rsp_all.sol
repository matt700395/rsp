//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    
    
    
    constructor () payable {}
   
    enum Hand {
        rock, paper, scissors
    }
    
    enum PlayerStatus{
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }
    
    enum GameStatus {  
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }
    
    // player structure
    struct Player {
        bytes32 _Hashed_hand;
        address payable addr;
        PlayerStatus playerStatus;
        uint256 playerBetAmount;
    }
    
    struct Game {
        uint256 betAmount;
        GameStatus gameStatus;
        Player originator;
        Player taker;
    }
    
    
    mapping(uint => Game) rooms;
    uint roomLen = 0;
    /*
    modifier isValidHand (bytes32 _Hashed_hand, address _owner) {
        require((_Hashed_hand  == Hashed_hand(_Hashed_hand, _owner)) || (_Hashed_hand  == Hand.paper) || (_Hashed_hand == Hand.scissors));
        _;
    }
    */
    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }
    
    function Hashed_hand(uint256 _hand, address _owner) public pure returns (bytes32){
        require(_hand == 0 || _hand == 1 || _hand == 2);
        return keccak256(abi.encodePacked(_hand, _owner));
    }

    function decodedHand(bytes32 _Hashed_hand, address playerAddress)private pure returns (uint8 _decodedHand){
        if (_Hashed_hand == Hashed_hand(0, playerAddress)) {
            _decodedHand = 0;
        } else if (_Hashed_hand == Hashed_hand(1, playerAddress)) {
            _decodedHand = 1;
        } else if (_Hashed_hand == Hashed_hand(2, playerAddress)) {
            _decodedHand = 2;
        }
        return _decodedHand;
    }
    
    function createRoom (bytes32 _Hashed_hand) public payable returns (uint roomNum) {
        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                _Hashed_hand: _Hashed_hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({ // will change
                _Hashed_hand: _Hashed_hand,
                addr: payable(msg.sender),  
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen;
        roomLen = roomLen+1;
        
        return roomNum;
    }
    
    function joinRoom(uint roomNum, bytes32 _Hashed_hand) public payable{
        
        rooms[roomNum].taker = Player({
            _Hashed_hand: _Hashed_hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        compareHands(roomNum);
    }
    
    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
         rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
    
    function compareHands(uint roomNum) private{ 
        uint8 originator = decodedHand(rooms[roomNum].originator._Hashed_hand, rooms[roomNum].originator.addr);
        uint8 taker = decodedHand(rooms[roomNum].taker._Hashed_hand, rooms[roomNum].taker.addr);
        
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        
        
        if (taker == originator){ //draw
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
            
        }
        else if ((taker +1) % 3 == originator) { // originator wins
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if ((originator + 1)%3 == taker){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }

       
    }
}