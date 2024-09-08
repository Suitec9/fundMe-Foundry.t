// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {MockV3Aggregator} from "../mock/MockV3Aggregator.t.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import { ZkSyncChainChecker } from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import { FoundryZkSyncChecker } from "lib/foundry-devops/src/FoundryZkSyncChecker.sol";



contract FundMeTest is Test {

   FundMe fundMe;
   address alice = makeAddr("alice");
   MockV3Aggregator mockV3Aggregator;
   address private owner;
   DeployFundMe deployFundMe;
   uint256 public constant SEND_VALUE = 0.1 ether;
   uint256 public constant STARTING_BALANCE = 10 ether;
   int256 public constant  INITIAL_VALUE = 2000e8;
   uint8 public constant DECIMAL = 8;
   uint256 constant GAS_PRICE = 1;
   

   function setUp() external { 
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        mockV3Aggregator = new MockV3Aggregator(DECIMAL, INITIAL_VALUE); // $2000 with 8 decimals
        
      //  address priceFeedAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

        fundMe = new FundMe(address(mockV3Aggregator));
       // owner = fundMe.i_owner();
        vm.deal(alice, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), address(this));
        console.log("Check the address for the owner", fundMe.getOwner());
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }    
    
    function testFundFailsWIthoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.fund(); // <- We send 0 value

    }    
    
    function testFundUpdatesFundDataStrucutre() public {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_VALUE);

    }    
    
    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(alice);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, alice);

    }        
    
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();

    } 

    modifier funded() {
        vm.prank(alice);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;

    }

    function testWithdrawFromASingleFunder() public funded {
                
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        console.log("How much is value", address(fundMe).balance);
        console.log("how much is the value", fundMe.getOwner().balance);

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        // // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

         uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Withdraw consummed: %d gas", gasUsed);
                
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        console.log("how much is the value", endingOwnerBalance);
        console.log("how much is the value", endingFundMeBalance);

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);

    }
    
    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Vaule at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));

    }

}