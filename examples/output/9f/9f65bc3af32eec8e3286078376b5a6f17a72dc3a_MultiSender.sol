pragma solidity ^0.5.0;

/**
 * The ERC20 multi sender Contract
 * Useful to do multiple transfers of the same token to different addresses
 * 
 * @author Fabio Pacchioni <mailto:<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="731512111a1c5d031210101b1a1c1d1a33141e121a1f5d101c1e">[email&#160;protected]</a>>
 * @author Marco Vasapollo <mailto:<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="bdded8d2fdd0d8c9dccfd4d3da93ded2d0">[email&#160;protected]</a>>
 */

contract ERC20 {
    function transferFrom(address from, address to, uint256 value) public returns (bool) {}
}

contract MultiSender {
    
    /**
     * @param _tokenAddr the address of the ERC20Token
     * @param _to the list of addresses that can receive your tokens
     * @param _value the list of all the amounts that every _to address will receive
     * 
     * @return true if all the transfers are OK.
     * 
     * PLEASE NOTE: Max 150 addresses per time are allowed.
     * 
     * PLEASE NOTE: remember to call the &#39;approve&#39; function on the Token first,
     * to let MultiSender be able to transfer your tokens.
     */
    function multiSend(address _tokenAddr, address[] memory _to, uint256[] memory _value) public returns (bool _success) {
        assert(_to.length == _value.length);
        assert(_to.length <= 150);
        ERC20 _token = ERC20(_tokenAddr);
        for (uint8 i = 0; i < _to.length; i++) {
            assert((_token.transferFrom(msg.sender, _to[i], _value[i])) == true);
        }
        return true;
    }
}