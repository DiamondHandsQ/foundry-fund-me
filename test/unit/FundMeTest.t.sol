// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundmeTest is Test {
    FundMe private fundMe;
    address private USER = makeAddr("USER"); // This is a mock address
    uint256 constant private USER_BALANCE = 100 ether;
    uint256 constant private SEND_AMOUNT = 0.1 ether;
    uint256 constant private GAS_PRICE = 20 gwei; // gas price can be any value

    function setUp() external {
        // use the DeployFundMe script to deploy the FundMe contract
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, USER_BALANCE); // This is a function that sends USER_BALANCE to USER
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18); //assertEq is a function that checks if the two values are equal
    }

    function testOwnerIsMessageSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender); // This will print the address of the sender
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVerionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // This is telling test that we expect the next call to revert --> returns Success if the next call reverts

        fundMe.fund{value: 1}();
    }

    // This is a modifier that funds the contract before running the test
    modifier funded() {
        vm.prank(USER); // The next tx will be sent from USER
        fundMe.fund{value: SEND_AMOUNT}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getsAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_AMOUNT);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder({index : 0});
        assertEq(funder, USER);
    }
    
    function testOnlyOwnerCanWithdraw() public funded {
        // Try to withdraw as a non-owner
        vm.prank(USER); // User is not owner so this will revert
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft(); // gasleft() returns the amount of gas left in the current call from the gas allowance
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = gasStart - gasEnd;
        console.log("Gas used: ", gasUsed);
        
        // Assert 
        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 finalFundMeBalance = address(fundMe).balance;

        assertEq(startingFundMeBalance + startingOwnerBalance, finalOwnerBalance);
        assertEq(finalFundMeBalance, 0);
    } 

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) { // initialization ; condition ; increment
            // hoax() similar to prank() and deal() combined
            hoax(address(i), SEND_AMOUNT);
            fundMe.fund{value: SEND_AMOUNT}();
        }

        // Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 finalFundMeBalance = address(fundMe).balance;

        assertEq(startingFundMeBalance + startingOwnerBalance, finalOwnerBalance);
        assertEq(finalFundMeBalance, 0);
    }  
}
