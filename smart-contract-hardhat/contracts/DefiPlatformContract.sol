// SPDX-License-Identifier: DEFI

pragma solidity >=0.6.0 <0.9.0;
import "./LendingRequestContracts.sol";
import "./GovernanceContract.sol";
import "./ERC20Interface.sol";
import "./RequestFactoryAbstract.sol";

contract DefiPlatform is RequestFactory {
    // event
    event LoanAsked();
    event LoanGiven();
    event LoanReturned();
    event LoanDefaulted();
    event LoanCancelled();

    // state mapping

    address[] private lendingRequests;
    mapping(address => uint256) private requestIndex;
    mapping(address => uint256) private userRequestCount;
    mapping(address => bool) private validRequest;

    address private governance;

    constructor(address _governance) {
        governance = _governance;
    }

    function ask(
        uint256 _amount,
        uint256 _paybackAmount,
        string memory _purpose,
        address payable _token,
        uint256 _collateralCollectionTimeStamp
    ) external payable returns (bool success) {
        bool isPlatformEnabled = Governance(governance).isPlatformEnabled();
        require(isPlatformEnabled, "New Loan Requests are currently disabled");
        require(
            _amount > 0,
            "Some Ether collateral must be included in your ask request"
        );

        address payable requestContract = createLendingRequest(
            _amount,
            _paybackAmount,
            _purpose,
            payable(msg.sender),
            _token,
            msg.value,
            _collateralCollectionTimeStamp
        );
        userRequestCount[msg.sender]++;
        requestIndex[requestContract] = lendingRequests.length;
        lendingRequests.push(requestContract);

        // mark created lendingRequest as a valid request
        validRequest[requestContract] = true;

        emit LoanAsked();
        return true;
    }

    function lend(
        address payable _requestContractAddress
    ) external returns (bool result) {
        // Check is there is a valid lending contract at that address
        require(
            validRequest[_requestContractAddress],
            "Invalid Request Contract"
        );

        bool success = LendingRequest(_requestContractAddress).lend(
            payable(msg.sender)
        );
        require(success, "Lending failed");

        // Emit Event

        emit LoanGiven();

        return true;
    }

    function payback(
        address payable _requestContractAddress
    ) external returns (bool result) {
        require(
            validRequest[_requestContractAddress],
            "Invalid Request Contract"
        );
        bool success = LendingRequest(_requestContractAddress).payback(
            payable(msg.sender)
        );
        require(success, "Transaction Failed");

        emit LoanReturned();
        return true;
    }

    function collectCollateral(
        address payable _requestContractAddress
    ) external returns (bool result) {
        require(
            validRequest[_requestContractAddress],
            "Invalid Request Contract"
        );
        bool success = LendingRequest(_requestContractAddress)
            .collectCollateral(payable(msg.sender));
        require(success, "Transaction Failed");

        emit LoanDefaulted();
        return true;
    }

    function cancelRequest(
        address payable _requestContractAddress
    ) external returns (bool result) {
        require(
            validRequest[_requestContractAddress],
            "Invalid Request Contract"
        );
        bool success = LendingRequest(_requestContractAddress).cancelRequest(
            payable(msg.sender)
        );
        require(success, "Transaction Failed");

        emit LoanCancelled();
        return true;
    }

    function removeRequest(
        address _requestContractAddress,
        address _asker
    ) private {
        // update the number of requests for asker

        userRequestCount[_asker]--;
        uint256 idx = requestIndex[_requestContractAddress];
        if (lendingRequests[idx] == _requestContractAddress) {
            requestIndex[lendingRequests[lendingRequests.length - 1]] = idx;
            lendingRequests[idx] = lendingRequests[lendingRequests.length - 1];

            lendingRequests.pop();
        }

        validRequest[_requestContractAddress] = false;
    }

    function getRequestParameters(
        address payable _requestContractAddress
    )
        external
        view
        returns (
            address asker,
            address lender,
            uint256 amountAsked,
            uint256 paybackAmount,
            string memory purpose
        )
    {
        (asker, lender, amountAsked, paybackAmount, purpose) = LendingRequest(
            _requestContractAddress
        ).getRequestParameters();
    }

    function getRequestState(
        address payable _requestContractAddress
    )
        external
        view
        returns (
            bool moneyLent,
            bool debtSettled,
            uint256 collateral,
            bool collateralCollected,
            uint256 collateralCollectionTimeStamp,
            uint256 currentTimeStamp
        )
    {
        return LendingRequest(_requestContractAddress).getRequestState();
    }

    function getCollateralBalance(
        address _requestContractAddress
    ) external view returns (uint256) {
        return address(_requestContractAddress).balance;
    }

    function getRequests() external view returns (address[] memory) {
        return lendingRequests;
    }
}
