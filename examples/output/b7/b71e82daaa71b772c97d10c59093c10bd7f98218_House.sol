/*
 * Kryptium House Smart Contract v.1.1.0
 * Copyright &#169; 2019 Kryptium Team <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cca5a2aaa38ca7beb5bcb8a5b9a1e2a5a3">[email&#160;protected]</a>>
 * Author: Giannis Zarifis <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5b31213a29323d32281b3029222b2f322e36753234">[email&#160;protected]</a>>
 * 
 * A decentralised betting house in the form of an Ethereum smart contract which 
 * registers bets, escrows the amounts wagered and transfers funds following the 
 * outcomes of the corresponding events. It can be fully autonomous or managed 
 * and might charge a commission for its services.
 *
 * This program is free to use according the Terms of Use available at
 * <https://kryptium.io/terms-of-use/>. You cannot resell it or copy any
 * part of it or modify it without permission from the Kryptium Team.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the Terms and Conditions for more details.
 */

pragma solidity ^0.5.0;

/**
 * SafeMath
 * Math operations with safety checks that throw on error
 */
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b != 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        return div(mul(number, numerator), denominator);
    }
}

contract Owned {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0x0));
        owner = newOwner;
    }
}

/*
Oracle smart contract interface
*/
interface OracleContract {
    function eventOutputs(uint eventId, uint outputId) external view returns (bool isSet, string memory title, uint possibleResultsCount, uint  eventOutputType, string memory announcement, uint decimals); 
    function owner() external view returns (address);
    function getEventForHousePlaceBet(uint id) external view returns (uint closeDateTime, uint freezeDateTime, bool isCancelled); 
    function getEventOutcomeIsSet(uint eventId, uint outputId) external view returns (bool isSet);
    function getEventOutcome(uint eventId, uint outputId) external view returns (uint outcome); 
    function getEventOutcomeNumeric(uint eventId, uint outputId) external view returns(uint256 outcome1, uint256 outcome2,uint256 outcome3,uint256 outcome4, uint256 outcome5, uint256 outcome6);
}

/*
House smart contract interface
*/
interface HouseContract {
    function owner() external view returns (address); 
    function isHouse() external view returns (bool); 
}



/*
 * Kryptium House Smart Contract.
 */
