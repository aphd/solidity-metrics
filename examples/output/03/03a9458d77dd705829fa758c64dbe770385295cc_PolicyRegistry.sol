pragma solidity ^0.4.24;

/**
 *  @title PolicyRegistry
 *  @author Enrique Piqueras - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1a7f6a736b6f7f687b69695a7d777b737634797577">[email&#160;protected]</a>>
 *  @dev A contract to maintain a policy for each subcourt.
 */
contract PolicyRegistry {
    /* Events */

    /** @dev Emitted when a policy is updated.
     *  @param _subcourtID The ID of the policy&#39;s subcourt.
     *  @param _policy The URI of the policy JSON.
     */
    event PolicyUpdate(uint indexed _subcourtID, string _policy);

    /* Storage */

    address public governor;
    mapping(uint => string) public policies;

    /* Modifiers */

    /** @dev Requires that the sender is the governor. */
    modifier onlyByGovernor() {require(governor == msg.sender, &quot;Can only be called by the governor.&quot;); _;}

    /* Constructor */

    /** @dev Constructs the `PolicyRegistry` contract.
     *  @param _governor The governor&#39;s address.
     */
    constructor(address _governor) public {governor = _governor;}

    /* External */

    /** @dev Changes the `governor` storage variable.
     *  @param _governor The new value for the `governor` storage variable.
     */
    function changeGovernor(address _governor) external onlyByGovernor {governor = _governor;}

    /** @dev Sets the policy for the specified subcourt.
     *  @param _subcourtID The ID of the specified subcourt.
     *  @param _policy The URI of the policy JSON.
     */
    function setPolicy(uint _subcourtID, string _policy) external onlyByGovernor {
        emit PolicyUpdate(_subcourtID, policies[_subcourtID]);
        policies[_subcourtID] = _policy;
    }
}