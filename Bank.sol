pragma solidity 0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";


contract BankAuthority is Ownable {

    event Deposited (uint value);

    //address [] public admins;
    mapping (address => bool) public admins;
    uint public approvals;

    struct Request {
        uint id;
        address payable to;
        uint value;
        uint8 approves;
        bool isToken;
        address tokenAddress;
        bool status;
    }

        struct RequestAdmin {
        uint id;
        address admin;
        bool isAdmin;
        uint8 approves;
        bool status;
    }

    mapping (address => mapping(uint => bool)) public isAddressApprove;
    Request [] public requests;

    //constructor
    constructor(address [] memory _addresses, uint _numberOfApprovals) {

        for (uint i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
        approvals = _numberOfApprovals;
    }


    //check eth balance
    function getEthBalance() public view returns(uint){
        return address(this).balance;
    }


    //deposit eth
    function deposit () external payable {
        emit Deposited(msg.value);
    }

    //create eth/bnb transfer request
    function createEthTransferRequest(address payable _to, uint _value) external returns(bool) {


        Request memory _newRequest;
        uint _id = requests.length;

        _newRequest.id = _id;
        _newRequest.to = _to;
        _newRequest.value = _value;
        _newRequest.approves = 1;
        _newRequest.isToken = false;
        _newRequest.status = false;

        requests.push(_newRequest);

        isAddressApprove[msg.sender][_id] = true;


        return true;
    }


    //create ERC20 transfer request
    function createTokenTransferRequest(address _token, address payable _to, uint _value) external returns(bool) {

        Request memory _newRequest;
        uint _id = requests.length;

        _newRequest.id = _id;
        _newRequest.to = _to;
        _newRequest.value = _value;
        _newRequest.approves = 1;
        _newRequest.isToken = true;
        _newRequest.tokenAddress = _token;
        _newRequest.status = false;

        requests.push(_newRequest);

        isAddressApprove[msg.sender][_id] = true;
        return true;
    }


    //sign transfer tx
    function signTransferRequest(uint _id) external returns(bool) {


        require(!isAddressApprove[msg.sender][_id], "already signed by you");
        require(admins[msg.sender], "not admin");


        Request storage _currentRequest = requests[_id];
        _currentRequest.approves++;
        isAddressApprove[msg.sender][_id] = true;


        return true;
    }



    //execute transfer tx
    function executeEthTransferRequest(uint _id) external returns(bool) {


        Request storage _currentRequest = requests[_id];

        require(!_currentRequest.isToken, "request should transfer ETH");
        require(!_currentRequest.status, "already executed");
        require(_currentRequest.approves >= approvals, "not enough signs");
        require(_currentRequest.value <= address(this).balance, "not enough ETH on wallet");

        _currentRequest.status = true;
        _currentRequest.to.send(_currentRequest.value);


        return true;
    }


    //execute token transfer tx
    function executeTokenTransferRequest(uint _id) external returns(bool) {

        Request storage _currentRequest = requests[_id];

        require(_currentRequest.isToken, "request should transfer token");
        require(!_currentRequest.status, "already executed");
        require(_currentRequest.approves >= approvals, "not enough signs");
        require(_currentRequest.value <= IERC20(_currentRequest.tokenAddress).balanceOf(address(this)), "not enough tokens on wallet");

        _currentRequest.status = true;
        IERC20(_currentRequest.tokenAddress).transfer(_currentRequest.to, _currentRequest.value);

        return true;
    }


    //---------------------------ADMIN----------------------------
    function addAdmin(address _addr) external {

    }

    function removeAdmin(address _addr) external {

    }



    receive() external payable {
        emit Deposited(msg.value);
    }
}
