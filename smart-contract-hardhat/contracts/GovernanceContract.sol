// SPDX-License-Identifier: DEFI

pragma solidity >=0.6.0 <0.9.0;
import "hardhat/console.sol"; // Hardhat console logs
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Governance is Initializable {
    uint16 flaggingThreshold;
    uint16 currentFlags;
    bool public isPlatformEnabled;  
// console.log(initializer);

    function initialize(uint16 _flaggingThreshold) public initializer {
        flaggingThreshold = _flaggingThreshold;
        currentFlags = 0;
        isPlatformEnabled = true;
    }

    // TODO: Add modifier to control who can access this function
    function flag() external returns (bool _success) {
        // Increment
        currentFlags += 1;

        // Check
        if (currentFlags > flaggingThreshold) {
            isPlatformEnabled = false;
            currentFlags = 0;
        }

        return true;
    }

    function enableFlag() external returns (bool _success) {
        // Increment
        currentFlags += 1;

        // Check
        if (currentFlags > flaggingThreshold) {
            isPlatformEnabled = true;
            currentFlags = 0;
        }

        return true;
    }

    // TODO: Add modifier to control who can access this function
    function changePlatformState(
        bool newState
    ) external returns (bool _success) {
        isPlatformEnabled = newState;
        return true;
    }
}
