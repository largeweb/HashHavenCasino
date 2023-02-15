// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HashHavenCasino is ERC20, Ownable {
    constructor() ERC20("HashHavenToken", "HHT") {}

    mapping(address => string) private address2user;
    mapping(string => address) private user2address;
    mapping(uint256 => address[]) private gameid2playerarr;
    mapping(uint256 => address) private gameid2winner;
    mapping(uint256 => bytes32) private gameid2hash;

    uint256[] private activeGames;

    uint256 private gameid = 0;
    uint256 private salt = 394857;
    uint256 private salt2 = 792997;

    uint256 private tokenPerEth = 100;

    function buyHHT(uint256 _amount) public payable returns(uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        require(msg.value >= _amount * 10000000000000000 / tokenPerEth, "Insufficient Amount Transferred");
        _mint(msg.sender, _amount);
        return _amount;
    }

    function sellHHT(uint256 _amount) public returns(uint256) {
        require(_amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= _amount, "Insufficient HHT Balance");
        uint256 amountReceived = _amount * 10000000000000000 / tokenPerEth; // Convert HHT to ETH
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(amountReceived);
        return _amount;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function changeSalt(uint256 _newsalt) public onlyOwner {
        salt=_newsalt;
    }

    function changeSalt2(uint256 _newsalt) public onlyOwner {
        salt2=_newsalt;
    }

    function setUsername(string memory _username) public {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require((user2address[_username] == msg.sender) || (user2address[_username] == address(0)), "Username taken by someone else or already set");
        user2address[address2user[msg.sender]] = address(0);
        address2user[msg.sender] = _username;
        user2address[_username] = msg.sender;
    }

    function viewAddress(string memory _username) view public returns(address) {
        return user2address[_username];
    }

    function viewUsername(address _address) view public returns(string memory) {
        return address2user[_address];
    }

    function createGame() public returns(uint256) {
        require(bytes(address2user[msg.sender]).length>0, "Player Must have Username");
        gameid+=1;
        activeGames.push(gameid);
        return gameid;
    }

    function joinGame(uint256 _gameid) public {
        require(_gameid<=gameid, "Game ID Doesn't Exist");
        require(_gameid>0, "Game ID Must be Greater Than 0");
        require(gameid2playerarr[_gameid].length < 6, "There are already 6/6 Players in the Game");
        require(bytes(address2user[msg.sender]).length>0, "Player Must have Username");
        for(uint i = 0; i < gameid2playerarr[_gameid].length; i++) {
            require(gameid2playerarr[_gameid][i] != msg.sender, "You have already joined the game");
        }
        gameid2playerarr[_gameid].push(msg.sender);
        uint256 gamelen = gameid2playerarr[_gameid].length;
        bytes memory encoded;
        if(gamelen==1) {
            encoded = abi.encode(msg.sender, block.timestamp, salt);
        } else {
            encoded = abi.encode(gameid2hash[_gameid], msg.sender, block.timestamp, salt);
        }
        gameid2hash[_gameid] = keccak256(encoded);
        salt+=1;
    }

    function gameOfRollDie(uint256 _gameid) public returns(address) {
        require(_gameid<=gameid, "Game ID Doesn't Exist");
        require(_gameid>0, "Game ID Must be Greater Than 0");
        require(gameid2playerarr[_gameid].length == 6, "Not enough players to start the game");
        require(gameid2winner[_gameid]==address(0), "Game has already been played and someone won");
        uint256 winnerIndex = uint(keccak256(abi.encodePacked(gameid2hash[_gameid], block.timestamp, salt2))) % 6;
        address winner = gameid2playerarr[_gameid][winnerIndex];
        gameid2winner[_gameid] = winner;
        bool found=false;
        for (uint256 i = 0; i<activeGames.length-1; i++){
            if(activeGames[i]==_gameid) found=true;
            if(found) activeGames[i]=activeGames[i+1];
        }
        activeGames.pop();
        return winner;
    }

    function viewGameWinnerAddress(uint256 _gameid) view public returns(address) {
        require(_gameid<=gameid, "Game ID Doesn't Exist");
        require(_gameid>0, "Game ID Must be Greater Than 0");
        return gameid2winner[_gameid];
    }

    function viewGameWinnerUsername(uint256 _gameid) view public returns(string memory) {
        require(_gameid<=gameid, "Game ID Doesn't Exist");
        require(_gameid>0, "Game ID Must be Greater Than 0");
        address winnerAddress = gameid2winner[_gameid];
        return address2user[winnerAddress];
    }

    function viewGameHash(uint256 _gameid) view public returns(bytes32) {
        require(_gameid<=gameid, "Game ID Doesn't Exist");
        require(_gameid>0, "Game ID Must be Greater Than 0");
        return gameid2hash[_gameid];
    }

    function viewGamePlayers(uint256 _gameid) view public returns(address[] memory) {
        require(_gameid<=gameid, "Game ID Doesn't Exist");
        require(_gameid>0, "Game ID Must be Greater Than 0");
        return gameid2playerarr[_gameid];
    }

    function viewGamePlayerUsernames(uint256 _gameid) view public returns(string[] memory) {
        require(_gameid<=gameid, "Game ID Doesn't Exist");
        require(_gameid>0, "Game ID Must be Greater Than 0");
        address[] memory players = gameid2playerarr[_gameid];
        string[] memory usernames = new string[](players.length);
        for(uint i = 0; i < players.length; i++) {
            usernames[i] = address2user[players[i]];
        }
        return usernames;
    }

    function viewActiveGames() view public returns(uint256[] memory) {
        return activeGames;
    }
}
