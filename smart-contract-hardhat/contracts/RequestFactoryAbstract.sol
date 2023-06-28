// SPDX-License-Identifier: DEFI

pragma solidity ^0.8;

import "./LendingRequestContracts.sol";

abstract contract RequestFactory{

    function createLendingRequest(
        uint256 _amount,
        uint256 _paybackAmount,
        string memory _purpose,
        address payable _origin,
        address payable _token,
        uint256 _collateral,
        uint256 _collateralCollectionTimeStamp
    ) internal returns (address payable lendingRequest) {
        // create new instance of lendingRequest contract
        return
            lendingRequest = payable(
                (
                        address(
                            new LendingRequest{value: msg.value}(
                                payable(address(this)),
                                _token,
                                _origin,
                                _purpose,
                                _collateral,
                                _amount,
                                _paybackAmount,
                                _collateralCollectionTimeStamp
                            )
                        )
                    )

            );
    }
}
