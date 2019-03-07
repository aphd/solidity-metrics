pragma solidity >=0.4.24;

contract frozenForever {
    string public  name = &quot;DEFLAT FROZEN FOREVER&quot;;
    string public symbol = &quot;DEFT&quot;;
    string public comment = &#39;this contract do nothing&#39;;

    function () payable external {        
       //this function has nothing 		
    }
}