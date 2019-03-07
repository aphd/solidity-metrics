pragma solidity ^0.4.25;

contract CoinFlip {
    address owner;
    uint payPercentage = 90;
	
	// Maximum amount to bet in WEIs
	uint public MaxAmountToBet = 200000000000000000; // = 0.2 Ether
	

	
	struct Game {
		address addr;
		uint blocknumber;
		uint blocktimestamp;
        uint bet;
		uint prize;
        bool winner;
    }
	
	Game[] lastPlayedGames;
	
	Game newGame;
    
    event Status(
		string _msg, 
		address user, 
		uint amount,
		bool winner
	);
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert();
        } else {
            _;
        }
    }
    
    function Play() public payable {
		
		if (msg.value > MaxAmountToBet) {
			revert();
		} else {
			if ((block.timestamp % 2) == 0) {
				
				if (address(this).balance < (msg.value * ((100 + payPercentage) / 100))) {
					// No tenemos suficientes fondos para pagar el premio, as&#237; que transferimos todo lo que tenemos
					msg.sender.transfer(address(this).balance);
					emit Status(&#39;Congratulations, you win! Sorry, we didn\&#39;t have enought money, we will deposit everything we have!&#39;, msg.sender, msg.value, true);
					
					newGame = Game({
						addr: msg.sender,
						blocknumber: block.number,
						blocktimestamp: block.timestamp,
						bet: msg.value,
						prize: address(this).balance,
						winner: true
					});
					lastPlayedGames.push(newGame);
					
				} else {
					uint _prize = msg.value * (100 + payPercentage) / 100;
					emit Status(&#39;Congratulations, you win!&#39;, msg.sender, _prize, true);
					msg.sender.transfer(_prize);
					
					newGame = Game({
						addr: msg.sender,
						blocknumber: block.number,
						blocktimestamp: block.timestamp,
						bet: msg.value,
						prize: _prize,
						winner: true
					});
					lastPlayedGames.push(newGame);
					
				}
			} else {
				emit Status(&#39;Sorry, you loose!&#39;, msg.sender, msg.value, false);
				
				newGame = Game({
					addr: msg.sender,
					blocknumber: block.number,
					blocktimestamp: block.timestamp,
					bet: msg.value,
					prize: 0,
					winner: false
				});
				lastPlayedGames.push(newGame);
				
			}
		}
    }
	
	function getGameCount() public constant returns(uint) {
		return lastPlayedGames.length;
	}

	function getGameEntry(uint index) public constant returns(address addr, uint blocknumber, uint blocktimestamp, uint bet, uint prize, bool winner) {
		return (lastPlayedGames[index].addr, lastPlayedGames[index].blocknumber, lastPlayedGames[index].blocktimestamp, lastPlayedGames[index].bet, lastPlayedGames[index].prize, lastPlayedGames[index].winner);
	}
	
	
	function depositFunds() payable public {}
    
	function withdrawFunds(uint amount) onlyOwner public {
	    require(amount <= address(this).balance);
        if (owner.send(amount)) {
            emit Status(&#39;User withdraw some money!&#39;, msg.sender, amount, true);
        }
    }
	
	function setMaxAmountToBet(uint amount) onlyOwner public returns (uint) {
		MaxAmountToBet = amount;
        return MaxAmountToBet;
    }
	
	function getMaxAmountToBet() constant public returns (uint) {
        return MaxAmountToBet;
    }
	
    
    function Kill() onlyOwner public{
        emit Status(&#39;Contract was killed, contract balance will be send to the owner!&#39;, msg.sender, address(this).balance, true);
        selfdestruct(owner);
    }
}