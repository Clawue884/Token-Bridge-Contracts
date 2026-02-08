// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BridgeGuardian is AccessControl, Pausable {
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Limit {
        uint256 maxPerHour;
        uint256 used;
        uint256 lastReset;
    }

    mapping(address => Limit) public tokenLimits;

    event LimitSet(address indexed token, uint256 maxPerHour);
    event TransferChecked(address indexed token, uint256 amount, bool allowed);
    event BridgeStatus(address indexed token, uint256 used, uint256 max, string status);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GUARDIAN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
    }

    function setLimit(address token, uint256 maxPerHour) external onlyRole(GUARDIAN_ROLE) {
        tokenLimits[token] = Limit(maxPerHour, 0, block.timestamp);
        emit LimitSet(token, maxPerHour);
    }

    function checkAndConsume(address token, uint256 amount) external whenNotPaused returns (bool) {
        Limit storage lim = tokenLimits[token];
        if (block.timestamp > lim.lastReset + 1 hours) {
            lim.used = 0;
            lim.lastReset = block.timestamp;
        }
        require(lim.maxPerHour > 0, "Guardian: LIMIT_NOT_SET");
        require(lim.used + amount <= lim.maxPerHour, "Guardian: RATE_LIMIT");
        lim.used += amount;

        string memory status = lim.used > (lim.maxPerHour * 8 / 10) ? "WARNING" : "HEALTHY";
        emit TransferChecked(token, amount, true);
        emit BridgeStatus(token, lim.used, lim.maxPerHour, status);
        return true;
    }

    function emergencyPause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    function emergencyUnpause() external onlyRole(GUARDIAN_ROLE) {
        _unpause();
    }

    function healthStatus(address token) external view returns (string memory) {
        Limit memory lim = tokenLimits[token];
        if (paused()) return "EMERGENCY";
        if (lim.used > lim.maxPerHour * 8 / 10) return "WARNING";
        return "HEALTHY";
    }
}
