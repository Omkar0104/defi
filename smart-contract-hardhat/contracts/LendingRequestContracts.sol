// SPDX-License-Identifier: DEFI

pragma solidity >=0.6.0 <0.9.0;

import "./ERC20Interface.sol";

contract LendingRequest {
    address payable private owner;
    address payable private token;
    address payable public asker;
    address payable public lender;
    string public purpose;
    uint256 public collateral;
    uint256 public amountAsked;
    uint256 public paybackAmount;
    uint256 public collateralCollectionTimestamp;

    bool public moneyLent;
    bool public debtSettled;
    bool public collateralCollected;

    constructor(
        address payable _owner,
        address payable _token,
        address payable _asker,
        string memory _purpose,
        uint256 _collateral,
        uint256 _amountAsked,
        uint256 _paybackAmount,
        uint256 _collateralCollectionTimestamp
    ) payable {
        token = _token;
        owner = _owner;
        asker = _asker;
        collateral = _collateral;
        purpose = _purpose;
        amountAsked = _amountAsked;
        paybackAmount = _paybackAmount;
        collateralCollectionTimestamp = _collateralCollectionTimestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorised Access");
        _;
    }

    function lend(address payable _lender)
        external
        onlyOwner
        returns (bool success)
    {
        require(!moneyLent, "Money Lent already");
        require((asker != _lender), "Invalid Lender");
        require(
            !collateralCollected,
            "Collateral Already Collected or Request Cancelled"
        );

        uint256 balance = ERC20Interface(token).allowance(
            _lender,
            address(this)
        );
        require(balance >= amountAsked, "Balance is less that asked amount");

        require(
            ERC20Interface(token).transferFrom(_lender, asker, amountAsked),
            "Transfer Failed"
        );

        moneyLent = true;
        lender = _lender;

        return true;
    }

    function payback(address payable _asker)
        external
        onlyOwner
        returns (bool success)
    {
        require(_asker == asker, "Not Access");
        require(moneyLent && !debtSettled, "Not Allowed");
        require(!collateralCollected, "Already Settled");

        uint256 balance = ERC20Interface(token).allowance(
            _asker,
            address(this)
        );
        require(balance >= paybackAmount, "Insufficient Balance");

        require(
            ERC20Interface(token).transferFrom(_asker, lender, paybackAmount),
            "Transfer Failed"
        );

        // giving back the collateral
        _asker.transfer(address(this).balance);
        collateral -= address(this).balance;

        debtSettled = true;
        return true;
    }

    function collectCollateral(address payable _lender)
        external
        onlyOwner
        returns (bool success)
    {
        require(lender == _lender, "Not Valid Lender");
        require(!debtSettled && moneyLent, "Money is not Lent");

        // check collateral
        require(!collateralCollected, "Already Collected");
        require(
            block.timestamp >= collateralCollectionTimestamp,
            "Too Soon to Collect Collateral"
        );

        // update State
        collateralCollected = true;
        _lender.transfer(address(this).balance);

        return true;
    }

    function cancelRequest(address payable _asker)
        external
        onlyOwner
        returns (bool success)
    {
        require(_asker == asker, "Invalid Asker");
        require(
            !moneyLent && !debtSettled && !collateralCollected,
            "Can not cancel the request"
        );
        collateralCollected = true;

        _asker.transfer(address(this).balance);

        return true;
    }

    function getRequestState()
        external
        view
        onlyOwner
        returns (
            bool,
            bool,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        return (
            moneyLent,
            debtSettled,
            collateral,
            collateralCollected,
            collateralCollectionTimestamp,
            block.timestamp
        );
    }

    function getRequestParameters()
        external
        view
        onlyOwner
        returns (
            address payable,
            address payable,
            uint256,
            uint256,
            string memory
        )
    {
        return (asker, lender, amountAsked, paybackAmount, purpose);
    }
}
