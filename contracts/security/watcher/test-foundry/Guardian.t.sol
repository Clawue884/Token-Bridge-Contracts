// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/security/BridgeGuardian.sol";

contract GuardianTest is Test {
    BridgeGuardian guardian;
    address admin = address(1);
    address token = address(2);

    function setUp() public {
        vm.prank(admin);
        guardian = new BridgeGuardian(admin);
        vm.prank(admin);
        guardian.setLimit(token, 1000 ether);
    }

    function testRateLimit() public {
        vm.prank(address(3));
        guardian.checkAndConsume(token, 400 ether);
        vm.prank(address(3));
        guardian.checkAndConsume(token, 500 ether);
        vm.expectRevert("Guardian: RATE_LIMIT");
        vm.prank(address(3));
        guardian.checkAndConsume(token, 200 ether);
    }

    function testPause() public {
        vm.prank(admin);
        guardian.emergencyPause();
        vm.expectRevert("Pausable: paused");
        vm.prank(address(3));
        guardian.checkAndConsume(token, 10 ether);
    }
}
