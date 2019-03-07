pragma solidity 0.5.4;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract pDNADistributedRegistry is Ownable {
  mapping(string => address) private registry;

  event Profiled(string eGrid, address indexed property);
  event Unprofiled(string eGrid, address indexed property);

  /**
   * this function&#39;s abi should never change and always maintain backwards compatibility
   */
  function getProperty(string memory _eGrid) public view returns (address property) {
    property = registry[_eGrid];
  }

  function profileProperty(string memory _eGrid, address _property) public onlyOwner {
    require(bytes(_eGrid).length > 0, &quot;eGrid must be non-empty string&quot;);
    require(_property != address(0), &quot;property address must be non-null&quot;);
    require(registry[_eGrid] == address(0), &quot;property must not already exist in land registry&quot;);

    registry[_eGrid] = _property;
    emit Profiled(_eGrid, _property);
  }

  function unprofileProperty(string memory _eGrid) public onlyOwner {
    address property = getProperty(_eGrid);
    require(property != address(0), &quot;property must exist in land registry&quot;);

    registry[_eGrid] = address(0);
    emit Unprofiled(_eGrid, property);
  }
}