contract House is SafeMath, Owned {

    //enum Category { football, basket }

    enum BetType { headtohead, multiuser, poolbet }

    enum BetEvent { placeBet, callBet, removeBet, refuteBet, settleWinnedBet, settleCancelledBet, increaseWager, cancelledByHouse }

    uint private betNextId;


    struct Bet { 
        uint id;
        address oracleAddress;
        uint eventId;
        uint outputId;
        uint outcome;
        bool isOutcomeSet;
        uint closeDateTime;
        uint freezeDateTime;
        bool isCancelled;
        uint256 minimumWager;
        uint256 maximumWager;
        uint256 payoutRate;
        address createdBy;
        BetType betType;
    } 


    struct HouseData { 
        bool managed;
        string  name;
        string  creatorName;
        string  countryISO; 
        address oracleAddress;
        address oldOracleAddress;       
        bool  newBetsPaused;
        uint  housePercentage;
        uint oraclePercentage;   
        uint version;
        string shortMessage;              
    } 

    address public _newHouseAddress;

    HouseData public houseData;  

    // This creates an array with all bets
    mapping (uint => Bet) public bets;

    //Last betting activity timestamp
    uint public lastBettingActivity;

    //Total bets
    uint public totalBets;

    //Total amount played on bets
    uint public totalAmountOnBets;

    //Total amount on Bet
    mapping (uint => uint256) public betTotalAmount;

    //Totalbets on bet
    mapping (uint => uint) public betTotalBets;

    //Bet Refutes amount
    mapping (uint => uint256) public betRefutedAmount;

    //Total amount placed on a bet forecast
    mapping (uint => mapping (uint => uint256)) public betForcastTotalAmount;    

    //Player bet total amount on a Bet
    mapping (address => mapping (uint => uint256)) public playerBetTotalAmount;

    //Player bet total bets on a Bet
    mapping (address => mapping (uint => uint)) public playerBetTotalBets;

    //Player wager for a Bet.Output.Forecast
    mapping (address => mapping (uint => mapping (uint => uint256))) public playerBetForecastWager;

    //head to head bets forecasts
    mapping (uint => mapping (address => uint)) public headToHeadForecasts;  

    //head to head bets max accepted forecasts
    mapping (uint => uint) public headToHeadMaxAcceptedForecasts;  

    //Player output(cause or win or refund)  of a bet
    mapping (address => mapping (uint => uint256)) public playerOutputFromBet;    

    //Player bet Refuted
    mapping (address => mapping (uint => bool)) public playerBetRefuted;    

    //Player bet Settled
    mapping (address => mapping (uint => bool)) public playerBetSettled; 


    //Total bets placed by player
    mapping (address => uint) public totalPlayerBets;


    //Total amount placed for bets by player
    mapping (address => uint256) public totalPlayerBetsAmount;

    // User balances
    mapping (address => uint256) public balance;

    // Stores the house owners percentage as part per thousand 
    mapping (address => uint) public ownerPerc;

    //The array of house owners
    address[] public owners;

    //The House and Oracle edge has been paid
    mapping (uint => bool) public housePaid;

    //The total remaining House amount collected from fees for Bet
    mapping (uint => uint256) public houseEdgeAmountForBet;

    //The total remaining Oracle amount collected from fees for Bet
    mapping (uint => uint256) public oracleEdgeAmountForBet;

    //The total House fees
    uint256 public houseTotalFees;

    //The total Oracle fees
    mapping (address => uint256) public oracleTotalFees;

    // Notifies clients that a new house is launched
    event HouseCreated();

    // Notifies clients that a house data has changed
    event HousePropertiesUpdated();    

    event BetPlacedOrModified(uint id, address sender, BetEvent betEvent, uint256 amount, uint forecast, string createdBy, uint closeDateTime);


    event transfer(address indexed wallet, uint256 amount,bool inbound);

    event testevent(uint betTotalAmount, uint AcceptedWager, uint headToHeadForecastsOPEN, uint matchedANDforecast, uint matchedORforecast, uint headToHeadMaxAcceptedForecast);


    /**
     * Constructor function
     * Initializes House contract
     */
    constructor(bool managed, string memory houseName, string memory houseCreatorName, string memory houseCountryISO, address oracleAddress, address[] memory ownerAddress, uint[] memory ownerPercentage, uint housePercentage,uint oraclePercentage, uint version) public {
        require(add(housePercentage,oraclePercentage)<1000,&quot;House + Oracle percentage should be lower than 100%&quot;);
        houseData.managed = managed;
        houseData.name = houseName;
        houseData.creatorName = houseCreatorName;
        houseData.countryISO = houseCountryISO;
        houseData.housePercentage = housePercentage;
        houseData.oraclePercentage = oraclePercentage; 
        houseData.oracleAddress = oracleAddress;
        houseData.shortMessage = &quot;&quot;;
        houseData.newBetsPaused = true;
        houseData.version = version;
        uint ownersTotal = 0;
        for (uint i = 0; i<ownerAddress.length; i++) {
            owners.push(ownerAddress[i]);
            ownerPerc[ownerAddress[i]] = ownerPercentage[i];
            ownersTotal += ownerPercentage[i];
            }
        require(ownersTotal == 1000);    
        emit HouseCreated();
    }



    /**
     * Check if valid house contract
     */
    function isHouse() public pure returns(bool response) {
        return true;    
    }

     /**
     * Updates House Data function
     *
     */
    function updateHouseProperties(string memory houseName, string memory houseCreatorName, string memory houseCountryISO) onlyOwner public {
        houseData.name = houseName;
        houseData.creatorName = houseCreatorName;
        houseData.countryISO = houseCountryISO;     
        emit HousePropertiesUpdated();
    }    

    /**
     * Updates House Oracle function
     *
     */
    function changeHouseOracle(address oracleAddress, uint oraclePercentage) onlyOwner public {
        require(add(houseData.housePercentage,oraclePercentage)<1000,&quot;House + Oracle percentage should be lower than 100%&quot;);
        if (oracleAddress != houseData.oracleAddress) {
            houseData.oldOracleAddress = houseData.oracleAddress;
            houseData.oracleAddress = oracleAddress;
        }
        houseData.oraclePercentage = oraclePercentage;
        emit HousePropertiesUpdated();
    } 

    /**
     * Updates House percentage function
     *
     */
    function changeHouseEdge(uint housePercentage) onlyOwner public {
        require(housePercentage != houseData.housePercentage,&quot;New percentage is identical with current&quot;);
        require(add(housePercentage,houseData.oraclePercentage)<1000,&quot;House + Oracle percentage should be lower than 100%&quot;);
        houseData.housePercentage = housePercentage;
        emit HousePropertiesUpdated();
    } 



    function updateBetDataFromOracle(uint betId) private {
        if (!bets[betId].isOutcomeSet) {
            (bets[betId].isOutcomeSet) = OracleContract(bets[betId].oracleAddress).getEventOutcomeIsSet(bets[betId].eventId,bets[betId].outputId); 
            if (bets[betId].isOutcomeSet) {
                (bets[betId].outcome) = OracleContract(bets[betId].oracleAddress).getEventOutcome(bets[betId].eventId,bets[betId].outputId); 
            }
        }     
        if (!bets[betId].isCancelled) {
        (bets[betId].closeDateTime, bets[betId].freezeDateTime, bets[betId].isCancelled) = OracleContract(bets[betId].oracleAddress).getEventForHousePlaceBet(bets[betId].eventId);      
        }  
        if (!bets[betId].isOutcomeSet && bets[betId].freezeDateTime <= now) {
            bets[betId].isCancelled = true;
        }
    }

    /**
     * Get the possibleResultsCount of an Event.Output as uint.
     * Should be changed in a future version to use an Oracle function that directly returns possibleResultsCount instead of receive the whole eventOutputs structure
     */
    function getEventOutputMaxUint(address oracleAddress, uint eventId, uint outputId) private view returns (uint) {
        (bool isSet, string memory title, uint possibleResultsCount, uint  eventOutputType, string memory announcement, uint decimals) = OracleContract(oracleAddress).eventOutputs(eventId,outputId);
        return 2 ** possibleResultsCount - 1;
    }


function checkPayoutRate(uint256 payoutRate) public view {
    uint256 multBase = 10 ** 18;
    uint256 houseFees = houseData.housePercentage + houseData.oraclePercentage;
    uint256 check1 = div(multBase , (1000 - houseFees));
    check1 = div(mul(100000 , check1), multBase);
    uint256 check2 = 10000;
    if (houseFees > 0) {
        check2 =  div(multBase , houseFees);
        check2 = div(mul(100000 ,check2), multBase);
    }
    require(payoutRate>check1 && payoutRate<check2,&quot;Payout rate out of accepted range&quot;);
}


    /*
     * Place a Bet
     */
    function placeBet(uint eventId, BetType betType,uint outputId, uint forecast, uint256 wager, uint closingDateTime, uint256 minimumWager, uint256 maximumWager, uint256 payoutRate, string memory createdBy) public {
        require(wager>0,&quot;Wager should be greater than zero&quot;);
        require(balance[msg.sender]>=wager,&quot;Not enough balance&quot;);
        require(!houseData.newBetsPaused,&quot;Bets are paused right now&quot;);
        require(betType == BetType.headtohead || betType == BetType.poolbet,&quot;Only poolbet and headtohead bets are implemented&quot;);
        betNextId += 1;
        bets[betNextId].id = betNextId;
        bets[betNextId].oracleAddress = houseData.oracleAddress;
        bets[betNextId].outputId = outputId;
        bets[betNextId].eventId = eventId;
        bets[betNextId].betType = betType;
        bets[betNextId].createdBy = msg.sender;
        updateBetDataFromOracle(betNextId);
        require(!bets[betNextId].isCancelled,&quot;Event has been cancelled&quot;);
        require(!bets[betNextId].isOutcomeSet,&quot;Event has already an outcome&quot;);
        if (closingDateTime>0) {
            bets[betNextId].closeDateTime = closingDateTime;
        }  
        require(bets[betNextId].closeDateTime >= now,&quot;Close time has passed&quot;);
        if (betType == BetType.poolbet) {
            if (minimumWager != 0) {
                bets[betNextId].minimumWager = minimumWager;
            } else {
                bets[betNextId].minimumWager = wager;
            }
            if (maximumWager != 0) {
                bets[betNextId].maximumWager = maximumWager;
            }
        } else if (betType == BetType.headtohead) {
            checkPayoutRate(payoutRate);
            uint maxAcceptedForecast = getEventOutputMaxUint(bets[betNextId].oracleAddress, bets[betNextId].eventId, bets[betNextId].outputId);
            headToHeadMaxAcceptedForecasts[betNextId] = maxAcceptedForecast;
            require(forecast>0 && forecast < maxAcceptedForecast,&quot;Forecast should be grater than zero and less than Max accepted forecast(All options true)&quot;);
            bets[betNextId].payoutRate = payoutRate;
            headToHeadForecasts[betNextId][msg.sender] = forecast;
        }
              
        playerBetTotalBets[msg.sender][betNextId] = 1;
        betTotalBets[betNextId] = 1;
        betTotalAmount[betNextId] = wager;
        totalBets += 1;
        totalAmountOnBets += wager;
        if (houseData.housePercentage>0) {
            houseEdgeAmountForBet[betNextId] += mulByFraction(wager, houseData.housePercentage, 1000);
        }
        if (houseData.oraclePercentage>0) {
            oracleEdgeAmountForBet[betNextId] += mulByFraction(wager, houseData.oraclePercentage, 1000);
        }

        balance[msg.sender] -= wager;

 
        betForcastTotalAmount[betNextId][forecast] = wager;

        playerBetTotalAmount[msg.sender][betNextId] = wager;

        playerBetForecastWager[msg.sender][betNextId][forecast] = wager;

        totalPlayerBets[msg.sender] += 1;

        totalPlayerBetsAmount[msg.sender] += wager;

        lastBettingActivity = block.number;
        
        emit BetPlacedOrModified(betNextId, msg.sender, BetEvent.placeBet, wager, forecast, createdBy, bets[betNextId].closeDateTime);
    }  

    /*
     * Call a Bet
     */
    function callBet(uint betId, uint forecast, uint256 wager, string memory createdBy) public {
        require(wager>0,&quot;Wager should be greater than zero&quot;);
        require(balance[msg.sender]>=wager,&quot;Not enough balance&quot;);
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,&quot;Only poolbet and headtohead bets are implemented&quot;);
        require(bets[betId].betType != BetType.headtohead || betTotalBets[betId] == 1,&quot;Head to head bet has been already called&quot;);
        require(wager>=bets[betId].minimumWager,&quot;Wager is lower than the minimum accepted&quot;);
        require(bets[betId].maximumWager==0 || wager<=bets[betId].maximumWager,&quot;Wager is higher then the maximum accepted&quot;);
        updateBetDataFromOracle(betId);
        require(!bets[betId].isCancelled,&quot;Bet has been cancelled&quot;);
        require(!bets[betId].isOutcomeSet,&quot;Event has already an outcome&quot;);
        require(bets[betId].closeDateTime >= now,&quot;Close time has passed&quot;);
        if (bets[betId].betType == BetType.headtohead) {
            require(bets[betId].createdBy != msg.sender,&quot;Player has been opened the bet&quot;);
            require(wager == mulByFraction( betTotalAmount[betId], bets[betId].payoutRate - 100, 100),&quot;Wager should be equal to [Opened bet Wager  * PayoutRate - 100]&quot;);
            require(headToHeadForecasts[betId][bets[betId].createdBy] & forecast == 0,&quot;Forecast overlaps opened bet forecast&quot;);
            require(headToHeadForecasts[betId][bets[betId].createdBy] | forecast == headToHeadMaxAcceptedForecasts[betId],&quot;Forecast should be opposite to the opened&quot;);
            headToHeadForecasts[betId][msg.sender] = forecast;           
        } else if (bets[betId].betType == BetType.poolbet) {
            require(playerBetForecastWager[msg.sender][betId][forecast] == 0,&quot;Already placed a bet on this forecast, use increaseWager method instead&quot;);
        }

        betTotalBets[betId] += 1;
        betTotalAmount[betId] += wager;
        totalAmountOnBets += wager;
        if (houseData.housePercentage>0) {
            houseEdgeAmountForBet[betId] += mulByFraction(wager, houseData.housePercentage, 1000);
        }
        if (houseData.oraclePercentage>0) {
            oracleEdgeAmountForBet[betId] += mulByFraction(wager, houseData.oraclePercentage, 1000);
        }


        balance[msg.sender] -= wager;

        playerBetTotalBets[msg.sender][betId] += 1;

        betForcastTotalAmount[betId][forecast] += wager;

        playerBetTotalAmount[msg.sender][betId] += wager;

        playerBetForecastWager[msg.sender][betId][forecast] = wager;

        totalPlayerBets[msg.sender] += 1;

        totalPlayerBetsAmount[msg.sender] += wager;

        lastBettingActivity = block.number;

        emit BetPlacedOrModified(betId, msg.sender, BetEvent.callBet, wager, forecast, createdBy, bets[betId].closeDateTime);   
    }  

    /*
     * Increase wager
     */
    function increaseWager(uint betId, uint forecast, uint256 additionalWager, string memory createdBy) public {
        require(additionalWager>0,&quot;Increase wager amount should be greater than zero&quot;);
        require(balance[msg.sender]>=additionalWager,&quot;Not enough balance&quot;);
        require(bets[betId].betType == BetType.poolbet,&quot;Only poolbet supports the increaseWager&quot;);
        require(playerBetForecastWager[msg.sender][betId][forecast] > 0,&quot;Haven&#39;t placed any bet for this forecast. Use callBet instead&quot;);
        uint256 wager = playerBetForecastWager[msg.sender][betId][forecast] + additionalWager;
        require(bets[betId].maximumWager==0 || wager<=bets[betId].maximumWager,&quot;The updated wager is higher then the maximum accepted&quot;);
        updateBetDataFromOracle(betId);
        require(!bets[betId].isCancelled,&quot;Bet has been cancelled&quot;);
        require(!bets[betId].isOutcomeSet,&quot;Event has already an outcome&quot;);
        require(bets[betId].closeDateTime >= now,&quot;Close time has passed&quot;);
        betTotalAmount[betId] += additionalWager;
        totalAmountOnBets += additionalWager;
        if (houseData.housePercentage>0) {
            houseEdgeAmountForBet[betId] += mulByFraction(additionalWager, houseData.housePercentage, 1000);
        }
        if (houseData.oraclePercentage>0) {
            oracleEdgeAmountForBet[betId] += mulByFraction(additionalWager, houseData.oraclePercentage, 1000);
        }

        balance[msg.sender] -= additionalWager;

        betForcastTotalAmount[betId][forecast] += additionalWager;

        playerBetTotalAmount[msg.sender][betId] += additionalWager;

        playerBetForecastWager[msg.sender][betId][forecast] += additionalWager;

        totalPlayerBetsAmount[msg.sender] += additionalWager;

        lastBettingActivity = block.number;

        emit BetPlacedOrModified(betId, msg.sender, BetEvent.increaseWager, additionalWager, forecast, createdBy, bets[betId].closeDateTime);       
    }

    /*
     * Remove a Bet
     */
    function removeBet(uint betId, string memory createdBy) public {
        require(bets[betId].createdBy == msg.sender,&quot;Caller and player created don&#39;t match&quot;);
        require(playerBetTotalBets[msg.sender][betId] > 0, &quot;Player should has placed at least one bet&quot;);
        require(betTotalBets[betId] == playerBetTotalBets[msg.sender][betId],&quot;The bet has been called by other player&quot;);
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,&quot;Only poolbet and headtohead bets are implemented&quot;);
        updateBetDataFromOracle(betId);  
        bets[betId].isCancelled = true;
        uint256 wager = betTotalAmount[betId];
        betTotalBets[betId] = 0;
        betTotalAmount[betId] = 0;
        totalBets -= playerBetTotalBets[msg.sender][betId];
        totalAmountOnBets -= wager;
        houseEdgeAmountForBet[betId] = 0;
        oracleEdgeAmountForBet[betId] = 0;
        balance[msg.sender] += wager;
        playerBetTotalAmount[msg.sender][betId] = 0;
        totalPlayerBets[msg.sender] -= playerBetTotalBets[msg.sender][betId];
        totalPlayerBetsAmount[msg.sender] -= wager;
        playerBetTotalBets[msg.sender][betId] = 0;
        lastBettingActivity = block.number;       
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.removeBet, wager, 0, createdBy, bets[betId].closeDateTime);      
    } 

    /*
     * Refute a Bet
     */
    function refuteBet(uint betId, string memory createdBy) public {
        require(playerBetTotalAmount[msg.sender][betId]>0,&quot;Caller hasn&#39;t placed any bet&quot;);
        require(!playerBetRefuted[msg.sender][betId],&quot;Already refuted&quot;);
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,&quot;Only poolbet and headtohead bets are implemented&quot;);
        updateBetDataFromOracle(betId);  
        require(bets[betId].isOutcomeSet, &quot;Refute isn&#39;t allowed when no outcome has been set&quot;);
        require(bets[betId].freezeDateTime > now, &quot;Refute isn&#39;t allowed when Event freeze has passed&quot;);
        playerBetRefuted[msg.sender][betId] = true;
        betRefutedAmount[betId] += playerBetTotalAmount[msg.sender][betId];
        if (betRefutedAmount[betId] >= betTotalAmount[betId]) {
            bets[betId].isCancelled = true;   
        }
        lastBettingActivity = block.number;       
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.refuteBet, 0, 0, createdBy, bets[betId].closeDateTime);    
    } 


    /*
     * Settle a Bet
     */
    function settleBet(uint betId, string memory createdBy) public {
        require(playerBetTotalAmount[msg.sender][betId]>0, &quot;Caller hasn&#39;t placed any bet&quot;);
        require(!playerBetSettled[msg.sender][betId],&quot;Already settled&quot;);
        require(bets[betId].betType == BetType.headtohead || bets[betId].betType == BetType.poolbet,&quot;Only poolbet and headtohead bets are implemented&quot;);
        updateBetDataFromOracle(betId);
        require(bets[betId].isCancelled || bets[betId].isOutcomeSet,&quot;Bet should be cancelled or has an outcome&quot;);
        require(bets[betId].freezeDateTime <= now,&quot;Bet payments are freezed&quot;);
        BetEvent betEvent;
        if (bets[betId].isCancelled) {
            betEvent = BetEvent.settleCancelledBet;
            houseEdgeAmountForBet[betId] = 0;
            oracleEdgeAmountForBet[betId] = 0;
            playerOutputFromBet[msg.sender][betId] = playerBetTotalAmount[msg.sender][betId];            
        } else {
            if (!housePaid[betId] && houseEdgeAmountForBet[betId] > 0) {
                for (uint i = 0; i<owners.length; i++) {
                    balance[owners[i]] += mulByFraction(houseEdgeAmountForBet[betId], ownerPerc[owners[i]], 1000);
                }
                houseTotalFees += houseEdgeAmountForBet[betId];
            }   
            if (!housePaid[betId] && oracleEdgeAmountForBet[betId] > 0) {
                address oracleOwner = HouseContract(bets[betId].oracleAddress).owner();
                balance[oracleOwner] += oracleEdgeAmountForBet[betId];
                oracleTotalFees[bets[betId].oracleAddress] += oracleEdgeAmountForBet[betId];
            }
            housePaid[betId] = true;
            uint256 totalBetAmountAfterFees = betTotalAmount[betId] - houseEdgeAmountForBet[betId] - oracleEdgeAmountForBet[betId];
            if (bets[betId].betType == BetType.poolbet) {
                if (betForcastTotalAmount[betId][bets[betId].outcome]>0) {                  
                    playerOutputFromBet[msg.sender][betId] = mulByFraction(totalBetAmountAfterFees, playerBetForecastWager[msg.sender][betId][bets[betId].outcome], betForcastTotalAmount[betId][bets[betId].outcome]);            
                } else {
                    playerOutputFromBet[msg.sender][betId] = playerBetTotalAmount[msg.sender][betId] - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.housePercentage, 1000) - mulByFraction(playerBetTotalAmount[msg.sender][betId], houseData.oraclePercentage, 1000);
                }
            } else if (bets[betId].betType == BetType.headtohead) {
                if (headToHeadForecasts[betId][msg.sender] & (2 ** bets[betId].outcome) > 0) {
                    playerOutputFromBet[msg.sender][betId] = totalBetAmountAfterFees;
                } else {
                    playerOutputFromBet[msg.sender][betId] = 0;
                }
            }
            require(playerOutputFromBet[msg.sender][betId] > 0,&quot;Settled amount should be grater than zero&quot;);
            betEvent = BetEvent.settleWinnedBet;
        }      
        playerBetSettled[msg.sender][betId] = true;
        balance[msg.sender] += playerOutputFromBet[msg.sender][betId];
        lastBettingActivity = block.number;
        emit BetPlacedOrModified(betId, msg.sender, betEvent, playerOutputFromBet[msg.sender][betId],0, createdBy, bets[betId].closeDateTime);  
    } 

    function() external payable {
        balance[msg.sender] = add(balance[msg.sender],msg.value);
        emit transfer(msg.sender,msg.value,true);
    }


    /**
    * Checks if a player has betting activity on House 
    */
    function isPlayer(address playerAddress) public view returns(bool) {
        return (totalPlayerBets[playerAddress] > 0);
    }

    /**
    * Update House short message 
    */
    function updateShortMessage(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        emit HousePropertiesUpdated();
    }


    /**
    * Starts betting
    */
    function startNewBets(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        houseData.newBetsPaused = false;
        emit HousePropertiesUpdated();
    }

    /**
    * Pauses betting
    */
    function stopNewBets(string memory shortMessage) onlyOwner public {
        houseData.shortMessage = shortMessage;
        houseData.newBetsPaused = true;
        emit HousePropertiesUpdated();
    }

    /**
    * Link House to a new version
    */
    function linkToNewHouse(address newHouseAddress) onlyOwner public {
        require(newHouseAddress!=address(this),&quot;New address is current address&quot;);
        require(HouseContract(newHouseAddress).isHouse(),&quot;New address should be a House smart contract&quot;);
        _newHouseAddress = newHouseAddress;
        houseData.newBetsPaused = true;
        emit HousePropertiesUpdated();
    }

    /**
    * UnLink House from a newer version
    */
    function unLinkNewHouse() onlyOwner public {
        _newHouseAddress = address(0);
        houseData.newBetsPaused = false;
        emit HousePropertiesUpdated();
    }

    /**
    * Cancels a Bet
    */
    function cancelBet(uint betId) onlyOwner public {
        require(houseData.managed, &quot;Cancel available on managed Houses&quot;);
        updateBetDataFromOracle(betId);
        require(bets[betId].freezeDateTime > now,&quot;Freeze time passed&quot;);       
        bets[betId].isCancelled = true;
        emit BetPlacedOrModified(betId, msg.sender, BetEvent.cancelledByHouse, 0, 0, &quot;&quot;, bets[betId].closeDateTime);  
    }

    /**
    * Settle fees of Oracle and House for a bet
    */
    function settleBetFees(uint betId) onlyOwner public {
        require(bets[betId].isCancelled || bets[betId].isOutcomeSet,&quot;Bet should be cancelled or has an outcome&quot;);
        require(bets[betId].freezeDateTime <= now,&quot;Bet payments are freezed&quot;);
        if (!housePaid[betId] && houseEdgeAmountForBet[betId] > 0) {
            for (uint i = 0; i<owners.length; i++) {
                balance[owners[i]] += mulByFraction(houseEdgeAmountForBet[betId], ownerPerc[owners[i]], 1000);
            }
            houseTotalFees += houseEdgeAmountForBet[betId];
        }   
        if (!housePaid[betId] && oracleEdgeAmountForBet[betId] > 0) {
            address oracleOwner = HouseContract(bets[betId].oracleAddress).owner();
            balance[oracleOwner] += oracleEdgeAmountForBet[betId];
            oracleTotalFees[bets[betId].oracleAddress] += oracleEdgeAmountForBet[betId];
        }
        housePaid[betId] = true;
    }

    /**
    * Withdraw the requested amount to the sender address
    */
    function withdraw(uint256 amount) public {
        require(address(this).balance>=amount,&quot;Insufficient House balance. Shouldn&#39;t have happened&quot;);
        require(balance[msg.sender]>=amount,&quot;Insufficient balance&quot;);
        balance[msg.sender] = sub(balance[msg.sender],amount);
        msg.sender.transfer(amount);
        emit transfer(msg.sender,amount,false);
    }

    /**
    * Withdraw the requested amount to an address
    */
    function withdrawToAddress(address payable destinationAddress,uint256 amount) public {
        require(address(this).balance>=amount);
        require(balance[msg.sender]>=amount,&quot;Insufficient balance&quot;);
        balance[msg.sender] = sub(balance[msg.sender],amount);
        destinationAddress.transfer(amount);
        emit transfer(msg.sender,amount,false);
    }

}