pragma solidity ^0.5.1;

contract SavingTheSender {
    address payable public theSender;
    string public contact;
    string public message;

    constructor() public {
    	theSender = address(0);
    	contact = &#39;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="dcafa9acacb3aea89cbfaeb9bda8b5aab9bfb3b8b9f2bfb3f2b7ae">[email&#160;protected]</a>&#39;;
    	message = &#39;This smart contract is deployed for miners who would like to return the Ethereum used in transaction fees and for developers who are working tirelessly to improve blockchain technology. We would like to show the world that smart contracts can be used in such cases.&#39;;
    }
    
    event Register(address indexed _sender);
    event Transfer(address indexed _from, uint256 _value, bytes _msg);
    
    modifier isCorrectSender() {
        require(msg.sender == 0x587Ecf600d304F831201c30ea0845118dD57516e);
        _;
    }

    modifier isReceiver() {
    	require(msg.sender == theSender);
    	_;
    }

    function registerTheSender() isCorrectSender public {
    	theSender = msg.sender;
    	emit Register(msg.sender);
    }

    function appreciated() isReceiver public {
    	theSender.transfer(address(this).balance);
    }
    
    function() payable external {
        emit Transfer(msg.sender, msg.value, msg.data);
    }
}