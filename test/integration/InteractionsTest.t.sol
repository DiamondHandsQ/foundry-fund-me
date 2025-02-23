// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract Interactions is Test {
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

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe(); // create a new instance of the FundFundMe contract
        fundFundMe.fundFundMe(address(fundMe)); // call the fundFundMe function

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe(); // create a new instance of the WithdrawFundMe contract
        withdrawFundMe.withdrawFundMe(address(fundMe)); // call the withdrawFundMe function

        assert(address(fundMe).balance == 0); // check if the balance of the FundMe contract is 0
    }
}