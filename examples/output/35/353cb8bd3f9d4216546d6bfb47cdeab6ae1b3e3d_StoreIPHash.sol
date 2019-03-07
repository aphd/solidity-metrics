pragma solidity ^0.4.19;

contract StoreIPHash {
  string constant _ipHash = &quot;IP1.txt.zip 1bdf34b347d70f6aadc952a76532e077&quot;;
  function  getIPHash() public returns(string) {
    return _ipHash;
  }

}