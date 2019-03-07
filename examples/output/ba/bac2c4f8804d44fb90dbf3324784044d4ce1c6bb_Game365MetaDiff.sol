pragma solidity <= 0.6;

contract Game365MetaDiff {

    /*
        set constants
    */
    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether; 

    // Chance to win jackpot (currently 0.1%) and fee deducted into jackpot fund.
    uint public constant MIN_JACKPOT_BET = 0.1 ether;
    uint public constant JACKPOT_MODULO = 1000; 
    uint constant JACKPOT_FEE = 0.001 ether; 
    // There is minimum and maximum bets.
    uint public constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether; 
    
    // Modulo is a number of equiprobable outcomes in a game:
    //  - 2 for coin flip
    //  - 6 for dice
    //  - 6*6 = 36 for double dice
    //  - 100 for etheroll
    //  etc.
    // It&#39;s called so because 256-bit entropy is treated like a huge integer and
    // the remainder of its division by modulo is considered bet outcome.
    uint constant MAX_MODULO = 100;
    uint constant MAX_MASK_MODULO = 40;

    // This is a check on bet mask overflow.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions our croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint constant BET_EXPIRATION_BLOCKS = 250;

    // This are some constants making O(1) population count in placeBet possible.
    // See whitepaper for intuition and proofs behind it.
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F; // decimal:63, binary:111111
    
    // Owner setting
    address payable public owner = address(0x0);

    // Croupier account.
    address public croupier = address(0x0);

    // The address corresponding to a private key used to sign placeBet commits.
    address public secretSigner = address(0x0);

    // Adjustable max bet profit and start winning the jackpot. Used to cap bets against dynamic odds.
    uint public maxProfit = 5 ether;
    uint public minJackpotWinAmount = 0.1 ether;

    // Funds that are locked in potentially winning bets. Prevents contract from
    // committing to bets it cannot pay out.
    uint256 public lockedInBets_;
    uint256 public lockedInJackpot_;
    
    struct Bet {
        // Wager amount in wei.
        uint128 amount;
        // Block difficulty.
        uint128 placeBlockDifficulty;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollUnder;
        // Block number of placeBet tx.
        uint40 placeBlockNumber;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
    }
    mapping(uint256 => Bet) bets;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(uint256 indexed commit, address indexed beneficiary, uint amount, uint jackpotAmount);
    event Payment(uint256 indexed commit, address indexed beneficiary, uint amount, uint jackpotAmount);
    event JackpotPayment(address indexed beneficiary, uint amount);
    event Commit(uint256 indexed commit, uint256 possibleWinAmount);
    
    /**
        Constructor
     */
    constructor () 
        public
    {
        owner = msg.sender;
    }

    /**
        Modifier
    */
    // Standard modifier on methods invokable only by contract owner.
    modifier onlyOwner {
        require (msg.sender == owner, &quot;OnlyOwner methods called by non-owner.&quot;);
        _;
    }
    
    // Standard modifier on methods invokable only by contract owner.
    modifier onlyCroupier {
        require (msg.sender == croupier, &quot;OnlyCroupier methods called by non-croupier.&quot;);
        _;
    }

    // See comment for &quot;secretSigner&quot; variable.
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    // Change the croupier address.
    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require (_maxProfit < MAX_AMOUNT, &quot;maxProfit should be a sane number.&quot;);
        maxProfit = _maxProfit;
    }

    function setMinJackPotWinAmount(uint _minJackpotAmount) public onlyOwner {
        minJackpotWinAmount = _minJackpotAmount;
    }

    // This function is used to bump up the jackpot fund. Cannot be used to lower it.
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require (increaseAmount <= address(this).balance, &quot;Increase amount larger than balance.&quot;);
        require (lockedInJackpot_ + lockedInBets_ + increaseAmount <= address(this).balance, &quot;Not enough funds.&quot;);
        lockedInJackpot_ += uint128(increaseAmount);
    }

    // Funds withdrawal to cover costs of our operation.
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, &quot;Increase amount larger than balance.&quot;);
        require (lockedInJackpot_ + lockedInBets_ + withdrawAmount <= address(this).balance, &quot;Not enough funds.&quot;);
        sendFunds(1, beneficiary, withdrawAmount, 0);
    }
    
    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner {
        require (lockedInBets_ == 0, &quot;All bets should be processed (settled or refunded) before self-destruct.&quot;);
        selfdestruct(owner);
    }

    // Fallback function deliberately left empty. It&#39;s primary use case
    // is to top up the bank roll.
    function () external payable {
    }
    
    function placeBet(uint256 betMask, uint256 modulo, uint256 commitLastBlock, uint256 commit, bytes32 r, bytes32 s) 
        external
        payable 
    {
        Bet storage bet = bets[commit];
        require(bet.gambler == address(0), &quot;already betting same commit number&quot;);

        uint256 amount = msg.value;
        require (modulo > 1 && modulo <= MAX_MODULO, &quot;Modulo should be within range.&quot;);
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, &quot;Amount should be within range.&quot;);
        require (betMask > 0 && betMask < MAX_BET_MASK, &quot;Mask should be within range.&quot;);

        require (block.number <= commitLastBlock, &quot;Commit has expired.&quot;);

        //@DEV It will be changed later.
        bytes memory prefix = &quot;\x19Ethereum Signed Message:\n32&quot;;
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, commit));
        require (secretSigner == ecrecover(prefixedHash, 28, r, s), &quot;ECDSA signature is not valid.&quot;);

        // Winning amount and jackpot increase.
        uint rollUnder;
        
        // Small modulo games specify bet outcomes via bit mask.
        // rollUnder is a number of 1 bits in this mask (population count).
        // This magical looking formula is an efficient way to compute population
        // count on EVM for numbers below 2**40. For detailed proof consult
        // the our whitepaper.
        if(modulo <= MAX_MASK_MODULO){
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            // mask = betMask;  //Stack too deep, try removing local variables.
        }else{
            require (betMask > 0 && betMask <= modulo, &quot;High modulo range, betMask larger than modulo.&quot;);
            rollUnder = betMask;
        }

        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = getGameWinAmount(amount, modulo, rollUnder);

        // Enforce max profit limit.
        require (possibleWinAmount <= amount + maxProfit, &quot;maxProfit limit violation.&quot;);

        // Lock funds.
        lockedInBets_ += uint128(possibleWinAmount);
        lockedInJackpot_ += uint128(jackpotFee);

        // Check whether contract has enough funds to process this bet.
        require (lockedInJackpot_ + lockedInBets_ <= address(this).balance, &quot;Cannot afford to lose this bet.&quot;);
        
        // Record commit in logs.
        emit Commit(commit, possibleWinAmount);

        bet.amount = uint128(amount);
        bet.placeBlockDifficulty = uint128(block.difficulty);
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(betMask);
        bet.gambler = msg.sender;
    }
    
    // This is the method used to settle 99% of bets. To process a bet with a specific
    // &quot;commit&quot;, settleBet should supply a &quot;reveal&quot; number that would Keccak256-hash to
    // &quot;commit&quot;. &quot;difficulty&quot; is the block difficulty of placeBet block as seen by croupier; it
    // is additionally asserted to prevent changing the bet outcomes on Ethereum reorgs.
    function settleBet(uint reveal, uint difficulty) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require (block.number > placeBlockNumber, &quot;settleBet in the same block as placeBet, or before.&quot;);
        require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, &quot;Blockhash can&#39;t be queried by EVM.&quot;);
        // require (blockhash(placeBlockNumber) == blockHash, &quot;Does not matched blockHash.&quot;);
        require (bet.placeBlockDifficulty == difficulty, &quot;Does not matched difficulty.&quot;);

        // Settle bet using reveal and difficulty as entropy sources.
        settleBetCommon(bet, reveal, difficulty);
    }

    // Common settlement code for settleBet.
    function settleBetCommon(Bet storage bet, uint reveal, uint entropyDifficulty) private {
        // Fetch bet parameters into local variables (to save gas).
        uint commit = uint(keccak256(abi.encodePacked(reveal)));
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

        // Check that bet is in &#39;active&#39; state.
        require (amount != 0, &quot;Bet should be in an &#39;active&#39; state&quot;);

        // Move bet into &#39;processed&#39; state already.
        bet.amount = 0;
        
        // The RNG - combine &quot;reveal&quot; and difficulty of placeBet using Keccak256. Miners
        // are not aware of &quot;reveal&quot; and cannot deduce it from &quot;commit&quot; (as Keccak256
        // preimage is intractable), and house is unable to alter the &quot;reveal&quot; after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyDifficulty));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint game = uint(entropy) % modulo;

        uint gameWinAmount;
        uint _jackpotFee;
        (gameWinAmount, _jackpotFee) = getGameWinAmount(amount, modulo, rollUnder);

        uint gameWin = 0;
        uint jackpotWin = 0;

        // Determine game outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** game) & bet.mask != 0) {
                gameWin = gameWinAmount;
            }
        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (game < rollUnder) {
                gameWin = gameWinAmount;
            }
        }

        // Unlock the bet amount, regardless of the outcome.
        lockedInBets_ -= uint128(gameWinAmount);

        // Roll for a jackpot (if eligible).
        if (amount >= MIN_JACKPOT_BET && lockedInJackpot_ >= minJackpotWinAmount) {
            // The second modulo, statistically independent from the &quot;main&quot; dice roll.
            // Effectively you are playing two games at once!
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

            // Bingo!
            if (jackpotRng == 0) {
                jackpotWin = lockedInJackpot_;
                lockedInJackpot_ = 0;
            }
        }

        // Log jackpot win.
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

        // Send the funds to gambler.
        sendFunds(commit, gambler, gameWin, jackpotWin);
    }

    function getGameWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require (0 < rollUnder && rollUnder <= modulo, &quot;Win probability out of range.&quot;);

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require (houseEdge + jackpotFee <= amount, &quot;Bet doesn&#39;t even cover house edge.&quot;);
        winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
    }
    
    // Refund transaction - return the bet amount of a roll that was not processed in a
    // due timeframe. Processing such blocks is not possible due to EVM limitations (see
    // BET_EXPIRATION_BLOCKS comment above for details). In case you ever find yourself
    // in a situation like this, just contact the our support, however nothing
    // precludes you from invoking this method yourself.
    function refundBet(uint commit) external {
        // Check that bet is in &#39;active&#39; state.
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, &quot;Bet should be in an &#39;active&#39; state&quot;);

        // Check that bet has already expired.
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, &quot;Blockhash can&#39;t be queried by EVM.&quot;);

        // Move bet into &#39;processed&#39; state, release funds.
        bet.amount = 0;
        
        uint gameWinAmount;
        uint jackpotFee;
        (gameWinAmount, jackpotFee) = getGameWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets_ -= uint128(gameWinAmount);
        lockedInJackpot_ -= uint128(jackpotFee);

        // Send the refund.
        sendFunds(commit, bet.gambler, amount, 0);
    }

    // Helper routine to process the payment.
    function sendFunds(uint commit, address payable beneficiary, uint gameWin, uint jackpotWin) private {
        uint amount = gameWin + jackpotWin == 0 ? 1 wei : gameWin + jackpotWin;
        uint successLogAmount = gameWin;

        if (beneficiary.send(amount)) {
            emit Payment(commit, beneficiary, successLogAmount, jackpotWin);
        } else {
            emit FailedPayment(commit, beneficiary, amount, 0);
        }
    }
    
}